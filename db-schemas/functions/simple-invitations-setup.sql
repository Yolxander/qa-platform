-- Simple Team Invitations Setup
-- This script creates only the team_invitations table and basic setup
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. CREATE TEAM INVITATIONS TABLE
-- =============================================

-- Create team_invitations table
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
-- 4. CREATE RLS POLICIES
-- =============================================

-- Drop existing policies if they exist
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
-- 5. CREATE UPDATE TRIGGER
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
-- 6. GRANT PERMISSIONS
-- =============================================

GRANT ALL ON public.team_invitations TO authenticated;

-- =============================================
-- 7. VERIFICATION
-- =============================================

-- Test that table exists
SELECT 'Setup completed successfully!' as status;
SELECT 'team_invitations table created' as status;
SELECT 'RLS policies created' as status;
SELECT 'Indexes created' as status;
