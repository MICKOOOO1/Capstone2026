import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

type JsonObject = Record<string, unknown>;
type AccountRole = "Member" | "Admin" | "Super Admin" | "Unknown";
type AccountStatus = "Active" | "Inactive" | "Blocked" | "Suspended" | "Unknown";

interface AccountRecord {
  accountKey: string;
  authUserId: string | null;
  profileLinked: boolean;
  idNumber: string;
  fullName: string;
  email: string;
  phone: string;
  address: string;
  role: AccountRole;
  membershipType: "regular" | "associate" | null;
  department: string;
  status: AccountStatus;
  createdAt: string;
  integrityIssue: string | null;
}

function respond(body: JsonObject, status = 200) {
  return new Response(JSON.stringify(body), { status, headers });
}

function asRecord(value: unknown): JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as JsonObject
    : {};
}

function nonEmptyString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function getRole(authRole: unknown, profileRole: unknown): AccountRole {
  if (authRole === "super_admin") return "Super Admin";
  if (authRole === "admin" || authRole === "coop_admin") return "Admin";
  if (authRole === "member") return "Member";
  if (authRole !== null && authRole !== undefined && authRole !== "") return "Unknown";
  if (profileRole === "Member" || profileRole === "member") return "Member";
  return "Unknown";
}

function normalizeRole(value: unknown): AccountRole {
  if (value === "Super Administrator" || value === "Super Admin") return "Super Admin";
  if (value === "Administrator" || value === "Admin") return "Admin";
  if (value === "Member" || value === "member") return "Member";
  return "Unknown";
}

function getStatus(
  profileStatus: unknown,
  accountStatus: unknown,
  bannedUntil: unknown,
): AccountStatus {
  const expiry = typeof bannedUntil === "string" ? Date.parse(bannedUntil) : NaN;
  if (Number.isFinite(expiry) && expiry > Date.now()) return "Blocked";
  if (profileStatus === "active") return "Active";
  if (profileStatus === "inactive") return "Inactive";
  if (profileStatus === "blocked") return "Blocked";
  if (profileStatus === "suspended") return "Suspended";
  if (accountStatus === "active") return "Active";
  if (accountStatus === "inactive") return "Inactive";
  if (accountStatus === "blocked") return "Blocked";
  if (accountStatus === "suspended") return "Suspended";
  return "Unknown";
}

function getProfileName(profile: JsonObject): string {
  return [profile.first_name, profile.last_name]
    .filter((part): part is string => typeof part === "string" && part.trim().length > 0)
    .join(" ");
}

function getMembershipType(value: unknown): "regular" | "associate" | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  return normalized === "regular" || normalized === "associate"
    ? normalized
    : null;
}

function mapProfile(
  profile: JsonObject,
  authUser: JsonObject | null,
): AccountRecord {
  const metadata = asRecord(authUser?.user_metadata);
  const appMetadata = asRecord(authUser?.app_metadata);
  const userId = nonEmptyString(profile.user_id) || null;
  const profileId = nonEmptyString(profile.id) || nonEmptyString(profile.member_id);
  const role = getRole(appMetadata.role, profile.role);
  const profileName = getProfileName(profile);
  const authName = nonEmptyString(metadata.full_name);
  const membershipType =
    role === "Member" ? getMembershipType(profile.membership_type) : null;
  const authRole = appMetadata.role;
  const authRoleKnown =
    authRole === "super_admin" ||
    authRole === "admin" ||
    authRole === "coop_admin" ||
    authRole === "member";
  const identityIssues = [
    !userId ? "Profile has no linked authentication user." : "",
    userId && !authUser ? "Linked authentication user was not found." : "",
    !nonEmptyString(profile.member_id) || !profileName ||
      !(nonEmptyString(profile.email) || nonEmptyString(authUser?.email))
      ? "Profile is missing an ID number, name, or email."
      : "",
    role === "Unknown" ? "Account role is missing or unsupported." : "",
    nonEmptyString(profile.role) && authRoleKnown && authUser && normalizeRole(profile.role) !== role
      ? "Profile role does not match the trusted authentication role."
      : "",
  ].filter(Boolean);

  return {
    accountKey: userId ?? `profile:${profileId}`,
    authUserId: userId,
    profileLinked: Boolean(userId && authUser),
    idNumber: nonEmptyString(profile.member_id),
    fullName: profileName || authName,
    email: nonEmptyString(profile.email) || nonEmptyString(authUser?.email),
    phone: nonEmptyString(profile.phone),
    address: nonEmptyString(profile.address),
    role,
    membershipType,
    department: role === "Member" ? nonEmptyString(profile.department) : "",
    status: getStatus(
      profile.status,
      appMetadata.account_status,
      authUser?.banned_until,
    ),
    createdAt:
      nonEmptyString(profile.created_at) || nonEmptyString(authUser?.created_at),
    integrityIssue: identityIssues.length ? identityIssues.join(" ") : null,
  };
}

