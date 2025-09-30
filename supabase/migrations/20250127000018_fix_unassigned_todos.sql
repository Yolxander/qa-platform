-- =============================================================================
-- MIGRATION: Fix unassigned todos by making assignee nullable
-- =============================================================================
-- This migration fixes the issue where unassigned todos fail to create
-- because the assignee field is NOT NULL but the form sends null for unassigned
-- 
-- SOLUTION:
-- 1. Make assignee field nullable to allow unassigned todos
-- 2. Update the view to handle null assignees properly
-- 3. Update the function to handle null assignees
-- =============================================================================

-- Step 1: Make assignee field nullable to allow unassigned todos
ALTER TABLE todos ALTER COLUMN assignee DROP NOT NULL;

-- Step 2: Update the view to handle null assignees properly
DROP VIEW IF EXISTS todos_with_assignee_names;
CREATE OR REPLACE VIEW todos_with_assignee_names AS
SELECT 
  t.*,
  CASE 
    WHEN t.assignee IS NULL THEN 'Unassigned'
    ELSE COALESCE(p.name, 'Unknown User')
  END as assignee_name
FROM todos t
LEFT JOIN profiles p ON t.assignee = p.id;

-- Step 3: Update the get_assignee_display_name function to handle null UUIDs
CREATE OR REPLACE FUNCTION get_assignee_display_name(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Handle null cases
  IF user_id IS NULL THEN
    RETURN 'Unassigned';
  END IF;
  
  -- Return the name from profiles table, or 'Unknown User' if not found
  RETURN (
    SELECT COALESCE(name, 'Unknown User')
    FROM profiles
    WHERE id = user_id
  );
END;
$$;

-- Step 4: Grant permissions on the updated view
GRANT SELECT ON todos_with_assignee_names TO authenticated;

-- Step 5: Add comment explaining the change
COMMENT ON COLUMN todos.assignee IS 'UUID reference to auth.users(id) - nullable to allow unassigned todos';
COMMENT ON FUNCTION get_assignee_display_name(UUID) IS 'Returns the display name for a user ID from the profiles table, or "Unassigned" if null, or "Unknown User" if not found';
COMMENT ON VIEW todos_with_assignee_names IS 'View that includes todos with resolved assignee names, showing "Unassigned" for null assignees';
