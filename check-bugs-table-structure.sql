-- Check bugs table structure and fix any issues
-- This script verifies the bugs table has the correct structure

-- Step 1: Check current table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'bugs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Check if assignee column exists and is correct type
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'bugs' 
            AND column_name = 'assignee' 
            AND data_type = 'uuid'
        ) THEN 'assignee column exists and is UUID type'
        ELSE 'assignee column missing or wrong type'
    END as assignee_status;

-- Step 3: Check foreign key constraints
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'bugs';

-- Step 4: Check RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'bugs' AND schemaname = 'public';

-- Step 5: Check if bugs table has the required columns
DO $$
BEGIN
    -- Check if bugs table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bugs' AND table_schema = 'public') THEN
        RAISE NOTICE 'Bugs table does not exist!';
    ELSE
        RAISE NOTICE 'Bugs table exists';
    END IF;
    
    -- Check if assignee column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bugs' AND column_name = 'assignee' AND table_schema = 'public') THEN
        RAISE NOTICE 'Assignee column missing!';
    ELSE
        RAISE NOTICE 'Assignee column exists';
    END IF;
    
    -- Check if assignee is UUID type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bugs' AND column_name = 'assignee' AND data_type = 'uuid' AND table_schema = 'public') THEN
        RAISE NOTICE 'Assignee column is UUID type';
    ELSE
        RAISE NOTICE 'Assignee column is not UUID type!';
    END IF;
END $$;

-- Step 6: Test basic operations
-- This should work without errors
SELECT COUNT(*) as bug_count FROM public.bugs;

-- Step 7: Check for any data issues
SELECT 
    COUNT(*) as total_bugs,
    COUNT(assignee) as assigned_bugs,
    COUNT(*) - COUNT(assignee) as unassigned_bugs
FROM public.bugs;