function mapAuthOnlyUser(user: JsonObject): AccountRecord {
  const appMetadata = asRecord(user.app_metadata);
  const role = appMetadata.role;
  const metadata = asRecord(user.user_metadata);
  const displayRole = getRole(role, null);
  return {
    accountKey: nonEmptyString(user.id),
    authUserId: nonEmptyString(user.id) || null,
    profileLinked: false,
    idNumber: "",
    fullName: nonEmptyString(metadata.full_name),
    email: nonEmptyString(user.email),
    phone: "",
    address: "",
    role: displayRole,
    membershipType: null,
    department: "",
    status: getStatus(null, appMetadata.account_status, user.banned_until),
    createdAt: nonEmptyString(user.created_at),
    integrityIssue: displayRole === "Unknown"
      ? "Authentication account has no recognized trusted role."
      : role === "member"
      ? "Member authentication account has no linked member profile."
      : "Administrative authentication account has no linked member profile.",
  };
}

class AccountSnapshotChangedError extends Error {}

async function readStableSnapshot<T>(
  scan: () => Promise<T[]>,
  keyOf: (value: T) => string,
  description: string,
): Promise<T[]> {
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const first = await scan();
    const second = await scan();
    const firstKeys = new Set(first.map(keyOf));
    const secondKeys = new Set(second.map(keyOf));
    if (
      firstKeys.size === secondKeys.size &&
      [...firstKeys].every((key) => secondKeys.has(key))
    ) {
      return second;
    }
  }
  throw new AccountSnapshotChangedError(
    `${description} changed during pagination. Retry the account listing.`,
  );
}

async function listAllProfiles(
  admin: ReturnType<typeof createClient>,
): Promise<JsonObject[]> {
  const pageSize = 500;
  return await readStableSnapshot(
    async () => {
      const profiles = new Map<string, JsonObject>();
      for (let offset = 0; ; offset += pageSize) {
        const { data, error } = await admin
          .from("members")
          // Optional profile fields vary across deployed schemas. Only mapped
          // account fields below are returned to the browser.
          .select("*")
          .order("created_at", { ascending: false, nullsFirst: false })
          .order("id", { ascending: true })
          .range(offset, offset + pageSize - 1);
        if (error) throw error;
        for (const value of data ?? []) {
          const profile = value as unknown as JsonObject;
          const id = nonEmptyString(profile.id);
          if (!id) {
            throw new Error("A member profile is missing its primary key.");
          }
          profiles.set(id, profile);
        }
        if ((data?.length ?? 0) < pageSize) break;
      }
      return [...profiles.values()];
    },
    (profile) => nonEmptyString(profile.id),
    "Member profiles",
  );
}

async function listAllAuthUsers(
  admin: ReturnType<typeof createClient>,
): Promise<JsonObject[]> {
  const perPage = 1000;
  return await readStableSnapshot(
    async () => {
      const users = new Map<string, JsonObject>();
      for (let page = 1; ; page += 1) {
        const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
        if (error) throw error;
        for (const user of data.users) {
          users.set(user.id, user as unknown as JsonObject);
        }
        if (data.users.length < perPage) break;
      }
      return [...users.values()];
    },
    (user) => nonEmptyString(user.id),
    "Auth accounts",
  );
}

function isCurrentlyBanned(bannedUntil: unknown): boolean {
  if (typeof bannedUntil !== "string") return false;
  const expiry = Date.parse(bannedUntil);
  return Number.isFinite(expiry) && expiry > Date.now();
}

function isMissingAccountSchema(error: { code?: string; message?: string }) {
  return error.code === "42703" ||
    error.code === "PGRST204" ||
    /column .* does not exist|could not find the .* column/i.test(error.message ?? "");
}

serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  if (request.method !== "POST") {
    return respond({ error: { code: "method_not_allowed", message: "Method not allowed." } }, 405);
  }
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Account listing function is missing server configuration.");
    return respond({
      error: {
        code: "server_misconfigured",
        message: "The secure account listing service is not configured.",
      },
    }, 503);
  }

  const bearer = request.headers.get("Authorization")?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!bearer) {
    return respond({
      error: { code: "unauthorized", message: "Authentication is required." },
    }, 401);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await admin.auth.getUser(bearer);
  if (authError || !authData.user) {
    return respond({
      error: { code: "session_expired", message: "Your session has expired. Sign in again." },
    }, 401);
  }
  const authAppMetadata = asRecord(authData.user.app_metadata);
  const accountStatus = authAppMetadata.account_status;
  if (
    !["super_admin", "admin", "coop_admin"].includes(nonEmptyString(authAppMetadata.role)) ||
    (accountStatus !== undefined && accountStatus !== "active") ||
    isCurrentlyBanned(authData.user.banned_until)
  ) {
    return respond({
      error: { code: "forbidden", message: "Admin or Super Admin access is required." },
    }, 403);
  }

  const { data: actorProfile, error: actorProfileError } = await admin
    .from("members")
    .select("status")
    .eq("user_id", authData.user.id)
    .maybeSingle();
  if (actorProfileError) {
    console.error("Secure account listing authorization status lookup failed:", {
      code: actorProfileError.code,
      message: actorProfileError.message,
    });
    return respond({
      error: {
        code: actorProfileError.code === "42501"
          ? "database_permission"
          : "authorization_status_failure",
        message: actorProfileError.code === "42501"
          ? "The account service lacks permission to read member status."
          : "Unable to verify the administrator account status.",
      },
    }, 503);
  }
  const profileStatus = actorProfile?.status;
  if (
    (actorProfile && profileStatus !== "active") ||
    (!actorProfile && accountStatus !== "active")
  ) {
    return respond({
      error: { code: "forbidden", message: "An active administrator account is required." },
    }, 403);
  }

  let profiles: JsonObject[];
  let authUsers: JsonObject[];
  try {
    [profiles, authUsers] = await Promise.all([
      listAllProfiles(admin),
      listAllAuthUsers(admin),
    ]);
  } catch (error) {
    if (error instanceof AccountSnapshotChangedError) {
      return respond({
        error: {
          code: "account_snapshot_unstable",
          message: error.message,
        },
      }, 503);
    }
    const databaseError = error as { code?: string; message?: string };
    console.error("Secure account listing query failed:", {
      code: databaseError.code,
      message: databaseError.message,
    });
    return respond({
      error: isMissingAccountSchema(databaseError)
        ? {
          code: "schema_not_migrated",
          message: "The account database is missing required columns. Review and apply the approved account reconciliation migration, then retry.",
        }
        : databaseError.code === "42501"
          ? {
            code: "database_permission",
            message: "The secure account service lacks required database permissions.",
          }
          : {
            code: "database_failure",
            message: "Unable to retrieve account profiles from the secure database.",
          },
    }, 503);
  }

  const usersById = new Map<string, JsonObject>();
  for (const user of authUsers) {
    const userId = nonEmptyString(user.id);
    if (userId) usersById.set(userId, user);
  }

  const accounts = new Map<string, AccountRecord>();
  for (const profile of profiles) {
    const linkedUserId = nonEmptyString(profile.user_id);
    const linkedUser = linkedUserId ? usersById.get(linkedUserId) ?? null : null;
    const account = mapProfile(profile, linkedUser);
    const existingAccount = accounts.get(account.accountKey);
    if (existingAccount) {
      existingAccount.profileLinked = false;
      existingAccount.integrityIssue = [
        existingAccount.integrityIssue,
        "Multiple member profiles link to the same authentication account.",
      ]
        .filter(Boolean)
        .join(" ");
      continue;
    }
    accounts.set(account.accountKey, account);
  }
  for (const authUser of authUsers) {
    const userId = nonEmptyString(authUser.id);
    if (!userId || accounts.has(userId)) continue;
    const account = mapAuthOnlyUser(authUser);
    accounts.set(userId, account);
  }

  const result = Array.from(accounts.values()).sort((first, second) => {
    const secondTime = Date.parse(second.createdAt);
    const firstTime = Date.parse(first.createdAt);
    const timeDifference = (Number.isNaN(secondTime) ? 0 : secondTime) -
      (Number.isNaN(firstTime) ? 0 : firstTime);
    return timeDifference || first.accountKey.localeCompare(second.accountKey);
  });
  return respond({
    success: true,
    accounts: result,
    dataIntegrityIssues: result.filter((account) => account.integrityIssue).length,
  });
});
