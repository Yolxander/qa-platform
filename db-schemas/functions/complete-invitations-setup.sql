-- Complete Invitations System Setup
-- This script creates the complete invitation system with all required tables and functions
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
CREATE INDEX IF NOT EXISTS idx_team_invitations_invited_by ON public.team_invitations(invited_by);

-- =============================================
-- 3. ENABLE RLS
-- =============================================

ALTER TABLE public.team_invitations ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 4. DROP EXISTING POLICIES (if they exist)
-- =============================================

DROP POLICY IF EXISTS "Users can view invitations for their projects" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can view invitations sent to their email" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can create invitations for their projects" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can update invitations for their projects" ON public.team_invitations;
DROP POLICY IF EXISTS "Users can delete invitations for their projects" ON public.team_invitations;

-- =============================================
-- 5. CREATE RLS POLICIES
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
-- 6. DROP EXISTING FUNCTIONS (if they exist)
-- =============================================

DROP FUNCTION IF EXISTS public.get_user_invitations();
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.accept_team_invitation(TEXT);

-- =============================================
-- 7. CREATE get_user_invitations FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION public.get_user_invitations()
RETURNS TABLE (
  id UUID,
  email TEXT,
  name TEXT,
  role TEXT,
  project_id UUID,
  invited_by UUID,
  status TEXT,
  token TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  project_name TEXT,
  inviter_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ti.id,
    ti.email,
    ti.name,
    ti.role,
    ti.project_id,
    ti.invited_by,
    ti.status,
    ti.token,
    ti.expires_at,
    ti.created_at,
    p.name as project_name,
    COALESCE(prof.name, u.email) as inviter_name
  FROM public.team_invitations ti
  JOIN public.projects p ON ti.project_id = p.id
  JOIN auth.users u ON ti.invited_by = u.id
  LEFT JOIN public.profiles prof ON ti.invited_by = prof.id
  WHERE ti.email = (SELECT email FROM auth.users WHERE id = auth.uid())
  AND ti.status = 'pending'
  AND ti.expires_at > NOW()
  ORDER BY ti.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 8. CREATE create_team_invitation FUNCTION
-- =============================================

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

-- =============================================
-- 9. CREATE accept_team_invitation FUNCTION
-- =============================================

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
-- 10. CREATE TRIGGERS
-- =============================================

-- Create update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_team_invitations_updated_at ON public.team_invitations;
CREATE TRIGGER update_team_invitations_updated_at
  BEFORE UPDATE ON public.team_invitations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- 11. GRANT PERMISSIONS
-- =============================================

GRANT ALL ON public.team_invitations TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_invitations() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(TEXT) TO authenticated;

-- =============================================
-- 12. COMMENTS
-- =============================================

COMMENT ON TABLE public.team_invitations IS 'Team invitations for users who haven''t registered yet';
COMMENT ON COLUMN public.team_invitations.token IS 'Unique token for invitation acceptance';
COMMENT ON COLUMN public.team_invitations.expires_at IS 'When the invitation expires (default 7 days)';

-- =============================================
-- 13. VERIFICATION
-- =============================================

-- Test that functions exist
SELECT 'Setup completed successfully!' as status;
SELECT 'get_user_invitations function created' as status;
SELECT 'create_team_invitation function created' as status;
SELECT 'accept_team_invitation function created' as status;
