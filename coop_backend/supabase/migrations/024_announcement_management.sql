-- Requires existing members, notifications and admin_activity_logs (migrations 001-023).
-- Prepared for review/deployment; no existing role or notification policy is changed.
BEGIN;

CREATE TABLE public.announcement_categories (
  id text PRIMARY KEY,
  name text NOT NULL UNIQUE,
  sort_order integer NOT NULL DEFAULT 0
);
-- Category definitions, not sample announcements.
INSERT INTO public.announcement_categories (id, name, sort_order) VALUES
  ('general', 'General', 1), ('events', 'Events', 2), ('advisories', 'Advisories', 3),
  ('loan_updates', 'Loan Updates', 4), ('maintenance', 'Maintenance', 5);

CREATE TABLE public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 160),
  content text NOT NULL DEFAULT '' CHECK (char_length(content) <= 20000),
  category_id text NOT NULL REFERENCES public.announcement_categories(id),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'archived')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  author_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  scheduled_at timestamptz,
  notify_members boolean NOT NULL DEFAULT false,
  CHECK (status NOT IN ('published', 'scheduled') OR char_length(btrim(content)) > 0),
  CHECK ((status = 'scheduled') = (scheduled_at IS NOT NULL)),
  CHECK (status <> 'published' OR published_at IS NOT NULL),
  CHECK (status <> 'draft' OR NOT notify_members)
);
CREATE INDEX announcements_admin_list ON public.announcements(created_at DESC, id DESC);
CREATE INDEX announcements_member_list ON public.announcements(published_at DESC, id DESC) WHERE status = 'published';
CREATE INDEX announcements_due ON public.announcements(scheduled_at) WHERE status = 'scheduled';

CREATE TABLE public.announcement_notification_receipts (
  announcement_id uuid NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_id uuid NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (announcement_id, user_id)
);
-- System scheduler events retain an audit trail even if the original author is deleted.
CREATE TABLE public.announcement_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id uuid,
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE FUNCTION public.announcement_admin_access(p_write boolean DEFAULT false)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, auth AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users u
    WHERE u.id = auth.uid()
      AND (u.banned_until IS NULL OR u.banned_until <= now())
      AND COALESCE(u.raw_app_meta_data ->> 'account_status', 'active') = 'active'
      AND (u.raw_app_meta_data ->> 'role' = 'super_admin'
        OR (NOT p_write AND u.raw_app_meta_data ->> 'role' IN ('admin', 'coop_admin')))
      AND NOT EXISTS (SELECT 1 FROM public.members m WHERE m.user_id = u.id AND m.status <> 'active')
  );
$$;
CREATE FUNCTION public.announcement_member_access()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, auth AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users u JOIN public.members m ON m.user_id = u.id
    WHERE u.id = auth.uid() AND u.raw_app_meta_data ->> 'role' = 'member'
      AND COALESCE(u.raw_app_meta_data ->> 'account_status', 'active') = 'active'
      AND (u.banned_until IS NULL OR u.banned_until <= now())
      AND m.status = 'active' AND lower(m.role) = 'member' AND NOT m.must_change_password
  );
$$;

CREATE FUNCTION public.announcement_scheduler_ready()
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
DECLARE v_ready boolean := false;
BEGIN
  IF to_regclass('cron.job') IS NOT NULL THEN
    EXECUTE 'SELECT EXISTS (SELECT 1 FROM cron.job WHERE jobname = ''csucc_mpc_publish_announcements'' AND active AND position(''public.publish_due_announcements()'' in command) > 0)' INTO v_ready;
  END IF;
  RETURN v_ready;
END;
$$;
CREATE FUNCTION public.announcement_service_status()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
BEGIN
  IF NOT public.announcement_admin_access(false) THEN RAISE EXCEPTION 'Administrator authorization required' USING ERRCODE = '42501'; END IF;
  RETURN jsonb_build_object('scheduling_enabled',public.announcement_scheduler_ready(),'notifications_enabled',true,'images_enabled',false);
