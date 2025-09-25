-- Temporarily disable RLS to test if policies are causing the recursion
-- This script disables RLS on all related tables to isolate the issue

-- Step 1: Disable RLS on all related tables
ALTER TABLE public.bugs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects DISABLE ROW LEVEL SECURITY;

-- Step 2: Grant full access to authenticated users
GRANT ALL ON public.bugs TO authenticated;
GRANT ALL ON public.teams TO authenticated;
GRANT ALL ON public.team_members TO authenticated;
GRANT ALL ON public.projects TO authenticated;
GRANT ALL ON public.profiles TO authenticated;

-- Step 3: Test basic operations
-- These should work without any RLS restrictions
SELECT COUNT(*) as total_bugs FROM public.bugs;
SELECT COUNT(*) as total_teams FROM public.teams;
SELECT COUNT(*) as total_team_members FROM public.team_members;
SELECT COUNT(*) as total_projects FROM public.projects;

-- Step 4: Test specific bug operations
SELECT 
    b.id,
    b.title,
    b.assignee,
    p.name as assignee_name
FROM public.bugs b
LEFT JOIN public.profiles p ON b.assignee = p.id
LIMIT 5;

-- Step 5: Add comments
COMMENT ON TABLE public.bugs IS 'Bugs table with RLS temporarily disabled for testing';
COMMENT ON TABLE public.teams IS 'Teams table with RLS temporarily disabled for testing';
COMMENT ON TABLE public.team_members IS 'Team members table with RLS temporarily disabled for testing';

-- Verification
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('bugs', 'teams', 'team_members', 'projects') 
AND schemaname = 'public';
