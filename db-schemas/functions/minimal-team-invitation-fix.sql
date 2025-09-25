-- Minimal fix for team-specific invitations
-- This script only adds what's needed without recreating existing policies

-- =============================================
-- 1. ADD TEAM_ID COLUMN (if not exists)
-- =============================================

-- Add team_id column to team_invitations table
ALTER TABLE public.team_invitations 
ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE;

-- =============================================
-- 2. CREATE INDEX FOR NEW COLUMN
-- =============================================

CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON public.team_invitations(team_id);

-- =============================================
-- 3. UPDATE THE FUNCTION TO INCLUDE TEAM_ID
-- =============================================

-- Drop the old function if it exists
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);

-- Create the new function with team_id parameter
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
-- 4. UPDATE ACCEPT INVITATION FUNCTION
-- =============================================

-- Update the accept_team_invitation function to handle team_id
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

-- =============================================
-- 5. ADD COMMENTS
-- =============================================

COMMENT ON COLUMN public.team_invitations.team_id IS 'Foreign key reference to teams table - specifies which team the user is being invited to';
