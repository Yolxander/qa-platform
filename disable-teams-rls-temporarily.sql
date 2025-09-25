-- Temporarily disable RLS on teams table to eliminate recursion
-- This script disables RLS completely to test if policies are causing the issue

-- Step 1: Disable RLS on teams table completely
ALTER TABLE public.teams DISABLE ROW LEVEL SECURITY;

-- Step 2: Grant full access to authenticated users
GRANT ALL ON public.teams TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT ON public.projects TO authenticated;

-- Step 3: Test basic operations without RLS
-- These should work without any recursion errors
SELECT COUNT(*) as total_teams FROM public.teams;

-- Step 4: Test the exact query that was failing
SELECT 
    t.*,
    p.name as project_name,
    p.user_id as project_owner
FROM public.teams t
LEFT JOIN public.projects p ON t.project_id = p.id
WHERE t.project_id = 'ceb512e0-74fd-43c2-ad93-2785c9830f7d'
ORDER BY t.created_at DESC;

-- Step 5: Test team creation
INSERT INTO public.teams (name, project_id, created_at, updated_at)
VALUES ('Test Team', 'ceb512e0-74fd-43c2-ad93-2785c9830f7d', NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Step 6: Test team member operations
SELECT 
    tm.*,
    t.name as team_name,
    p.name as project_name
FROM public.team_members tm
LEFT JOIN public.teams t ON tm.team_id = t.id
LEFT JOIN public.projects p ON t.project_id = p.id
LIMIT 5;

-- Step 7: Add comments
COMMENT ON TABLE public.teams IS 'Teams table with RLS temporarily disabled to prevent recursion';

-- Verification
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'teams' AND schemaname = 'public';

-- Test all team-related operations
SELECT 
    'Teams without RLS' as test_type,
    COUNT(*) as team_count
FROM public.teams;

SELECT 
    'Teams with projects' as test_type,
    COUNT(*) as team_count
FROM public.teams t
INNER JOIN public.projects p ON t.project_id = p.id;

SELECT 
    'Teams by specific project' as test_type,
    COUNT(*) as team_count
FROM public.teams 
WHERE project_id = 'ceb512e0-74fd-43c2-ad93-2785c9830f7d';
