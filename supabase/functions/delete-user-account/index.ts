// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

interface DeleteAccountRequest {
  userId: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Create a Supabase client with the Auth context of the logged in user
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get the user from the auth token
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      throw new Error('User not authenticated')
    }

    // Parse request body
    const { userId }: DeleteAccountRequest = await req.json()

    // Verify the user is deleting their own account
    if (user.id !== userId) {
      throw new Error('Users can only delete their own account')
    }

    // Create admin client to delete user
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    )

    // Delete user profile and related data from database
    // Note: This assumes you have CASCADE DELETE set up in your foreign keys
    const { error: deleteProfileError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('id', userId)

    if (deleteProfileError) {
      console.error('Error deleting user profile:', deleteProfileError)
      throw new Error(`Failed to delete user profile: ${deleteProfileError.message}`)
    }

    // Delete user's uploaded files from storage
    try {
      // List and delete files from profile-pictures bucket
      const { data: profilePictures } = await supabaseAdmin
        .storage
        .from('profile-pictures')
        .list(userId)

      if (profilePictures && profilePictures.length > 0) {
        const profilePicturePaths = profilePictures.map(file => `${userId}/${file.name}`)
        await supabaseAdmin
          .storage
          .from('profile-pictures')
          .remove(profilePicturePaths)
      }

      // List and delete files from driver-licenses bucket
      const { data: licenses } = await supabaseAdmin
        .storage
        .from('driver-licenses')
        .list(userId)

      if (licenses && licenses.length > 0) {
        const licensePaths = licenses.map(file => `${userId}/${file.name}`)
        await supabaseAdmin
          .storage
          .from('driver-licenses')
          .remove(licensePaths)
      }
    } catch (storageError) {
      console.error('Error deleting storage files:', storageError)
      // Continue with user deletion even if storage cleanup fails
    }

    // Delete user from Supabase Auth
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(
      userId
    )

    if (deleteAuthError) {
      console.error('Error deleting user from auth:', deleteAuthError)
      throw new Error(`Failed to delete user from auth: ${deleteAuthError.message}`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Account deleted successfully',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error in delete-user-account function:', error)
    return new Response(
      JSON.stringify({
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/delete-user-account' \
    --header 'Authorization: Bearer YOUR_ANON_KEY' \
    --header 'Content-Type: application/json' \
    --data '{"userId":"USER_ID_HERE"}'

*/
