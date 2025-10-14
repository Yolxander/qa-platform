-- Create comprehensive dashboard function that gets all user projects and data
-- This function will replace the need for multiple queries and provide all dashboard data

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_user_dashboard_data(UUID);

-- Create comprehensive dashboard function
CREATE OR REPLACE FUNCTION get_user_dashboard_data(user_profile_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    owned_projects JSON;
    member_projects JSON;
    all_project_ids UUID[];
    bugs_data JSON;
    todos_data JSON;
    metrics JSON;
    chart_data JSON;
    table_data JSON;
BEGIN
    -- Get owned projects
    SELECT json_agg(
        json_build_object(
            'id', p.id,
            'name', p.name,
            'description', p.description,
            'user_id', p.user_id,
            'created_at', p.created_at,
            'updated_at', p.updated_at,
            'type', 'owned'
        )
    ) INTO owned_projects
    FROM projects p
    WHERE p.user_id = user_profile_id;

    -- Get member projects (projects where user is a team member)
    SELECT json_agg(
        json_build_object(
            'id', p.id,
            'name', p.name,
            'description', p.description,
            'user_id', p.user_id,
            'created_at', p.created_at,
            'updated_at', p.updated_at,
            'type', 'member',
            'team_id', t.id,
            'team_name', t.name,
            'role', tm.role,
            'joined_at', tm.joined_at
        )
    ) INTO member_projects
    FROM projects p
    JOIN teams t ON t.project_id = p.id
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = user_profile_id;

    -- Combine all project IDs
    SELECT array_agg(DISTINCT project_id) INTO all_project_ids
    FROM (
        SELECT id as project_id FROM projects WHERE user_id = user_profile_id
        UNION
        SELECT p.id as project_id 
        FROM projects p
        JOIN teams t ON t.project_id = p.id
        JOIN team_members tm ON tm.team_id = t.id
        WHERE tm.user_id = user_profile_id
    ) combined_projects;

    -- Get bugs data from all accessible projects
    SELECT json_agg(
        json_build_object(
            'id', b.id,
            'title', b.title,
            'description', b.description,
            'severity', b.severity,
            'status', b.status,
            'environment', b.environment,
            'reporter', b.reporter,
            'assignee', b.assignee,
            'steps_to_reproduce', b.steps_to_reproduce,
            'url', b.url,
            'user_id', b.user_id,
            'project_id', b.project_id,
            'created_at', b.created_at,
            'updated_at', b.updated_at,
            'project_name', p.name
        )
    ) INTO bugs_data
    FROM bugs b
    JOIN projects p ON p.id = b.project_id
    WHERE b.project_id = ANY(all_project_ids);

    -- Get todos data from all accessible projects
    SELECT json_agg(
        json_build_object(
            'id', t.id,
            'title', t.title,
            'issue_link', t.issue_link,
            'status', t.status,
            'severity', t.severity,
            'due_date', t.due_date,
            'environment', t.environment,
            'assignee', t.assignee,
            'quick_action', t.quick_action,
            'user_id', t.user_id,
            'project_id', t.project_id,
            'created_at', t.created_at,
            'updated_at', t.updated_at,
            'project_name', p.name
        )
    ) INTO todos_data
    FROM todos t
    JOIN projects p ON p.id = t.project_id
    WHERE t.project_id = ANY(all_project_ids);

    -- Calculate metrics
    SELECT json_build_object(
        'total_projects', COALESCE(array_length(all_project_ids, 1), 0),
        'owned_projects_count', COALESCE(json_array_length(owned_projects), 0),
        'member_projects_count', COALESCE(json_array_length(member_projects), 0),
        'total_bugs', COALESCE(json_array_length(bugs_data), 0),
        'open_bugs', COALESCE(
            (SELECT COUNT(*) FROM json_array_elements(bugs_data) 
             WHERE value->>'status' = 'Open'), 0
        ),
        'ready_for_qa_bugs', COALESCE(
            (SELECT COUNT(*) FROM json_array_elements(bugs_data) 
             WHERE value->>'status' = 'Ready for QA'), 0
        ),
        'critical_bugs', COALESCE(
            (SELECT COUNT(*) FROM json_array_elements(bugs_data) 
             WHERE value->>'status' = 'Open' AND value->>'severity' = 'CRITICAL'), 0
        ),
        'total_todos', COALESCE(json_array_length(todos_data), 0),
        'open_todos', COALESCE(
            (SELECT COUNT(*) FROM json_array_elements(todos_data) 
             WHERE value->>'status' = 'OPEN'), 0
        ),
        'in_progress_todos', COALESCE(
            (SELECT COUNT(*) FROM json_array_elements(todos_data) 
             WHERE value->>'status' = 'IN_PROGRESS'), 0
        ),
        'ready_for_qa_todos', COALESCE(
            (SELECT COUNT(*) FROM json_array_elements(todos_data) 
             WHERE value->>'status' = 'READY_FOR_QA'), 0
        ),
        'done_todos', COALESCE(
            (SELECT COUNT(*) FROM json_array_elements(todos_data) 
             WHERE value->>'status' = 'DONE'), 0
        )
    ) INTO metrics;

    -- Generate chart data (last 14 days) - combine bugs and todos for All Projects mode
    WITH chart_data_raw AS (
        SELECT 
            date_trunc('day', (value->>'created_at')::timestamp) as date,
            COUNT(*) as opened,
            COUNT(CASE WHEN (value->>'status') IN ('Closed', 'DONE') THEN 1 END) as closed
        FROM (
            SELECT value FROM json_array_elements(bugs_data)
            UNION ALL
            SELECT value FROM json_array_elements(todos_data)
        ) combined_items
        WHERE (value->>'created_at')::timestamp >= NOW() - INTERVAL '14 days'
        GROUP BY date_trunc('day', (value->>'created_at')::timestamp)
    ),
    -- Generate all dates for the last 14 days to ensure we have data points
    date_series AS (
        SELECT generate_series(
            date_trunc('day', NOW() - INTERVAL '13 days'),
            date_trunc('day', NOW()),
            INTERVAL '1 day'
        )::date as date
    )
    SELECT json_agg(
        json_build_object(
            'date', ds.date::text,
            'opened', COALESCE(cdr.opened, 0),
            'closed', COALESCE(cdr.closed, 0)
        )
        ORDER BY ds.date
    ) INTO chart_data
    FROM date_series ds
    LEFT JOIN chart_data_raw cdr ON ds.date = cdr.date;

    -- Generate table data (combining bugs and todos)
    WITH combined_data AS (
        SELECT 
            (value->>'id')::integer as id,
            value->>'title' as header,
            value->>'severity' as type,
            value->>'status' as status,
            value->>'assignee' as target,
            value->>'created_at' as due_date,
            value->>'reporter' as reviewer,
            'bug' as source,
            value->>'project_name' as project
        FROM json_array_elements(bugs_data)
        UNION ALL
        SELECT 
            (value->>'id')::integer + 10000 as id, -- Offset to avoid conflicts
            value->>'title' as header,
            value->>'severity' as type,
            value->>'status' as status,
            value->>'assignee' as target,
            value->>'due_date' as due_date,
            'Assign reviewer' as reviewer,
            'todo' as source,
            value->>'project_name' as project
        FROM json_array_elements(todos_data)
    )
    SELECT json_agg(
        json_build_object(
            'id', id,
            'header', header,
            'type', type,
            'status', status,
            'target', target,
            'due_date', due_date,
            'reviewer', reviewer,
            'source', source,
            'project', project
        )
    ) INTO table_data
    FROM combined_data;

    -- Build final result
    result := json_build_object(
        'projects', json_build_object(
            'owned', COALESCE(owned_projects, '[]'::json),
            'member', COALESCE(member_projects, '[]'::json),
            'all_ids', all_project_ids
        ),
        'bugs', COALESCE(bugs_data, '[]'::json),
        'todos', COALESCE(todos_data, '[]'::json),
        'metrics', metrics,
        'chart_data', COALESCE(chart_data, '[]'::json),
        'table_data', COALESCE(table_data, '[]'::json),
        'accessible_project_count', COALESCE(array_length(all_project_ids, 1), 0)
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_dashboard_data(UUID) TO authenticated;
