-- Fix bugs table RLS policies to avoid team_members recursion
-- This script creates simple, non-recursive policies for bugs table only

-- Step 1: Drop all existing RLS policies on bugs table
DROP POLICY IF EXISTS "Users can view all bugs" ON public.bugs;
DROP POLICY IF EXISTS "Users can view bugs in their projects" ON public.bugs;
DROP POLICY IF EXISTS "Users can view bugs assigned to them" ON public.bugs;
DROP POLICY IF EXISTS "Users can insert bugs" ON public.bugs;
DROP POLICY IF EXISTS "Users can update own bugs" ON public.bugs;
DROP POLICY IF EXISTS "Users can delete own bugs" ON public.bugs;
DROP POLICY IF EXISTS "Users can get bugs with assignee names" ON public.bugs;
DROP POLICY IF EXISTS "Users can view bugs from their projects" ON public.bugs;
DROP POLICY IF EXISTS "Users can update bugs in their projects" ON public.bugs;
DROP POLICY IF EXISTS "Users can delete bugs in their projects" ON public.bugs;

-- Step 2: Create simple, non-recursive RLS policies for bugs table
-- Policy for SELECT (viewing bugs) - NO team_members references
CREATE POLICY "Users can view bugs in their projects" ON public.bugs
    FOR SELECT USING (
        -- User can see bugs from projects they own
        user_id = auth.uid() OR
        -- User can see bugs from projects they own (direct project check)
        EXISTS (
            SELECT 1 FROM public.projects 
            WHERE projects.id = bugs.project_id 
            AND projects.user_id = auth.uid()
        )
    );

-- Policy for INSERT (creating bugs) - NO team_members references
CREATE POLICY "Users can insert bugs" ON public.bugs
    FOR INSERT WITH CHECK (
        -- User can create bugs in their own projects
        user_id = auth.uid() AND (
            project_id IS NULL OR 
            EXISTS (
                SELECT 1 FROM public.projects 
                WHERE projects.id = bugs.project_id 
                AND projects.user_id = auth.uid()
            )
        )
    );

-- Policy for UPDATE (updating bugs) - NO team_members references
CREATE POLICY "Users can update bugs in their projects" ON public.bugs
    FOR UPDATE USING (
        -- User can update bugs from their own projects
        user_id = auth.uid() OR
        -- User can update bugs from projects they own
        EXISTS (
            SELECT 1 FROM public.projects 
            WHERE projects.id = bugs.project_id 
            AND projects.user_id = auth.uid()
        )
    );

-- Policy for DELETE (deleting bugs) - NO team_members references
CREATE POLICY "Users can delete bugs in their projects" ON public.bugs
    FOR DELETE USING (
        -- User can delete bugs from their own projects
        user_id = auth.uid() OR
        -- User can delete bugs from projects they own
        EXISTS (
            SELECT 1 FROM public.projects 
            WHERE projects.id = bugs.project_id 
            AND projects.user_id = auth.uid()
        )
    );

-- Step 3: Ensure RLS is enabled on bugs table
ALTER TABLE public.bugs ENABLE ROW LEVEL SECURITY;

-- Step 4: Grant necessary permissions
GRANT ALL ON public.bugs TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT ON public.projects TO authenticated;

-- Step 5: Test the policies with a simple query
-- This should work without recursion errors
SELECT COUNT(*) as total_bugs FROM public.bugs;

-- Step 6: Add helpful comments
COMMENT ON TABLE public.bugs IS 'Bugs table with simple RLS policies (no team_members references)';

-- Verification queries
SELECT 
    'RLS Policies' as check_type,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'bugs' AND schemaname = 'public';

SELECT 
    'Bugs Table Access' as check_type,
    COUNT(*) as accessible_bugs
FROM public.bugs;

-- Test specific queries that might cause recursion
SELECT 
    'Test: Bugs by project' as test_type,
    COUNT(*) as bug_count
FROM public.bugs 
WHERE project_id IS NOT NULL;

SELECT 
    'Test: Bugs by user' as test_type,
    COUNT(*) as bug_count
FROM public.bugs 
WHERE user_id = auth.uid();
