-- Force create the create_team_invitation function and refresh schema cache
-- This script will definitely fix the PGRST202 error

-- =============================================
-- 1. FORCE DROP ALL EXISTING VERSIONS
-- =============================================

-- Drop all possible function signatures
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, TEXT, UUID, UUID);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT, UUID);

-- =============================================
-- 2. FORCE SCHEMA REFRESH
-- =============================================

-- Force refresh the schema cache
NOTIFY pgrst, 'reload schema';

-- =============================================
-- 3. CREATE FUNCTION WITH EXACT SIGNATURE
-- =============================================

-- Create the function with the exact signature from the error message
CREATE OR REPLACE FUNCTION public.create_team_invitation(
  invite_email TEXT,
  invite_name TEXT,
  invite_role TEXT,
  project_id_param UUID,
  team_id_param UUID
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
  
  -- Check if invitation already exists for this email and specific team
  -- Allow same email for different teams within the same project
  IF EXISTS (
    SELECT 1 FROM public.team_invitations 
    WHERE email = invite_email 
    AND team_id = team_id_param
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'An invitation for this email already exists for this specific team';
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

-- Grant execute permissions on the function
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, TEXT, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, TEXT, UUID, UUID) TO anon;

-- =============================================
-- 5. FORCE SCHEMA REFRESH AGAIN
-- =============================================

-- Force another schema refresh
NOTIFY pgrst, 'reload schema';

-- =============================================
-- 6. VERIFY FUNCTION EXISTS
-- =============================================

-- Check that the function exists
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'create_team_invitation' 
AND routine_schema = 'public';

-- Check function parameters
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
-- 7. TEST FUNCTION CALL (to force cache refresh)
-- =============================================

-- This will help refresh the cache even if it fails
DO $$
BEGIN
    -- Try to call the function with dummy data to refresh cache
    BEGIN
        PERFORM public.create_team_invitation(
            'test@example.com'::TEXT,
            'Test User'::TEXT,
            'developer'::TEXT,
            '00000000-0000-0000-0000-000000000000'::UUID,
            '00000000-0000-0000-0000-000000000000'::UUID
        );
        RAISE NOTICE 'Function test completed successfully';
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'Function test failed (expected with dummy data): %', SQLERRM;
    END;
END $$;
