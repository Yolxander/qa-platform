-- Fix team_members creation RLS policies to be less restrictive
-- This script makes team member creation policies more permissive

-- Step 1: Drop existing RLS policies on team_members table
DROP POLICY IF EXISTS "Users can view team members in their projects" ON public.team_members;
DROP POLICY IF EXISTS "Users can add team members to their projects" ON public.team_members;
DROP POLICY IF EXISTS "Users can update team members in their projects" ON public.team_members;
DROP POLICY IF EXISTS "Users can remove team members from their projects" ON public.team_members;
DROP POLICY IF EXISTS "Users can view team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can insert team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can update team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can delete team members" ON public.team_members;
DROP POLICY IF EXISTS "Team members can view their own records" ON public.team_members;
DROP POLICY IF EXISTS "Team owners can manage team members" ON public.team_members;

-- Step 2: Create less restrictive RLS policies for team_members
-- Policy for SELECT (viewing team members) - More permissive
CREATE POLICY "Users can view team members" ON public.team_members
    FOR SELECT USING (
        -- User can see team members from projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        ) OR
        -- User can see team members from teams they belong to
        profile_id = auth.uid() OR
        -- User can see all team members (temporarily more permissive)
        true
    );

-- Policy for INSERT (adding team members) - Much more permissive
CREATE POLICY "Users can add team members" ON public.team_members
    FOR INSERT WITH CHECK (
        -- User can add members to projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        ) OR
        -- Allow team member creation for any authenticated user (temporarily)
        auth.uid() IS NOT NULL
    );

-- Policy for UPDATE (updating team members) - More permissive
CREATE POLICY "Users can update team members" ON public.team_members
    FOR UPDATE USING (
        -- User can update team members from projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        ) OR
        -- User can update their own team member record
        profile_id = auth.uid()
    );

-- Policy for DELETE (removing team members) - More permissive
CREATE POLICY "Users can remove team members" ON public.team_members
    FOR DELETE USING (
        -- User can remove team members from projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            INNER JOIN public.teams t ON t.project_id = p.id
            WHERE t.id = team_members.team_id 
            AND p.user_id = auth.uid()
        ) OR
        -- User can remove their own team member record
        profile_id = auth.uid()
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
-- This should work without errors
SELECT COUNT(*) as total_team_members FROM public.team_members;

-- Step 6: Test team member creation permissions
-- This should work for any authenticated user
SELECT 
    'Team Member Creation Test' as test_type,
    COUNT(*) as accessible_teams
FROM public.teams t
WHERE EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = t.project_id 
    AND p.user_id = auth.uid()
);

-- Step 7: Add helpful comments
COMMENT ON TABLE public.team_members IS 'Team members table with permissive RLS policies for easier team creation';

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

-- Test specific team member operations
SELECT 
    'Test: Team members by team' as test_type,
    COUNT(*) as member_count
FROM public.team_members 
WHERE team_id IS NOT NULL;

SELECT 
    'Test: Team members by user' as test_type,
    COUNT(*) as member_count
FROM public.team_members 
WHERE profile_id = auth.uid();
