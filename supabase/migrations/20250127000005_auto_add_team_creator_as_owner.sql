-- Auto-add team creator as team member with owner role
-- This ensures the team creator is automatically added as a team member

-- Create or replace function to create teams and auto-add creator as owner
CREATE OR REPLACE FUNCTION create_team_with_owner(
    team_name VARCHAR(255),
    team_description TEXT,
    project_id_param UUID
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    new_team_id UUID;
    project_exists BOOLEAN;
    user_is_project_owner BOOLEAN;
BEGIN
    -- Get the current user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Check if project exists
    SELECT EXISTS(SELECT 1 FROM projects WHERE id = project_id_param) INTO project_exists;
    IF NOT project_exists THEN
        RETURN json_build_object('success', false, 'message', 'Project does not exist');
    END IF;
    
    -- Check if user is the owner of the project
    SELECT EXISTS(
        SELECT 1 FROM projects 
        WHERE id = project_id_param 
        AND user_id = current_user_id
    ) INTO user_is_project_owner;
    
    IF NOT user_is_project_owner THEN
        RETURN json_build_object('success', false, 'message', 'Access denied: You are not the owner of this project');
    END IF;
    
    -- Create the team
    INSERT INTO teams (name, description, project_id, created_by)
    VALUES (team_name, team_description, project_id_param, current_user_id)
    RETURNING id INTO new_team_id;
    
    -- Automatically add the creator as a team member with 'owner' role
    INSERT INTO team_members (team_id, user_id, role)
    VALUES (new_team_id, current_user_id, 'owner')
    ON CONFLICT (team_id, user_id) DO NOTHING;
    
    RETURN json_build_object(
        'success', true, 
        'message', 'Team created successfully',
        'team_id', new_team_id
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating team: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing teams to add their creators as team members if not already present
-- This is a one-time fix for existing teams
INSERT INTO team_members (team_id, user_id, role)
SELECT t.id, t.created_by, 'owner'
FROM teams t
WHERE NOT EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.team_id = t.id AND tm.user_id = t.created_by
)
ON CONFLICT (team_id, user_id) DO NOTHING;
