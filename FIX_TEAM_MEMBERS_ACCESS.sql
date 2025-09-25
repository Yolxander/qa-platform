-- Fix Team Members Access for Project Owners
-- This script adds the necessary RLS policies to allow project owners to view team members

-- =============================================
-- 1. ADD POLICY FOR PROJECT OWNERS TO VIEW TEAM MEMBERS
-- =============================================

-- Allow project owners to view team members in their teams
CREATE POLICY "Project owners can view team members in their teams" ON public.team_members
  FOR SELECT USING (
    team_id IN (
      SELECT t.id 
      FROM public.teams t
      INNER JOIN public.projects p ON t.project_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

-- =============================================
-- 2. VERIFY THE POLICIES
-- =============================================

-- Check that the policy was created
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  cmd, 
  qual 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'team_members'
ORDER BY policyname;
