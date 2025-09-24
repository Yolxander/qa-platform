import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Test endpoint to debug the invitation issue
export async function GET(request: NextRequest) {
  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    
    if (!supabaseUrl || !supabaseAnonKey) {
      return NextResponse.json({ error: 'Supabase not configured' }, { status: 500 })
    }

    // Get the authorization header
    const authHeader = request.headers.get('authorization')
    if (!authHeader) {
      return NextResponse.json({ error: 'No authorization header' }, { status: 401 })
    }

    // Extract the token from the header
    const token = authHeader.replace('Bearer ', '')
    
    // Create a new supabase client for server-side use
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    // Set the session for this request
    const { data: { user }, error: userError } = await supabase.auth.getUser(token)
    if (userError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    console.log('Test: User email:', user.email)
    console.log('Test: User ID:', user.id)

    // Test 1: Simple query without joins
    const { data: simpleData, error: simpleError } = await supabase
      .from('team_invitations')
      .select('*')
      .eq('email', user.email)

    console.log('Test: Simple query:', { simpleData, simpleError })

    // Test 2: Check if projects table exists and has data
    const { data: projectsData, error: projectsError } = await supabase
      .from('projects')
      .select('id, name')
      .limit(1)

    console.log('Test: Projects query:', { projectsData, projectsError })

    // Test 3: Check if profiles table exists and has data
    const { data: profilesData, error: profilesError } = await supabase
      .from('profiles')
      .select('id, name')
      .limit(1)

    console.log('Test: Profiles query:', { profilesData, profilesError })

    // Test 4: Try a manual join approach
    if (simpleData && simpleData.length > 0) {
      const invitation = simpleData[0]
      
      // Get project name
      const { data: projectData } = await supabase
        .from('projects')
        .select('name')
        .eq('id', invitation.project_id)
        .single()

      // Get inviter name
      const { data: profileData } = await supabase
        .from('profiles')
        .select('name')
        .eq('id', invitation.invited_by)
        .single()

      const manualJoinResult = {
        ...invitation,
        project_name: projectData?.name || 'Unknown Project',
        inviter_name: profileData?.name || 'Unknown User'
      }

      console.log('Test: Manual join result:', manualJoinResult)

      return NextResponse.json({
        success: true,
        simpleData,
        projectsData,
        profilesData,
        manualJoinResult,
        errors: {
          simpleError,
          projectsError,
          profilesError
        }
      })
    }

    return NextResponse.json({
      success: true,
      simpleData,
      projectsData,
      profilesData,
      message: 'No invitations found',
      errors: {
        simpleError,
        projectsError,
        profilesError
      }
    })

  } catch (error) {
    console.error('Error in test endpoint:', error)
    return NextResponse.json({ error: 'Internal server error', details: error.message }, { status: 500 })
  }
}
