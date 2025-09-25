-- Simple RLS Fix - Minimal Policies to Avoid Recursion
-- This script creates the most basic policies needed to avoid infinite recursion

-- =============================================
-- 1. DROP ALL EXISTING POLICIES
-- =============================================

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "Users can access projects from their teams" ON public.projects;
DROP POLICY IF EXISTS "Users can view teams in their projects" ON public.teams;
DROP POLICY IF EXISTS "Users can access teams they are members of" ON public.teams;
DROP POLICY IF EXISTS "Users can view team members in their project teams" ON public.team_members;
DROP POLICY IF EXISTS "Users can access their team memberships" ON public.team_members;
DROP POLICY IF EXISTS "Users can view own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can view teams in own projects" ON public.teams;
DROP POLICY IF EXISTS "Users can view own memberships" ON public.team_members;
DROP POLICY IF EXISTS "Users can create teams in their projects" ON public.teams;
DROP POLICY IF EXISTS "Users can add team members to their project teams" ON public.team_members;
DROP POLICY IF EXISTS "Users can update team members in their project teams" ON public.team_members;
DROP POLICY IF EXISTS "Users can delete team members in their project teams" ON public.team_members;

-- =============================================
-- 2. CREATE SIMPLE POLICIES
-- =============================================

-- Basic policy for projects - users can only see their own projects
CREATE POLICY "Users can view own projects" ON public.projects
  FOR SELECT USING (user_id = auth.uid());

-- Basic policy for teams - users can see teams in their projects
CREATE POLICY "Users can view teams in own projects" ON public.teams
  FOR SELECT USING (
    project_id IN (
      SELECT id FROM public.projects WHERE user_id = auth.uid()
    )
  );

-- Basic policy for team_members - users can see their own memberships
CREATE POLICY "Users can view own memberships" ON public.team_members
  FOR SELECT USING (profile_id = auth.uid());

-- =============================================
-- 3. GRANT BASIC PERMISSIONS
-- =============================================

-- Ensure the functions have the right permissions
GRANT EXECUTE ON FUNCTION get_member_teams(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;

-- =============================================
-- 4. TEST THE SETUP
-- =============================================

-- Check that policies exist
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  cmd, 
  qual 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('projects', 'teams', 'team_members')
ORDER BY tablename, policyname;
