-- Fix RLS policies for teams table to prevent recursion
-- This script ensures teams table policies don't cause infinite recursion

-- Step 1: Drop all existing RLS policies on teams table
DROP POLICY IF EXISTS "Users can view teams" ON public.teams;
DROP POLICY IF EXISTS "Users can insert teams" ON public.teams;
DROP POLICY IF EXISTS "Users can update teams" ON public.teams;
DROP POLICY IF EXISTS "Users can delete teams" ON public.teams;
DROP POLICY IF EXISTS "Users can view teams in their projects" ON public.teams;
DROP POLICY IF EXISTS "Users can manage teams in their projects" ON public.teams;
DROP POLICY IF EXISTS "Team members can view their teams" ON public.teams;

-- Step 2: Create simple, non-recursive RLS policies for teams
-- Policy for SELECT (viewing teams)
CREATE POLICY "Users can view teams in their projects" ON public.teams
    FOR SELECT USING (
        -- User can see teams from projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            WHERE p.id = teams.project_id 
            AND p.user_id = auth.uid()
        ) OR
        -- User can see teams they are a member of
        EXISTS (
            SELECT 1 FROM public.team_members tm
            WHERE tm.team_id = teams.id 
            AND tm.profile_id = auth.uid()
        )
    );

-- Policy for INSERT (creating teams)
CREATE POLICY "Users can create teams in their projects" ON public.teams
    FOR INSERT WITH CHECK (
        -- User can create teams in projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            WHERE p.id = teams.project_id 
            AND p.user_id = auth.uid()
        )
    );

-- Policy for UPDATE (updating teams)
CREATE POLICY "Users can update teams in their projects" ON public.teams
    FOR UPDATE USING (
        -- User can update teams in projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            WHERE p.id = teams.project_id 
            AND p.user_id = auth.uid()
        )
    );

-- Policy for DELETE (deleting teams)
CREATE POLICY "Users can delete teams in their projects" ON public.teams
    FOR DELETE USING (
        -- User can delete teams in projects they own
        EXISTS (
            SELECT 1 FROM public.projects p
            WHERE p.id = teams.project_id 
            AND p.user_id = auth.uid()
        )
    );

-- Step 3: Ensure RLS is enabled on teams table
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Step 4: Grant necessary permissions
GRANT ALL ON public.teams TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT ON public.projects TO authenticated;

-- Step 5: Test the policies with a simple query
-- This should work without recursion errors
SELECT COUNT(*) as total_teams FROM public.teams;

-- Step 6: Add helpful comments
COMMENT ON TABLE public.teams IS 'Teams table with non-recursive RLS policies';

-- Verification queries
SELECT 
    'RLS Policies' as check_type,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'teams' AND schemaname = 'public';

SELECT 
    'Teams Table Access' as check_type,
    COUNT(*) as accessible_teams
FROM public.teams;
