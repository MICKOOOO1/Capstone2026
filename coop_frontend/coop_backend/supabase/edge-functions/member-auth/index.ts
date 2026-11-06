import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const url = Deno.env.get("SUPABASE_URL");
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const publicKey = Deno.env.get("SUPABASE_ANON_KEY");
const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info, x-retry-count",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};
const respond = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), { status, headers });
const invalidCredentials = () => respond({ error: "No account found or the password is incorrect." }, 400);

serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  if (request.method !== "POST") return respond({ error: "Method not allowed." }, 405);
  if (!url || !serviceKey || !publicKey) return respond({ error: "Member authentication is not configured." }, 503);

  try {
    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) return respond({ error: "Invalid request." }, 400);
    const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });

    if (body.mode === "login") {
      const memberId = typeof body.memberId === "string" ? body.memberId.trim().toUpperCase() : "";
      const password = typeof body.password === "string" ? body.password : "";
      if (!/^(?:CSUCC-)?\d{4}-\d{4,}$/.test(memberId) || !password || password.length > 128) return invalidCredentials();

      const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(memberId));
      const identifierHash = Array.from(new Uint8Array(digest), (value) => value.toString(16).padStart(2, "0")).join("");
      const { data: allowed, error: limitError } = await admin.rpc("reserve_member_login_attempt", { p_identifier_hash: identifierHash });
      if (limitError) return respond({ error: "Member login is temporarily unavailable." }, 503);
      if (!allowed) return respond({ error: "Too many login attempts. Please try again in 15 minutes." }, 429);

      const { data: profile, error: profileError } = await admin.from("members")
        .select("user_id, email, status, must_change_password")
        .eq("member_id", memberId).maybeSingle();
      if (profileError) return respond({ error: "Unable to check the member account. Please try again." }, 503);
      if (!profile?.user_id || !profile.email || profile.status !== "active") return invalidCredentials();

      const verifier = createClient(url, publicKey, { auth: { persistSession: false, autoRefreshToken: false } });
      const { data, error } = await verifier.auth.signInWithPassword({ email: profile.email, password });
      if (error || !data.user || !data.session) return invalidCredentials();
      const role = data.user.app_metadata?.role;
      const status = data.user.app_metadata?.account_status;
      if (data.user.id !== profile.user_id || role !== "member" || (status !== undefined && status !== "active")) {
        await verifier.auth.signOut();
        return invalidCredentials();
      }
      const { error: clearError } = await admin.from("member_login_limits").delete().eq("identifier_hash", identifierHash);
      if (clearError) {
        await verifier.auth.signOut();
        return respond({ error: "Unable to complete member login. Please try again." }, 503);
      }
      return respond({ refreshToken: data.session.refresh_token, mustChangePassword: profile.must_change_password === true });
    }

    if (body.mode === "change-password") {
      const bearer = request.headers.get("Authorization")?.match(/^Bearer\s+(.+)$/i)?.[1];
      if (!bearer) return respond({ error: "Sign in before changing your password." }, 401);
      const { data: authData, error: authError } = await admin.auth.getUser(bearer);
      const user = authData.user;
      if (authError || !user || !user.email) return respond({ error: "Your session expired. Please sign in again." }, 401);
      if (user.app_metadata?.role !== "member" ||
        (user.app_metadata?.account_status !== undefined && user.app_metadata.account_status !== "active") ||
        (user.banned_until && Date.parse(user.banned_until) > Date.now())) {
        return respond({ error: "An active member account is required." }, 403);
      }
      const { data: profile, error: profileError } = await admin.from("members").select("id, status").eq("user_id", user.id).single();
      if (profileError || profile?.status !== "active") return respond({ error: "Unable to verify an active member profile." }, 403);
      const password = typeof body.password === "string" ? body.password : "";
      if (!/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,128}$/.test(password)) {
        return respond({ error: "Use 8–128 characters with an uppercase letter, a lowercase letter, and a number." }, 400);
      }
      const { error: passwordError } = await admin.auth.admin.updateUserById(user.id, { password });
      if (passwordError) return respond({ error: "Unable to update your password. Please try again." }, 400);
      const { error: updateError } = await admin.from("members").update({ must_change_password: false }).eq("id", profile.id);
      if (updateError) return respond({ error: "Your password was changed, but setup could not be completed. Please retry or contact the cooperative admin." }, 503);
      // Renew the session after the password change so the client does not
      // continue using refresh tokens issued with its temporary credentials.
      const verifier = createClient(url, publicKey, { auth: { persistSession: false, autoRefreshToken: false } });
      const { data: renewed, error: renewalError } = await verifier.auth.signInWithPassword({ email: user.email, password });
      if (renewalError || !renewed.session || renewed.user?.id !== user.id) {
        return respond({ error: "Your password was updated. Please sign in again with your new password." }, 401);
      }
      return respond({ success: true, refreshToken: renewed.session.refresh_token });
    }
    return respond({ error: "Unsupported authentication request." }, 400);
  } catch {
    return respond({ error: "Unable to process the authentication request. Please try again." }, 500);
  }
});