END;
$$;

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_notification_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.announcements, public.announcement_categories, public.announcement_notification_receipts, public.announcement_events FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.announcements, public.announcement_categories TO authenticated;
GRANT ALL ON public.announcements, public.announcement_categories, public.announcement_notification_receipts, public.announcement_events TO service_role;
CREATE POLICY "Announcement admin reads" ON public.announcements FOR SELECT TO authenticated
  USING (public.announcement_admin_access(false));
CREATE POLICY "Published member announcements only" ON public.announcements FOR SELECT TO authenticated
  USING (public.announcement_member_access() AND status = 'published' AND published_at <= now());
CREATE POLICY "Announcement category reads" ON public.announcement_categories FOR SELECT TO authenticated
  USING (public.announcement_admin_access(false) OR public.announcement_member_access());

CREATE VIEW public.member_announcements WITH (security_invoker = true) AS
  SELECT a.id, a.title, a.content, c.name AS category, a.author_name, a.published_at
  FROM public.announcements a JOIN public.announcement_categories c ON c.id = a.category_id
  WHERE a.status = 'published' AND a.published_at <= now();
REVOKE ALL ON public.member_announcements FROM PUBLIC, anon;
GRANT SELECT ON public.member_announcements TO authenticated;

-- Called only inside a publication transaction. Receipts and inbox inserts commit together.
CREATE FUNCTION public.deliver_announcement_notifications(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth AS $$
DECLARE v_announcement public.announcements;
BEGIN
  SELECT * INTO STRICT v_announcement FROM public.announcements WHERE id = p_id FOR UPDATE;
  IF v_announcement.status <> 'published' OR NOT v_announcement.notify_members THEN RETURN; END IF;
  WITH new_receipts AS (
    INSERT INTO public.announcement_notification_receipts (announcement_id, user_id, notification_id)
    SELECT DISTINCT p_id, u.id, gen_random_uuid()
    FROM public.members m JOIN auth.users u ON u.id = m.user_id
    WHERE m.status = 'active' AND lower(m.role) = 'member' AND NOT m.must_change_password
      AND u.raw_app_meta_data ->> 'role' = 'member'
      AND COALESCE(u.raw_app_meta_data ->> 'account_status', 'active') = 'active'
      AND (u.banned_until IS NULL OR u.banned_until <= now())
    ON CONFLICT (announcement_id, user_id) DO NOTHING
    RETURNING user_id, notification_id
  )
  INSERT INTO public.notifications (id, user_id, title, message, type, read)
  SELECT notification_id, user_id, left('Announcement: ' || v_announcement.title, 200),
    left(v_announcement.content, 180) || E'\nAnnouncement reference: ' || p_id::text, 'info', false
  FROM new_receipts;
END;
$$;

CREATE FUNCTION public.manage_announcement(p_action text, p_id uuid, p_expected_updated_at timestamptz, p_payload jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth AS $$
DECLARE
  v_old public.announcements;
  v_new public.announcements;
  v_exists boolean;
  v_status text;
  v_schedule timestamptz;
  v_notify boolean;
  v_author text;
BEGIN
  IF NOT public.announcement_admin_access(true) THEN RAISE EXCEPTION 'Active Super Admin authorization required' USING ERRCODE = '42501'; END IF;
  IF p_id IS NULL OR p_action IS NULL OR p_action NOT IN ('save', 'archive', 'restore', 'cancel_schedule', 'delete')
    OR p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object' THEN RAISE EXCEPTION 'Invalid announcement request'; END IF;
  SELECT * INTO v_old FROM public.announcements WHERE id = p_id FOR UPDATE;
  v_exists := FOUND;
  IF (v_exists AND (p_expected_updated_at IS NULL OR v_old.updated_at IS DISTINCT FROM p_expected_updated_at))
    OR (NOT v_exists AND p_expected_updated_at IS NOT NULL) THEN
    RAISE EXCEPTION 'Announcement changed; refresh before retrying' USING ERRCODE = '40001';
  END IF;
  IF NOT v_exists AND p_action <> 'save' THEN RAISE EXCEPTION 'Announcement not found'; END IF;
  IF p_action = 'save' THEN
    IF (p_payload - ARRAY['title','content','category_id','status','scheduled_at','notify_members']) <> '{}'::jsonb
      OR jsonb_typeof(p_payload -> 'title') IS DISTINCT FROM 'string'
      OR jsonb_typeof(p_payload -> 'content') IS DISTINCT FROM 'string'
      OR jsonb_typeof(p_payload -> 'category_id') IS DISTINCT FROM 'string'
      OR jsonb_typeof(p_payload -> 'notify_members') IS DISTINCT FROM 'boolean'
      OR char_length(btrim(p_payload ->> 'title')) NOT BETWEEN 1 AND 160
      OR char_length(p_payload ->> 'content') > 20000 THEN RAISE EXCEPTION 'Invalid announcement fields'; END IF;
    v_status := p_payload ->> 'status';
    IF v_status IS NULL OR v_status NOT IN ('draft','scheduled','published') THEN RAISE EXCEPTION 'Invalid publication status'; END IF;
    IF v_exists AND (v_old.status = 'archived' OR (v_old.status = 'published' AND v_status <> 'published')) THEN RAISE EXCEPTION 'Use the appropriate archive or restore action'; END IF;
    IF v_status <> 'draft' AND char_length(btrim(p_payload ->> 'content')) = 0 THEN RAISE EXCEPTION 'Announcement content is required'; END IF;
    v_schedule := CASE WHEN v_status = 'scheduled' THEN (p_payload ->> 'scheduled_at')::timestamptz ELSE NULL END;
    IF v_status = 'scheduled' AND NOT public.announcement_scheduler_ready() THEN RAISE EXCEPTION 'Scheduled publication is not configured' USING ERRCODE = '55000'; END IF;
    IF v_status = 'scheduled' AND (v_schedule IS NULL OR v_schedule <= now()) THEN RAISE EXCEPTION 'A future schedule is required'; END IF;
    v_notify := CASE WHEN v_status = 'draft' THEN false ELSE (p_payload ->> 'notify_members')::boolean END;
    IF v_exists AND v_old.status = 'published' AND v_old.notify_members IS DISTINCT FROM v_notify THEN RAISE EXCEPTION 'Notification preference is fixed after publication'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.announcement_categories WHERE id = p_payload ->> 'category_id') THEN RAISE EXCEPTION 'Unknown announcement category'; END IF;
    IF v_exists THEN
      UPDATE public.announcements SET title = btrim(p_payload ->> 'title'), content = btrim(p_payload ->> 'content'),
        category_id = p_payload ->> 'category_id', status = v_status, scheduled_at = v_schedule, notify_members = v_notify,
        published_at = CASE WHEN v_status = 'published' AND v_old.status <> 'published' THEN now() ELSE published_at END,
        updated_at = clock_timestamp() WHERE id = p_id RETURNING * INTO v_new;
    ELSE
      SELECT NULLIF(btrim(concat_ws(' ', first_name, last_name)), '') INTO v_author FROM public.members WHERE user_id = auth.uid() LIMIT 1;
      v_author := COALESCE(v_author, NULLIF(auth.jwt() -> 'user_metadata' ->> 'full_name', ''));
      INSERT INTO public.announcements (id,title,content,category_id,status,created_by,author_name,published_at,scheduled_at,notify_members)
      VALUES (p_id,btrim(p_payload ->> 'title'),btrim(p_payload ->> 'content'),p_payload ->> 'category_id',v_status,auth.uid(),v_author,
        CASE WHEN v_status = 'published' THEN now() ELSE NULL END,v_schedule,v_notify) RETURNING * INTO v_new;
    END IF;
    IF v_new.status = 'published' AND (NOT v_exists OR v_old.status <> 'published') THEN PERFORM public.deliver_announcement_notifications(p_id); END IF;
  ELSIF p_action = 'delete' THEN
    IF v_old.status <> 'draft' OR v_old.published_at IS NOT NULL THEN RAISE EXCEPTION 'Only never-published drafts can be deleted'; END IF;
    DELETE FROM public.announcements WHERE id = p_id;
  ELSE
    IF (p_action = 'archive' AND v_old.status <> 'published') OR (p_action = 'restore' AND v_old.status <> 'archived')
      OR (p_action = 'cancel_schedule' AND v_old.status <> 'scheduled') THEN RAISE EXCEPTION 'Invalid announcement transition'; END IF;
    UPDATE public.announcements SET status = CASE WHEN p_action = 'archive' THEN 'archived' ELSE 'draft' END,
      scheduled_at = NULL, notify_members = CASE WHEN p_action = 'archive' THEN notify_members ELSE false END,
      updated_at = clock_timestamp() WHERE id = p_id RETURNING * INTO v_new;
  END IF;
  INSERT INTO public.admin_activity_logs (actor_id,action_name,target_id,result,details)
    VALUES (auth.uid(),p_action || '-announcement',p_id::text,'success',jsonb_build_object('previous_status',v_old.status,'status',v_new.status));
  INSERT INTO public.announcement_events (announcement_id,actor_id,action,details)
    VALUES (p_id,auth.uid(),p_action,jsonb_build_object('previous_status',v_old.status,'status',v_new.status));
  RETURN jsonb_build_object('id',p_id,'success',true);
END;
$$;

-- Configure the scheduler separately after deployment; this function never runs from the UI.
CREATE FUNCTION public.publish_due_announcements()
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth AS $$
DECLARE v_row public.announcements; v_count integer := 0; v_author_active boolean;
BEGIN
  FOR v_row IN SELECT * FROM public.announcements WHERE status = 'scheduled' AND scheduled_at <= now()
    ORDER BY scheduled_at, id LIMIT 50 FOR UPDATE SKIP LOCKED
  LOOP
    SELECT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = v_row.created_by AND u.raw_app_meta_data ->> 'role' = 'super_admin'
      AND COALESCE(u.raw_app_meta_data ->> 'account_status','active') = 'active' AND (u.banned_until IS NULL OR u.banned_until <= now())
      AND NOT EXISTS (SELECT 1 FROM public.members m WHERE m.user_id = u.id AND m.status <> 'active')) INTO v_author_active;
    IF NOT v_author_active THEN
      UPDATE public.announcements SET status = 'draft', scheduled_at = NULL, notify_members = false, updated_at = clock_timestamp() WHERE id = v_row.id;
      INSERT INTO public.announcement_events (announcement_id,action) VALUES (v_row.id,'schedule_cancelled_author_inactive');
      CONTINUE;
    END IF;
    UPDATE public.announcements SET status = 'published', scheduled_at = NULL, published_at = now(), updated_at = clock_timestamp() WHERE id = v_row.id;
    PERFORM public.deliver_announcement_notifications(v_row.id);
    INSERT INTO public.announcement_events (announcement_id,action) VALUES (v_row.id,'scheduled_publication');
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.announcement_admin_access(boolean), public.announcement_member_access(), public.manage_announcement(text,uuid,timestamptz,jsonb), public.deliver_announcement_notifications(uuid), public.publish_due_announcements() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.announcement_scheduler_ready(), public.announcement_service_status() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.announcement_admin_access(boolean), public.announcement_member_access(), public.manage_announcement(text,uuid,timestamptz,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.announcement_service_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public.publish_due_announcements() TO service_role;
-- Supabase Cron is optional. Never claim scheduling is enabled when no job exists.
DO $$ BEGIN
  IF to_regclass('cron.job') IS NOT NULL THEN
    PERFORM cron.schedule('csucc_mpc_publish_announcements','* * * * *','SELECT public.publish_due_announcements();');
  ELSE
    RAISE NOTICE 'Enable Supabase Cron, then configure the csucc_mpc_publish_announcements job. Scheduling stays disabled until configured.';
  END IF;
END $$;
NOTIFY pgrst, 'reload schema';
COMMIT;
