-- Empty the bugs table and remove all hardcoded bugs
-- WARNING: This will delete ALL bugs from the table

-- Disable RLS temporarily to allow deletion
ALTER TABLE public.bugs DISABLE ROW LEVEL SECURITY;

-- Delete all bugs from the table
DELETE FROM public.bugs;

-- Re-enable RLS
ALTER TABLE public.bugs ENABLE ROW LEVEL SECURITY;

-- Reset the sequence to start from 1 (optional)
-- This ensures new bugs start with ID 1
ALTER SEQUENCE public.bugs_id_seq RESTART WITH 1;

-- Verify the table is empty
SELECT COUNT(*) as remaining_bugs FROM public.bugs;

-- Optional: Show table structure to confirm it's ready for new data
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'bugs' 
AND table_schema = 'public'
ORDER BY ordinal_position;
