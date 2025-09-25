-- Create Team-Specific Invitation Function
-- This function creates invitations for specific teams within a project
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. CREATE TEAM_INVITATIONS TABLE (if not exists)
-- =============================================

-- Create team_invitations table for users who haven't registered yet
CREATE TABLE IF NOT EXISTS public.team_invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  role TEXT DEFAULT 'developer' CHECK (role IN ('developer', 'tester', 'guest')),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
  invited_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  token TEXT UNIQUE DEFAULT gen_random_uuid(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 2. CREATE INDEXES
-- =============================================

CREATE INDEX IF NOT EXISTS idx_team_invitations_email ON public.team_invitations(email);
CREATE INDEX IF NOT EXISTS idx_team_invitations_project_id ON public.team_invitations(project_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON public.team_invitations(team_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_status ON public.team_invitations(status);
CREATE INDEX IF NOT EXISTS idx_team_invitations_token ON public.team_invitations(token);
CREATE INDEX IF NOT EXISTS idx_team_invitations_invited_by ON public.team_invitations(invited_by);

-- =============================================
-- 3. ENABLE RLS
-- =============================================

ALTER TABLE public.team_invitations ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 4. CREATE RLS POLICIES
-- =============================================

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Users can view invitations for their projects" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can view invitations sent to their email" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can create invitations for their projects" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can update invitations for their projects" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can delete invitations for their projects" ON public.team_invitations;

-- Users can view invitations for their projects
CREATE POLICY "Users can view invitations for their projects" ON public.team_invitations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = team_invitations.project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- Users can view invitations sent to their email
CREATE POLICY "Users can view invitations sent to their email" ON public.team_invitations
  FOR SELECT USING (
    email = (SELECT email FROM auth.users WHERE id = auth.uid())
  );

-- Users can create invitations for their projects
CREATE POLICY "Users can create invitations for their projects" ON public.team_invitations
  FOR INSERT WITH CHECK (
    auth.uid() = invited_by AND
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- Users can update invitations for their projects
CREATE POLICY "Users can update invitations for their projects" ON public.team_invitations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = team_invitations.project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- Users can delete invitations for their projects
CREATE POLICY "Users can delete invitations for their projects" ON public.team_invitations
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = team_invitations.project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- =============================================
-- 5. CREATE TEAM-SPECIFIC INVITATION FUNCTION
-- =============================================

-- Function to create team-specific invitation
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
-- 6. CREATE ACCEPT TEAM INVITATION FUNCTION
-- =============================================

-- Function to accept invitation (when user registers)
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
  
  -- Add user to the team
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
-- 7. GRANT PERMISSIONS
-- =============================================

GRANT ALL ON public.team_invitations TO authenticated;

-- =============================================
-- 8. ADD COMMENTS
-- =============================================

COMMENT ON TABLE public.team_invitations IS 'Team-specific invitations table for inviting users to specific teams';
COMMENT ON COLUMN public.team_invitations.team_id IS 'Foreign key reference to teams table';
COMMENT ON FUNCTION public.create_team_invitation IS 'Creates a team-specific invitation for a user';
COMMENT ON FUNCTION public.accept_team_invitation IS 'Accepts a team invitation and adds user to the team';
