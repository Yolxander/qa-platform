-- Add project_id column to team_invitations table
-- This migration adds the missing project_id column that the AuthContext expects

ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_team_invitations_project_id ON team_invitations(project_id);

-- Update the create_team_invitation function to include project_id
CREATE OR REPLACE FUNCTION create_team_invitation(
    invite_email TEXT,
    invite_name TEXT,
    project_id_param UUID,
    team_id_param UUID,
    invite_role TEXT DEFAULT 'member'
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    team_exists BOOLEAN;
    project_exists BOOLEAN;
    user_is_team_owner BOOLEAN;
    invitation_exists BOOLEAN;
    invitation_id UUID;
    invitation_token TEXT;
BEGIN
    -- Get the current user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Check if team exists
    SELECT EXISTS(SELECT 1 FROM teams WHERE id = team_id_param) INTO team_exists;
    IF NOT team_exists THEN
        RETURN json_build_object('success', false, 'message', 'Team does not exist');
    END IF;
    
    -- Check if project exists
    SELECT EXISTS(SELECT 1 FROM projects WHERE id = project_id_param) INTO project_exists;
    IF NOT project_exists THEN
        RETURN json_build_object('success', false, 'message', 'Project does not exist');
    END IF;
    
    -- Check if user is the owner of the team
    SELECT EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND created_by = current_user_id
    ) INTO user_is_team_owner;
    
    IF NOT user_is_team_owner THEN
        RETURN json_build_object('success', false, 'message', 'Access denied: You are not the owner of this team');
    END IF;
    
    -- Check if team belongs to the specified project
    IF NOT EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND project_id = project_id_param
    ) THEN
        RETURN json_build_object('success', false, 'message', 'Team does not belong to the specified project');
    END IF;
    
    -- Check if invitation already exists for this email and team
    SELECT EXISTS(
        SELECT 1 FROM team_invitations 
        WHERE email = invite_email 
        AND team_id = team_id_param 
        AND status = 'pending'
    ) INTO invitation_exists;
    
    IF invitation_exists THEN
        RETURN json_build_object('success', false, 'message', 'An invitation for this email already exists for this team');
    END IF;
    
    -- Generate a unique token for the invitation
    invitation_token := encode(gen_random_bytes(32), 'base64');
    
    -- Create the invitation with project_id
    INSERT INTO team_invitations (
        team_id,
        project_id,
        email,
        invited_by,
        status,
        expires_at,
        role
    ) VALUES (
        team_id_param,
        project_id_param,
        invite_email,
        current_user_id,
        'pending',
        NOW() + INTERVAL '7 days', -- Invitation expires in 7 days
        invite_role
    ) RETURNING id INTO invitation_id;
    
    -- Return success response
    RETURN json_build_object(
        'success', true, 
        'message', 'Invitation created successfully',
        'invitation_id', invitation_id,
        'token', invitation_token
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating invitation: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
