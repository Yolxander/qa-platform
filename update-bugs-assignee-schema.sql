-- Update bugs table assignee field to store profile ID (UUID) instead of name
-- This script migrates the assignee field from TEXT to UUID and makes it nullable

-- Step 1: Add a new temporary column for the profile ID
ALTER TABLE public.bugs 
ADD COLUMN assignee_id UUID;

-- Step 2: Create a function to find profile ID by name/email
-- This will help migrate existing data if needed
CREATE OR REPLACE FUNCTION find_profile_by_name_or_email(search_text TEXT)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    profile_uuid UUID;
BEGIN
    -- Try to find by exact name match first
    SELECT id INTO profile_uuid 
    FROM public.profiles 
    WHERE name = search_text;
    
    -- If not found by name, try by email
    IF profile_uuid IS NULL THEN
        SELECT id INTO profile_uuid 
        FROM public.profiles 
        WHERE email = search_text;
    END IF;
    
    -- If still not found, try partial name match
    IF profile_uuid IS NULL THEN
        SELECT id INTO profile_uuid 
        FROM public.profiles 
        WHERE name ILIKE '%' || search_text || '%'
        LIMIT 1;
    END IF;
    
    RETURN profile_uuid;
END;
$$;

-- Step 3: Migrate existing data (optional - only if you have existing assignee data to migrate)
-- Uncomment the following lines if you want to migrate existing assignee names to profile IDs
-- UPDATE public.bugs 
-- SET assignee_id = find_profile_by_name_or_email(assignee)
-- WHERE assignee IS NOT NULL 
--   AND assignee != 'Unassigned' 
--   AND assignee != '';

-- Step 4: Drop the old assignee column
ALTER TABLE public.bugs 
DROP COLUMN IF EXISTS assignee;

-- Step 5: Rename the new column to assignee
ALTER TABLE public.bugs 
RENAME COLUMN assignee_id TO assignee;

-- Step 6: Add foreign key constraint to profiles table
-- Note: This will only work if assignee_id was properly populated with UUIDs
ALTER TABLE public.bugs 
ADD CONSTRAINT fk_bugs_assignee 
FOREIGN KEY (assignee) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Step 7: Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_bugs_assignee ON public.bugs(assignee);

-- Step 8: Update RLS policies if they exist
-- Note: You may need to update existing RLS policies that reference the old assignee field

-- Step 9: Clean up the helper function
DROP FUNCTION IF EXISTS find_profile_by_name_or_email(TEXT);

-- Step 10: Add comments for documentation
COMMENT ON COLUMN public.bugs.assignee IS 'Profile ID of the team member assigned to this bug. NULL if unassigned.';

-- Verification queries (run these to check the migration)
-- SELECT 
--     COUNT(*) as total_bugs,
--     COUNT(assignee) as assigned_bugs,
--     COUNT(*) - COUNT(assignee) as unassigned_bugs
-- FROM public.bugs;

-- SELECT 
--     b.id,
--     b.title,
--     b.assignee,
--     p.name as assignee_name,
--     p.email as assignee_email
-- FROM public.bugs b
-- LEFT JOIN public.profiles p ON b.assignee = p.id
-- LIMIT 10;
