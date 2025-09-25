-- Create both versions of the function for compatibility
-- This ensures the function works with both old and new signatures

-- =============================================
-- 1. ENSURE TEAM_ID COLUMN EXISTS
-- =============================================

-- Add team_id column if it doesn't exist
ALTER TABLE public.team_invitations 
ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE;

-- Create index
CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON public.team_invitations(team_id);

-- =============================================
-- 2. DROP ALL EXISTING VERSIONS
-- =============================================

-- Drop all existing versions to avoid conflicts
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT);

-- =============================================
-- 3. CREATE NEW VERSION (5 parameters)
-- =============================================

CREATE OR REPLACE FUNCTION public.create_team_invitation(
  invite_email TEXT,
  invite_name TEXT,
  project_id_param UUID,
  team_id_param UUID,
  invite_role TEXT DEFAULT 'developer'
)
RETURNS UUID AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 4. CREATE LEGACY VERSION (4 parameters)
-- =============================================

-- Create a legacy version that works with the old signature
-- This will use the first team in the project as default
CREATE OR REPLACE FUNCTION public.create_team_invitation(
  invite_email TEXT,
  invite_name TEXT,
  project_id_param UUID,
  invite_role TEXT DEFAULT 'developer'
)
RETURNS UUID AS $$
DECLARE
  invitation_id UUID;
  user_id_param UUID;
  default_team_id UUID;
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
  
  -- Get the first team in the project (or create a default one)
  SELECT id INTO default_team_id 
  FROM public.teams 
  WHERE project_id = project_id_param 
  ORDER BY created_at 
  LIMIT 1;
  
  -- If no team exists, create a default team
  IF default_team_id IS NULL THEN
    INSERT INTO public.teams (name, description, project_id, created_by)
    VALUES (
      'Default Team',
      'Default team for ' || (SELECT name FROM public.projects WHERE id = project_id_param),
      project_id_param,
      user_id_param
    )
    RETURNING id INTO default_team_id;
  END IF;
  
  -- Check if invitation already exists for this email, project, and default team
  IF EXISTS (
    SELECT 1 FROM public.team_invitations 
    WHERE email = invite_email 
    AND project_id = project_id_param 
    AND team_id = default_team_id
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'An invitation for this email already exists for the default team in this project';
  END IF;
  
  -- Create the invitation with the default team
  INSERT INTO public.team_invitations (email, name, role, project_id, team_id, invited_by)
  VALUES (invite_email, invite_name, invite_role, project_id_param, default_team_id, user_id_param)
  RETURNING id INTO invitation_id;
  
  RETURN invitation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 5. GRANT PERMISSIONS
-- =============================================

-- Grant execute permissions on both function versions
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, UUID, TEXT) TO authenticated;

-- =============================================
-- 6. VERIFY BOTH FUNCTIONS EXIST
-- =============================================

-- Check that both function versions exist
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'create_team_invitation' 
AND routine_schema = 'public'
ORDER BY specific_name;

-- Show function parameters
SELECT 
    p.parameter_name,
    p.data_type,
    p.parameter_default,
    p.ordinal_position,
    r.specific_name
FROM information_schema.parameters p
JOIN information_schema.routines r ON p.specific_name = r.specific_name
WHERE r.routine_name = 'create_team_invitation' 
AND r.routine_schema = 'public'
ORDER BY r.specific_name, p.ordinal_position;

-- =============================================
-- 7. CREATE ACCEPT FUNCTION
-- =============================================

-- Update the accept_team_invitation function
CREATE OR REPLACE FUNCTION public.accept_team_invitation(
  invitation_token TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  invitation_record RECORD;
BEGIN
  -- Get the invitation
  SELECT * INTO invitation_record 
  FROM public.team_invitations 
  WHERE token = invitation_token 
  AND status = 'pending' 
  AND expires_at > NOW();
  
  -- Check if invitation exists and is valid
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation token';
  END IF;
  
  -- Check if user profile exists
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'User profile not found';
  END IF;
  
  -- Add user to the specific team
  INSERT INTO public.team_members (team_id, profile_id, role)
  VALUES (
    invitation_record.team_id, 
    auth.uid(), 
    invitation_record.role
  )
  ON CONFLICT (team_id, profile_id) DO UPDATE SET
    role = EXCLUDED.role,
    joined_at = NOW();
  
  -- Mark invitation as accepted
  UPDATE public.team_invitations 
  SET status = 'accepted', updated_at = NOW()
  WHERE id = invitation_record.id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(TEXT) TO authenticated;
