-- Fix infinite recursion in team_members RLS policies
-- This script removes circular dependencies in RLS policies

-- Step 1: Drop all existing RLS policies on team_members table
DROP POLICY IF EXISTS "Users can view team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can insert team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can update team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can delete team members" ON public.team_members;
DROP POLICY IF EXISTS "Team members can view their own records" ON public.team_members;
DROP POLICY IF EXISTS "Team owners can manage team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can view team members in their projects" ON public.team_members;
DROP POLICY IF EXISTS "Users can manage team members in their projects" ON public.team_members;

-- Step 2: Create simple, non-recursive RLS policies for team_members
-- Policy for SELECT (viewing team members)
CREATE POLICY "Users can view team members in their projects" ON public.team_members
    FOR SELECT USING (
        -- User can see team members from projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        ) OR
        -- User can see team members from teams they belong to
        profile_id = auth.uid()
    );

-- Policy for INSERT (adding team members)
CREATE POLICY "Users can add team members to their projects" ON public.team_members
    FOR INSERT WITH CHECK (
        -- User can add members to projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        )
    );

-- Policy for UPDATE (updating team members)
CREATE POLICY "Users can update team members in their projects" ON public.team_members
    FOR UPDATE USING (
        -- User can update team members in projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        )
    );

-- Policy for DELETE (removing team members)
CREATE POLICY "Users can remove team members from their projects" ON public.team_members
    FOR DELETE USING (
        -- User can remove team members from projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        )
    );

-- Step 3: Ensure RLS is enabled on team_members table
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

-- Step 4: Grant necessary permissions
GRANT ALL ON public.team_members TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT ON public.projects TO authenticated;
GRANT SELECT ON public.teams TO authenticated;

-- Step 5: Test the policies with a simple query
-- This should work without recursion errors
SELECT COUNT(*) as total_team_members FROM public.team_members;

-- Step 6: Add helpful comments
COMMENT ON TABLE public.team_members IS 'Team members table with non-recursive RLS policies';

-- Verification queries
SELECT 
    'RLS Policies' as check_type,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'team_members' AND schemaname = 'public';

SELECT 
    'Team Members Table Access' as check_type,
    COUNT(*) as accessible_team_members
FROM public.team_members;
