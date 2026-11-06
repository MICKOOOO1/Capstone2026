DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.members
    WHERE membership_type IS NOT NULL
      AND lower(membership_type) NOT IN ('regular', 'associate')
  ) THEN
    RAISE EXCEPTION
      'Unsupported members.membership_type values exist; review them before applying this migration.';
  END IF;
END;
$$;

ALTER TABLE public.members
  DROP CONSTRAINT IF EXISTS members_membership_type_check;

UPDATE public.members
SET membership_type = CASE lower(membership_type)
  WHEN 'regular' THEN 'Regular'
  WHEN 'associate' THEN 'Associate'
END
WHERE membership_type IS NOT NULL;

ALTER TABLE public.members
  ADD CONSTRAINT members_membership_type_check
  CHECK (membership_type IS NULL OR membership_type IN ('Regular', 'Associate'));
