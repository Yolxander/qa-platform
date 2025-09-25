-- Function to get bugs with assignee names instead of UUIDs
-- This function joins the bugs table with profiles to return assignee names

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_bugs_with_assignee_names(UUID, UUID);
DROP FUNCTION IF EXISTS get_bug_with_assignee(INTEGER);
DROP FUNCTION IF EXISTS get_bug_assignee_info(INTEGER);

CREATE OR REPLACE FUNCTION get_bugs_with_assignee_names(
    project_uuid UUID DEFAULT NULL,
    user_profile_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    description TEXT,
    severity TEXT,
    status TEXT,
    environment TEXT,
    url TEXT,
    steps_to_reproduce TEXT,
    reporter TEXT,
    assignee_id UUID,
    assignee_name TEXT,
    assignee_email TEXT,
    user_id UUID,
    project_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
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
        b.user_id,
        b.project_id,
        b.created_at,
        b.updated_at
    FROM public.bugs b
    LEFT JOIN public.profiles p ON b.assignee = p.id
    WHERE 
        (project_uuid IS NULL OR b.project_id = project_uuid)
        AND (user_profile_id IS NULL OR b.user_id = user_profile_id)
    ORDER BY b.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_bugs_with_assignee_names(UUID, UUID) TO authenticated;

-- Drop existing policy if it exists and create new one
DROP POLICY IF EXISTS "Users can get bugs with assignee names" ON public.bugs;

-- Create RLS policy to allow users to access bugs they have permission to see
CREATE POLICY "Users can get bugs with assignee names" ON public.bugs
    FOR SELECT USING (
        -- User can see bugs from their own projects
        project_id IN (
            SELECT id FROM public.projects WHERE user_id = auth.uid()
        )
        OR
        -- User can see bugs from projects they are a member of
        project_id IN (
            SELECT DISTINCT t.project_id 
            FROM public.teams t
            INNER JOIN public.team_members tm ON t.id = tm.team_id
            WHERE tm.profile_id = auth.uid()
        )
    );

-- Alternative function for getting a single bug with assignee info
CREATE OR REPLACE FUNCTION get_bug_with_assignee(bug_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    description TEXT,
    severity TEXT,
    status TEXT,
    environment TEXT,
    url TEXT,
    steps_to_reproduce TEXT,
    reporter TEXT,
    assignee_id UUID,
    assignee_name TEXT,
    assignee_email TEXT,
    assignee_avatar_url TEXT,
    user_id UUID,
    project_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
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
    LEFT JOIN public.profiles p ON b.assignee = p.id
    WHERE b.id = bug_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_bug_with_assignee(INTEGER) TO authenticated;

-- Function to get assignee information for a specific bug
CREATE OR REPLACE FUNCTION get_bug_assignee_info(bug_id INTEGER)
RETURNS TABLE (
    assignee_id UUID,
    assignee_name TEXT,
    assignee_email TEXT,
    assignee_avatar_url TEXT,
    assignee_role TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.assignee as assignee_id,
        COALESCE(p.name, 'Unassigned') as assignee_name,
        COALESCE(p.email, '') as assignee_email,
        COALESCE(p.avatar_url, '') as assignee_avatar_url,
        COALESCE(tm.role, '') as assignee_role
    FROM public.bugs b
    LEFT JOIN public.profiles p ON b.assignee = p.id
    LEFT JOIN public.team_members tm ON p.id = tm.profile_id
    LEFT JOIN public.teams t ON tm.team_id = t.id AND t.project_id = b.project_id
    WHERE b.id = bug_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_bug_assignee_info(INTEGER) TO authenticated;

-- Drop existing view if it exists
DROP VIEW IF EXISTS bugs_with_assignees;

-- Create a view for easier access to bugs with assignee names
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

-- Example usage:
-- 
-- Get all bugs for a specific project with assignee names:
-- SELECT * FROM get_bugs_with_assignee_names('project-uuid');
-- 
-- Get all bugs for the current user with assignee names:
-- SELECT * FROM get_bugs_with_assignee_names(NULL, auth.uid());
-- 
-- Get a specific bug with assignee info:
-- SELECT * FROM get_bug_with_assignee(bug_id);
-- 
-- Get assignee info for a specific bug:
-- SELECT * FROM get_bug_assignee_info(bug_id);
-- 
-- Use the view for simple queries:
-- SELECT * FROM bugs_with_assignees WHERE project_id = 'project-uuid';
