-- Simple fix for bugs assignee field - convert to UUID
-- This script drops the view, removes the assignee field, and adds it back as UUID

-- Step 1: Drop the view that depends on the assignee column
DROP VIEW IF EXISTS bugs_with_assignees CASCADE;

-- Step 2: Drop any existing foreign key constraints on assignee
ALTER TABLE public.bugs 
DROP CONSTRAINT IF EXISTS fk_bugs_assignee;

-- Step 3: Drop the old assignee column completely
ALTER TABLE public.bugs 
DROP COLUMN IF EXISTS assignee;

-- Step 4: Add the new assignee column as UUID
ALTER TABLE public.bugs 
ADD COLUMN assignee UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Step 5: Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_bugs_assignee ON public.bugs(assignee);

-- Step 6: Recreate the bugs_with_assignees view
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

-- Step 7: Update RLS policies to handle UUID assignees
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

-- Step 8: Add comments for documentation
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
