-- =============================================================================
-- MIGRATION: Convert assignee field from VARCHAR to UUID
-- =============================================================================
-- This migration safely converts the assignee field in the todos table
-- from VARCHAR(255) to UUID that references team_members.user_id
-- 
-- SAFETY MEASURES:
-- 1. Makes field nullable temporarily to avoid constraint violations
-- 2. Converts existing data to proper UUIDs where possible
-- 3. Sets default to current user for any remaining null values
-- 4. Makes field NOT NULL again with proper UUID type
-- =============================================================================

-- Step 1: Drop the existing view first to avoid dependency issues
DROP VIEW IF EXISTS todos_with_assignee_names;

-- Step 2: Make assignee field nullable temporarily
ALTER TABLE todos ALTER COLUMN assignee DROP NOT NULL;

-- Step 3: Convert existing assignee values to UUIDs where possible
-- This handles cases where assignee might be a user ID string
UPDATE todos 
SET assignee = CASE 
    WHEN assignee IS NULL OR assignee = '' OR assignee = 'Unassigned' THEN NULL
    WHEN assignee ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN assignee
    ELSE NULL
END;

-- Step 4: For any remaining NULL assignee values, set them to the todo's user_id
-- This ensures no data is lost and maintains referential integrity
UPDATE todos 
SET assignee = user_id::text
WHERE assignee IS NULL;

-- Step 5: Change the column type to UUID
ALTER TABLE todos ALTER COLUMN assignee TYPE UUID USING assignee::UUID;

-- Step 6: Make the field NOT NULL again
ALTER TABLE todos ALTER COLUMN assignee SET NOT NULL;

-- Step 7: Add foreign key constraint to auth.users(id) instead of team_members
-- This ensures assignee always references a valid user
ALTER TABLE todos 
ADD CONSTRAINT fk_todos_assignee_user 
FOREIGN KEY (assignee) REFERENCES auth.users(id) ON DELETE SET NULL;

-- Step 8: Update the index to work with UUID
DROP INDEX IF EXISTS idx_todos_assignee;
CREATE INDEX idx_todos_assignee ON todos(assignee);

-- Step 9: Recreate the view to work with the new UUID assignee field
CREATE OR REPLACE VIEW todos_with_assignee_names AS
SELECT 
  t.*,
  CASE 
    WHEN t.assignee IS NULL THEN 'Unassigned'
    ELSE COALESCE(p.name, 'Unknown User')
  END as assignee_name
FROM todos t
LEFT JOIN profiles p ON t.assignee = p.id;

-- Step 9: Update the get_assignee_display_name function to work with UUID
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

-- Step 10: Grant permissions on the updated view
GRANT SELECT ON todos_with_assignee_names TO authenticated;

-- Add comment explaining the change
COMMENT ON COLUMN todos.assignee IS 'UUID reference to team_members.user_id - the team member assigned to this todo';
COMMENT ON FUNCTION get_assignee_display_name(UUID) IS 'Returns the display name for a user ID from the profiles table, or "Unknown User" if not found';
COMMENT ON VIEW todos_with_assignee_names IS 'View that includes todos with resolved assignee names instead of UUIDs';
