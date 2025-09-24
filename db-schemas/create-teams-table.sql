-- Create Teams Table and Team Members Schema
-- This script creates the teams table and team_members junction table
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. CREATE TABLES
-- =============================================

-- Create teams table
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create team_members junction table
CREATE TABLE IF NOT EXISTS public.team_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'developer' CHECK (role IN ('developer', 'tester', 'guest')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, profile_id)
);

-- =============================================
-- 2. CREATE INDEXES
-- =============================================

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_teams_project_id ON public.teams(project_id);
CREATE INDEX IF NOT EXISTS idx_teams_created_by ON public.teams(created_by);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_profile_id ON public.team_members(profile_id);

-- =============================================
-- 3. ENABLE ROW LEVEL SECURITY
-- =============================================

-- Enable RLS on tables
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 4. CREATE RLS POLICIES
-- =============================================

-- Teams policies
CREATE POLICY "Users can view teams in their projects" ON public.teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = teams.project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create teams in their projects" ON public.teams
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update teams in their projects" ON public.teams
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = teams.project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete teams in their projects" ON public.teams
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = teams.project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- Team members policies
CREATE POLICY "Users can view team members in their project teams" ON public.team_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can add team members to their project teams" ON public.team_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update team members in their project teams" ON public.team_members
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can remove team members from their project teams" ON public.team_members
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

-- =============================================
-- 5. CREATE TRIGGERS
-- =============================================

-- Create trigger for updated_at on teams
CREATE TRIGGER update_teams_updated_at
  BEFORE UPDATE ON public.teams
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Function to automatically create a team when a project is created
CREATE OR REPLACE FUNCTION public.create_default_team_for_project()
RETURNS TRIGGER AS $$
BEGIN
  -- Create a default team for the new project
  INSERT INTO public.teams (name, description, project_id, created_by)
  VALUES (
    NEW.name || ' Team',
    'Default team for ' || NEW.name,
    NEW.id,
    NEW.user_id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create team when project is created
CREATE TRIGGER create_default_team_for_project_trigger
  AFTER INSERT ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.create_default_team_for_project();

-- Function to add project owner as team owner (developer role)
CREATE OR REPLACE FUNCTION public.add_project_owner_to_team()
RETURNS TRIGGER AS $$
BEGIN
  -- Add the project owner as team developer
  INSERT INTO public.team_members (team_id, profile_id, role)
  VALUES (NEW.id, NEW.created_by, 'developer');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to add project owner to team
CREATE TRIGGER add_project_owner_to_team_trigger
  AFTER INSERT ON public.teams
  FOR EACH ROW EXECUTE FUNCTION public.add_project_owner_to_team();

-- =============================================
-- 6. GRANT PERMISSIONS
-- =============================================

-- Grant necessary permissions
GRANT ALL ON public.teams TO authenticated;
GRANT ALL ON public.team_members TO authenticated;

-- =============================================
-- 7. ADD COMMENTS
-- =============================================

-- Add comments for documentation
COMMENT ON TABLE public.teams IS 'Teams table for organizing team members by project';
COMMENT ON TABLE public.team_members IS 'Junction table linking teams to profiles (team members)';
COMMENT ON COLUMN public.teams.project_id IS 'Foreign key reference to projects table';
COMMENT ON COLUMN public.team_members.role IS 'Role of the team member: developer, tester, or guest';

-- =============================================
-- 8. VERIFICATION QUERIES
-- =============================================

-- Verify tables were created
SELECT 
  table_name, 
  table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('teams', 'team_members');

-- Verify RLS is enabled
SELECT 
  schemaname, 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('teams', 'team_members');

-- Verify policies were created
SELECT 
  schemaname, 
  tablename, 
  policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('teams', 'team_members');
