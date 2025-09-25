-- Immediate fix for bugs assignee field
-- This script handles the transition from TEXT to UUID for the assignee field

-- Step 0: Drop the view that depends on the assignee column
DROP VIEW IF EXISTS bugs_with_assignees;

-- Step 1: Make assignee field nullable temporarily to allow null values
ALTER TABLE public.bugs 
ALTER COLUMN assignee DROP NOT NULL;

-- Step 2: Update the assignee field to allow UUIDs
-- This will allow both text names and UUIDs during transition
ALTER TABLE public.bugs 
ALTER COLUMN assignee TYPE TEXT;

-- Step 3: Set default value for unassigned bugs
UPDATE public.bugs 
SET assignee = 'Unassigned' 
WHERE assignee IS NULL OR assignee = '';

-- Step 4: Create a function to handle assignee validation
CREATE OR REPLACE FUNCTION validate_assignee(assignee_value TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    -- If it's a UUID format, return as is
    IF assignee_value ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RETURN assignee_value;
    -- If it's null or empty, return 'Unassigned'
    ELSIF assignee_value IS NULL OR assignee_value = '' THEN
        RETURN 'Unassigned';
    -- Otherwise return the value as is
    ELSE
        RETURN assignee_value;
    END IF;
END;
$$;

-- Step 5: Create a trigger to validate assignee on insert/update
CREATE OR REPLACE FUNCTION validate_bugs_assignee()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.assignee := validate_assignee(NEW.assignee);
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS validate_bugs_assignee_trigger ON public.bugs;

-- Create the trigger
CREATE TRIGGER validate_bugs_assignee_trigger
    BEFORE INSERT OR UPDATE ON public.bugs
    FOR EACH ROW
    EXECUTE FUNCTION validate_bugs_assignee();

-- Step 6: Update RLS policies to handle the new assignee format
-- This allows users to see bugs assigned to them by UUID or name
DROP POLICY IF EXISTS "Users can view bugs assigned to them" ON public.bugs;

CREATE POLICY "Users can view bugs assigned to them" ON public.bugs
    FOR SELECT USING (
        -- User can see bugs from their own projects
        user_id = auth.uid() OR
        -- User can see bugs assigned to them (by email or UUID)
        assignee = (SELECT email FROM auth.users WHERE id = auth.uid()) OR
        assignee = auth.uid()::text OR
        -- User can see bugs from projects they own
        EXISTS (
            SELECT 1 FROM public.projects 
            WHERE projects.id = bugs.project_id 
            AND projects.user_id = auth.uid()
        )
    );

-- Step 7: Add helpful comments
COMMENT ON COLUMN public.bugs.assignee IS 'Assignee can be: UUID (profile ID), email, name, or "Unassigned"';

-- Step 8: Recreate the bugs_with_assignees view
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

-- Verification query
SELECT 
    COUNT(*) as total_bugs,
    COUNT(CASE WHEN assignee = 'Unassigned' THEN 1 END) as unassigned_bugs,
    COUNT(CASE WHEN assignee ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as uuid_assigned_bugs,
    COUNT(CASE WHEN assignee != 'Unassigned' AND assignee !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 1 END) as name_assigned_bugs
FROM public.bugs;
