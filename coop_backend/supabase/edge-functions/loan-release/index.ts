import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

async function sha256(value: string): Promise<string> {
  const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))
  return Array.from(new Uint8Array(hash), (byte) => byte.toString(16).padStart(2, '0')).join('')
}

serve(async (req) => {
  try {
    const { application_id, grant_token } = await req.json()

    if (!application_id || !grant_token) {
      return new Response(
        JSON.stringify({ error: 'Application and action authorization are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const token = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '')
    if (!token) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }
    if (user.app_metadata?.role !== 'super_admin') {
      return new Response(JSON.stringify({ error: 'Super Admin access required' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { data: consumed, error: grantError } = await supabase.rpc(
      'consume_admin_action_grant',
      {
        p_user_id: user.id,
        p_action_name: 'release-loan',
        p_target_id: String(application_id),
        p_request_fingerprint: await sha256('{}'),
        p_grant_token_hash: await sha256(grant_token),
      }
    )
    if (grantError || !consumed) {
      return new Response(JSON.stringify({ error: 'Action authorization is invalid or expired' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Call the database function to release loan
    const { data, error } = await supabase
      .rpc('release_loan', {
        p_application_id: application_id
      })

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify(data[0]),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
