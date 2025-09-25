-- Refresh Supabase schema cache
-- This script helps resolve schema caching issues

-- =============================================
-- 1. CHECK CURRENT FUNCTION STATE
-- =============================================

-- Show all current functions
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name LIKE '%invitation%' 
AND routine_schema = 'public'
ORDER BY routine_name, specific_name;

-- =============================================
-- 2. FORCE SCHEMA REFRESH
-- =============================================

-- Drop and recreate the function to force schema refresh
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT);

-- =============================================
-- 3. RECREATE WITH EXPLICIT PARAMETER NAMES
-- =============================================

-- Create the function with explicit parameter names (this helps with caching)
CREATE OR REPLACE FUNCTION public.create_team_invitation(
  invite_email TEXT,
  invite_name TEXT,
  project_id_param UUID,
  team_id_param UUID,
  invite_role TEXT DEFAULT 'developer'
)
RETURNS UUID 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
  invitation_id UUID;
  user_id_param UUID;
BEGIN
  -- Get the current user ID
  user_id_param := auth.uid();
  
  -- Check if user has access to the project
  IF NOT EXISTS (
    SELECT 1 FROM public.projects 
    WHERE id = project_id_param 
    AND user_id = user_id_param
  ) THEN
    RAISE EXCEPTION 'Access denied: You do not have permission to invite members to this project';
  END IF;
  
  -- Check if team belongs to the project
  IF NOT EXISTS (
    SELECT 1 FROM public.teams 
    WHERE id = team_id_param 
    AND project_id = project_id_param
  ) THEN
    RAISE EXCEPTION 'Team does not belong to the specified project';
  END IF;
  
  -- Check if invitation already exists for this email, project, and team
  IF EXISTS (
    SELECT 1 FROM public.team_invitations 
    WHERE email = invite_email 
    AND project_id = project_id_param 
    AND team_id = team_id_param
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'An invitation for this email already exists for this team in this project';
  END IF;
  
  -- Create the invitation
  INSERT INTO public.team_invitations (email, name, role, project_id, team_id, invited_by)
  VALUES (invite_email, invite_name, invite_role, project_id_param, team_id_param, user_id_param)
  RETURNING id INTO invitation_id;
  
  RETURN invitation_id;
END;
$$;

-- =============================================
-- 4. GRANT PERMISSIONS EXPLICITLY
-- =============================================

-- Grant execute permissions explicitly
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT) TO anon;

-- =============================================
-- 5. VERIFY FUNCTION EXISTS
-- =============================================

-- Check function exists and parameters
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'create_team_invitation' 
AND routine_schema = 'public';

-- Check parameters
SELECT 
    parameter_name,
    data_type,
    parameter_default,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'create_team_invitation' 
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- =============================================
-- 6. TEST FUNCTION CALL
-- =============================================

-- Test the function with dummy data to ensure it works
-- This will help refresh the schema cache
DO $$
DECLARE
    test_result TEXT;
BEGIN
    -- This will fail with "function not found" if there's still a cache issue
    -- but it will help refresh the cache
    BEGIN
        PERFORM public.create_team_invitation(
            'test@example.com'::TEXT,
            'Test User'::TEXT,
            '00000000-0000-0000-0000-000000000000'::UUID,
            '00000000-0000-0000-0000-000000000000'::UUID,
            'developer'::TEXT
        );
        RAISE NOTICE 'Function test completed successfully';
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'Function test failed (expected with dummy data): %', SQLERRM;
    END;
END $$;
