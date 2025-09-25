-- Test script for create_team_invitation function
-- Run this after setting up the function to verify it works

-- =============================================
-- 1. CHECK CURRENT FUNCTION STATE
-- =============================================

-- List all invitation-related functions
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%invitation%' 
AND routine_schema = 'public'
ORDER BY routine_name;

-- Check function parameters
SELECT 
    p.parameter_name,
    p.data_type,
    p.parameter_default,
    p.ordinal_position
FROM information_schema.parameters p
JOIN information_schema.routines r ON p.specific_name = r.specific_name
WHERE r.routine_name = 'create_team_invitation' 
AND r.routine_schema = 'public'
ORDER BY p.ordinal_position;

-- =============================================
-- 2. CHECK TABLE STRUCTURE
-- =============================================

-- Verify team_invitations table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'team_invitations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =============================================
-- 3. CHECK SAMPLE DATA
-- =============================================

-- Check if you have projects and teams to test with
SELECT 
    'projects' as table_name,
    count(*) as record_count
FROM public.projects
UNION ALL
SELECT 
    'teams' as table_name,
    count(*) as record_count
FROM public.teams
UNION ALL
SELECT 
    'profiles' as table_name,
    count(*) as record_count
FROM public.profiles;

-- Show sample projects and teams
SELECT 
    p.id as project_id,
    p.name as project_name,
    t.id as team_id,
    t.name as team_name
FROM public.projects p
LEFT JOIN public.teams t ON t.project_id = p.id
ORDER BY p.name, t.name;

-- =============================================
-- 4. TEST FUNCTION CALL (Manual Test)
-- =============================================

-- Uncomment and modify these lines to test the function manually
-- Replace the UUIDs with actual values from your database

/*
-- Test with actual project and team IDs
DO $$
DECLARE
    test_project_id UUID;
    test_team_id UUID;
    result_id UUID;
BEGIN
    -- Get first project and team for testing
    SELECT id INTO test_project_id FROM public.projects LIMIT 1;
    SELECT id INTO test_team_id FROM public.teams WHERE project_id = test_project_id LIMIT 1;
    
    IF test_project_id IS NOT NULL AND test_team_id IS NOT NULL THEN
        -- Test the function
        SELECT public.create_team_invitation(
            'test@example.com',
            'Test User',
            test_project_id,
            test_team_id,
            'developer'
        ) INTO result_id;
        
        RAISE NOTICE 'Function test successful! Created invitation with ID: %', result_id;
        
        -- Clean up test data
        DELETE FROM public.team_invitations WHERE id = result_id;
        RAISE NOTICE 'Test invitation cleaned up';
    ELSE
        RAISE NOTICE 'No projects or teams found for testing';
    END IF;
END $$;
*/
