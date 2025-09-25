-- Fix Infinite Recursion in RLS Policies
-- This script fixes the infinite recursion issue in the projects table policies

-- =============================================
-- 1. DROP PROBLEMATIC POLICIES
-- =============================================

-- Drop the problematic policy that's causing infinite recursion
DROP POLICY IF EXISTS "Users can access projects from their teams" ON public.projects;

-- =============================================
-- 2. CREATE FIXED POLICIES
-- =============================================

-- Create a simpler policy for projects that doesn't cause recursion
CREATE POLICY "Users can view their own projects" ON public.projects
  FOR SELECT USING (user_id = auth.uid());

-- Create a policy for team members to view projects through team membership
-- This uses a different approach to avoid recursion
CREATE POLICY "Team members can view project details" ON public.projects
  FOR SELECT USING (
    id IN (
      SELECT DISTINCT t.project_id 
      FROM public.teams t
      INNER JOIN public.team_members tm ON t.id = tm.team_id
      WHERE tm.profile_id = auth.uid()
    )
  );

-- =============================================
-- 3. UPDATE TEAM POLICIES
-- =============================================

-- Drop and recreate team policies to be more specific
DROP POLICY IF EXISTS "Users can view teams in their projects" ON public.teams;
DROP POLICY IF EXISTS "Users can access teams they are members of" ON public.teams;

-- Create policy for teams in user's own projects
CREATE POLICY "Users can view teams in their own projects" ON public.teams
  FOR SELECT USING (
    project_id IN (
      SELECT id FROM public.projects WHERE user_id = auth.uid()
    )
  );

-- Create policy for teams where user is a member
CREATE POLICY "Users can view teams they are members of" ON public.teams
  FOR SELECT USING (
    id IN (
      SELECT team_id FROM public.team_members WHERE profile_id = auth.uid()
    )
  );

-- =============================================
-- 4. UPDATE TEAM MEMBERS POLICIES
-- =============================================

-- Drop and recreate team_members policies
DROP POLICY IF EXISTS "Users can view team members in their project teams" ON public.team_members;
DROP POLICY IF EXISTS "Users can access their team memberships" ON public.team_members;

-- Create policy for team members
CREATE POLICY "Users can view their own team memberships" ON public.team_members
  FOR SELECT USING (profile_id = auth.uid());

-- Create policy for viewing team members in teams user owns
CREATE POLICY "Project owners can view team members" ON public.team_members
  FOR SELECT USING (
    team_id IN (
      SELECT t.id 
      FROM public.teams t
      INNER JOIN public.projects p ON t.project_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

-- Create policy for viewing team members in teams user is member of
CREATE POLICY "Team members can view other team members" ON public.team_members
  FOR SELECT USING (
    team_id IN (
      SELECT team_id FROM public.team_members WHERE profile_id = auth.uid()
    )
  );

-- =============================================
-- 5. VERIFY POLICIES
-- =============================================

-- Check that policies are created without recursion
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('projects', 'teams', 'team_members')
ORDER BY tablename, policyname;
