-- Migration: Add function to get assignee display name
-- This function takes a user ID (string) and returns the display name from profiles table

CREATE OR REPLACE FUNCTION get_assignee_display_name(user_id TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Handle null, empty, or 'Unassigned' cases
  IF user_id IS NULL OR user_id = '' OR user_id = 'Unassigned' THEN
    RETURN 'Unassigned';
  END IF;
  
  -- Return the name from profiles table, or 'Unknown User' if not found
  RETURN (
    SELECT COALESCE(name, 'Unknown User')
    FROM profiles
    WHERE id::text = user_id
  );
END;
$$;

-- Add a comment explaining the function
COMMENT ON FUNCTION get_assignee_display_name(TEXT) IS 'Returns the display name for a user ID from the profiles table, or "Unknown User" if not found';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_assignee_display_name(TEXT) TO authenticated;

-- Test the function (optional - can be removed in production)
-- SELECT get_assignee_display_name('some-uuid-here') as test_result;
