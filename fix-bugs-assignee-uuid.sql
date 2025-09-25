-- Fix bugs assignee field to use UUID with proper foreign key constraint
-- This script properly converts the assignee field from TEXT to UUID

-- Step 1: Drop all dependent objects that reference the assignee column
DROP VIEW IF EXISTS bugs_with_assignees CASCADE;
DROP TRIGGER IF EXISTS validate_bugs_assignee_trigger ON public.bugs;
DROP FUNCTION IF EXISTS validate_bugs_assignee();
DROP FUNCTION IF EXISTS validate_assignee(TEXT);

-- Step 2: Add a new UUID column for assignee
ALTER TABLE public.bugs 
ADD COLUMN assignee_uuid UUID;

-- Step 2.5: Disable any triggers that might interfere with the migration
ALTER TABLE public.bugs DISABLE TRIGGER ALL;

-- Step 3: Create a function to find profile ID by name/email
CREATE OR REPLACE FUNCTION find_profile_by_name_or_email(search_text TEXT)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    profile_uuid UUID;
BEGIN
    -- Handle unassigned cases
    IF search_text IS NULL OR search_text = 'Unassigned' OR search_text = '' THEN
        RETURN NULL;
    END IF;
    
    -- If it's already a UUID, return it
    IF search_text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RETURN search_text::UUID;
    END IF;
    
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

-- Step 4: Migrate existing data to UUID format
-- First, set all unassigned bugs to NULL
UPDATE public.bugs 
SET assignee_uuid = NULL
WHERE assignee IS NULL;

UPDATE public.bugs 
SET assignee_uuid = NULL
WHERE assignee = 'Unassigned';

UPDATE public.bugs 
SET assignee_uuid = NULL
WHERE assignee = '';

-- Then, migrate assigned bugs to UUID format
UPDATE public.bugs 
SET assignee_uuid = find_profile_by_name_or_email(assignee)
WHERE assignee IS NOT NULL 
  AND assignee != 'Unassigned' 
  AND assignee != ''
  AND assignee_uuid IS NULL;

-- Step 5: Drop any existing foreign key constraints on assignee
ALTER TABLE public.bugs 
DROP CONSTRAINT IF EXISTS fk_bugs_assignee;

-- Step 6: Drop the old assignee column
ALTER TABLE public.bugs 
DROP COLUMN IF EXISTS assignee;

-- Step 7: Rename the new column to assignee
ALTER TABLE public.bugs 
RENAME COLUMN assignee_uuid TO assignee;

-- Step 7.5: Re-enable triggers
ALTER TABLE public.bugs ENABLE TRIGGER ALL;

-- Step 8: Add foreign key constraint to profiles table
ALTER TABLE public.bugs 
ADD CONSTRAINT fk_bugs_assignee 
FOREIGN KEY (assignee) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Step 9: Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_bugs_assignee ON public.bugs(assignee);

-- Step 10: Recreate the bugs_with_assignees view
CREATE OR REPLACE VIEW bugs_with_assignees AS
SELECT 
    b.id,
    b.title,
    b.description,
    b.severity,
    b.status,
    b.environment,
    b.url,
    b.steps_to_reproduce,
    b.reporter,
    b.assignee as assignee_id,
    COALESCE(p.name, 'Unassigned') as assignee_name,
    COALESCE(p.email, '') as assignee_email,
    COALESCE(p.avatar_url, '') as assignee_avatar_url,
    b.user_id,
    b.project_id,
    b.created_at,
    b.updated_at
FROM public.bugs b
LEFT JOIN public.profiles p ON b.assignee = p.id;

-- Grant select permission on the view
GRANT SELECT ON bugs_with_assignees TO authenticated;

-- Step 11: Update RLS policies to handle UUID assignees
DROP POLICY IF EXISTS "Users can view bugs assigned to them" ON public.bugs;

CREATE POLICY "Users can view bugs assigned to them" ON public.bugs
    FOR SELECT USING (
        -- User can see bugs from their own projects
        user_id = auth.uid() OR
        -- User can see bugs assigned to them (by UUID)
        assignee = auth.uid() OR
        -- User can see bugs from projects they own
        EXISTS (
            SELECT 1 FROM public.projects 
            WHERE projects.id = bugs.project_id 
            AND projects.user_id = auth.uid()
        )
    );

-- Step 12: Clean up the helper function
DROP FUNCTION IF EXISTS find_profile_by_name_or_email(TEXT);

-- Step 13: Add comments for documentation
COMMENT ON COLUMN public.bugs.assignee IS 'Profile ID (UUID) of the team member assigned to this bug. NULL if unassigned.';

-- Verification queries
SELECT 
    COUNT(*) as total_bugs,
    COUNT(assignee) as assigned_bugs,
    COUNT(*) - COUNT(assignee) as unassigned_bugs
FROM public.bugs;

SELECT 
    b.id,
    b.title,
    b.assignee,
    p.name as assignee_name,
    p.email as assignee_email
FROM public.bugs b
LEFT JOIN public.profiles p ON b.assignee = p.id
LIMIT 10;
