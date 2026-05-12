import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, password, invite_code, display_name, phone } = await req.json()

    if (!email || !password || !invite_code || !display_name) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: email, password, invite_code, display_name' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Service role client — bypasses RLS for invite validation and user creation
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // 1. Validate invite code — must exist and be unused
    const { data: code, error: codeError } = await supabaseAdmin
      .from('invite_codes')
      .select('*')
      .eq('code', invite_code.trim().toUpperCase())
      .eq('used', false)
      .single()

    if (codeError || !code) {
      return new Response(
        JSON.stringify({ error: 'Invalid or already used invite code.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Create the auth user (email confirmed — no verification email)
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    })

    if (authError || !authData.user) {
      return new Response(
        JSON.stringify({ error: authError?.message ?? 'Failed to create account.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = authData.user.id

    // 3. Create profile row with role from invite code
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: userId,
        role: code.role,
        display_name: display_name.trim(),
        email: email.toLowerCase().trim(),
        phone: phone?.trim() ?? null,
        invite_code_used: code.code,
      })

    if (profileError) {
      // Rollback auth user so no orphaned accounts exist
      await supabaseAdmin.auth.admin.deleteUser(userId)
      return new Response(
        JSON.stringify({ error: 'Failed to create profile. Please try again.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 4. Mark invite code as used
    const { error: markError } = await supabaseAdmin
      .from('invite_codes')
      .update({
        used: true,
        used_by: userId,
        used_at: new Date().toISOString(),
      })
      .eq('code', code.code)

    if (markError) {
      // Non-fatal — profile was created. Log and continue.
      console.error('Failed to mark invite code as used:', markError.message)
    }

    // 5. Return success — client calls signInWithPassword() to get the session
    return new Response(
      JSON.stringify({
        success: true,
        user_id: userId,
        role: code.role,
        message: 'Account created successfully.',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('Unexpected error:', err)
    return new Response(
      JSON.stringify({ error: 'An unexpected error occurred.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
