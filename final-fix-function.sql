-- Final fix for create_team_invitation function
-- Based on the error message, the function signature should be:
-- create_team_invitation(invite_email, invite_name, invite_role, project_id_param, team_id_param)

-- =============================================
-- 1. DROP ALL EXISTING VERSIONS
-- =============================================

DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, TEXT, UUID, UUID);

-- =============================================
-- 2. CREATE FUNCTION WITH EXACT SIGNATURE FROM ERROR
-- =============================================

-- The error message shows it expects: invite_email, invite_name, invite_role, project_id_param, team_id_param
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
-- 3. GRANT PERMISSIONS
-- =============================================

GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, TEXT, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, TEXT, UUID, UUID) TO anon;

-- =============================================
-- 4. VERIFY FUNCTION EXISTS
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

-- Check function parameters in order
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
