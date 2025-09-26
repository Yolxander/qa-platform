-- Migration: Create a view for todos with assignee names
-- This view joins todos with profiles to get assignee display names

CREATE OR REPLACE VIEW todos_with_assignee_names AS
SELECT 
  t.*,
  CASE 
    WHEN t.assignee IS NULL OR t.assignee = '' THEN 'Unassigned'
    WHEN t.assignee = 'Unassigned' THEN 'Unassigned'
    ELSE COALESCE(p.name, 'Unknown User')
  END as assignee_name
FROM todos t
LEFT JOIN profiles p ON t.assignee::uuid = p.id;

-- Add a comment explaining the view
COMMENT ON VIEW todos_with_assignee_names IS 'View that includes todos with resolved assignee names instead of UUIDs';

-- Grant select permission to authenticated users
GRANT SELECT ON todos_with_assignee_names TO authenticated;

-- Create RLS policy for the view (inherits from base todos table)
-- The view will respect the same RLS policies as the todos table
