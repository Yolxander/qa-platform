-- Alternative Approach: Team Invitations
-- This script creates a team_invitations table to handle users who aren't registered yet
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. CREATE TEAM INVITATIONS TABLE
-- =============================================

-- Create team_invitations table for users who haven't registered yet
CREATE TABLE IF NOT EXISTS public.team_invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  role TEXT DEFAULT 'developer' CHECK (role IN ('developer', 'tester', 'guest')),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
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
CREATE INDEX IF NOT EXISTS idx_team_invitations_status ON public.team_invitations(status);
CREATE INDEX IF NOT EXISTS idx_team_invitations_token ON public.team_invitations(token);

-- =============================================
-- 3. ENABLE RLS
-- =============================================

ALTER TABLE public.team_invitations ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 4. CREATE RLS POLICIES
-- =============================================

-- Users can view invitations for their projects
CREATE POLICY "Users can view invitations for their projects" ON public.team_invitations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = team_invitations.project_id 
      AND projects.user_id = auth.uid()
    )
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
-- 5. CREATE FUNCTIONS
-- =============================================

-- Function to create team invitation
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
  
  -- Check if invitation already exists
  IF EXISTS (
    SELECT 1 FROM public.team_invitations 
    WHERE email = invite_email 
    AND project_id = project_id_param 
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'An invitation for this email already exists for this project';
  END IF;
  
  -- Create the invitation
  INSERT INTO public.team_invitations (email, name, role, project_id, invited_by)
  VALUES (invite_email, invite_name, invite_role, project_id_param, user_id_param)
  RETURNING id INTO invitation_id;
  
  RETURN invitation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept invitation (when user registers)
CREATE OR REPLACE FUNCTION public.accept_team_invitation(
  invitation_token TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  invitation_record RECORD;
  team_id UUID;
BEGIN
  -- Get the invitation
  SELECT * INTO invitation_record 
  FROM public.team_invitations 
  WHERE token = invitation_token 
  AND status = 'pending' 
  AND expires_at > NOW();
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation';
  END IF;
  
  -- Get the team for the project
  SELECT id INTO team_id 
  FROM public.teams 
  WHERE project_id = invitation_record.project_id;
  
  IF team_id IS NULL THEN
    RAISE EXCEPTION 'No team found for this project';
  END IF;
  
  -- Add the user to the team
  INSERT INTO public.team_members (team_id, profile_id, role)
  VALUES (team_id, auth.uid(), invitation_record.role)
  ON CONFLICT (team_id, profile_id) DO NOTHING;
  
  -- Update invitation status
  UPDATE public.team_invitations 
  SET status = 'accepted', updated_at = NOW()
  WHERE id = invitation_record.id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 6. CREATE TRIGGERS
-- =============================================

-- Trigger for updated_at
CREATE TRIGGER update_team_invitations_updated_at
  BEFORE UPDATE ON public.team_invitations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- 7. GRANT PERMISSIONS
-- =============================================

GRANT ALL ON public.team_invitations TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_team_invitation TO authenticated;

-- =============================================
-- 8. COMMENTS
-- =============================================

COMMENT ON TABLE public.team_invitations IS 'Team invitations for users who haven''t registered yet';
COMMENT ON COLUMN public.team_invitations.token IS 'Unique token for invitation acceptance';
COMMENT ON COLUMN public.team_invitations.expires_at IS 'When the invitation expires (default 7 days)';
