-- Fix RLS infinite recursion and add missing functions
-- This migration safely fixes the issues without losing existing data

-- Drop the problematic RLS policies that cause infinite recursion
DROP POLICY IF EXISTS "Users can view teams in their projects" ON teams;
DROP POLICY IF EXISTS "Users can view teams they created or are members of" ON teams;
DROP POLICY IF EXISTS "Users can view team members in their teams" ON team_members;
DROP POLICY IF EXISTS "Users can view team members if they're in the team or created it" ON team_members;

-- Create improved RLS policies that avoid circular dependencies
-- For teams: Users can view teams they created or teams they're members of
CREATE POLICY "Users can view teams they created or are members of" ON teams
    FOR SELECT USING (
        auth.uid() = created_by OR 
        EXISTS (
            SELECT 1 FROM team_members tm 
            WHERE tm.team_id = teams.id 
            AND tm.user_id = auth.uid()
        )
    );

-- For team_members: Users can view team members if they're in the team or created it
CREATE POLICY "Users can view team members if they're in the team or created it" ON team_members
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

-- Create the missing get_member_projects function
CREATE OR REPLACE FUNCTION get_member_projects(user_profile_id UUID)
RETURNS TABLE (
    project_id UUID,
    project_name VARCHAR(255),
    project_description TEXT,
    project_owner_id UUID,
    project_created_at TIMESTAMP WITH TIME ZONE,
    team_id UUID,
    team_name VARCHAR(255),
    role VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as project_id,
        p.name as project_name,
        p.description as project_description,
        p.user_id as project_owner_id,
        p.created_at as project_created_at,
        t.id as team_id,
        t.name as team_name,
        tm.role,
        tm.joined_at
    FROM projects p
    JOIN teams t ON t.project_id = p.id
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = user_profile_id
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to accept team invitations
CREATE OR REPLACE FUNCTION accept_team_invitation(invitation_token TEXT)
RETURNS JSON AS $$
DECLARE
    invitation_record RECORD;
    user_id UUID;
BEGIN
    -- Get the current user ID
    user_id := auth.uid();
    
    -- Find the invitation by token
    SELECT * INTO invitation_record
    FROM team_invitations
    WHERE token = invitation_token
    AND status = 'pending'
    AND expires_at > NOW();
    
    -- Check if invitation exists and is valid
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Invalid or expired invitation');
    END IF;
    
    -- Check if user email matches invitation email
    IF (SELECT email FROM auth.users WHERE id = user_id) != invitation_record.email THEN
        RETURN json_build_object('success', false, 'message', 'Email does not match invitation');
    END IF;
    
    -- Add user to team
    INSERT INTO team_members (team_id, user_id, role)
    VALUES (invitation_record.team_id, user_id, COALESCE(invitation_record.role, 'member'))
    ON CONFLICT (team_id, user_id) DO NOTHING;
    
    -- Update invitation status
    UPDATE team_invitations
    SET status = 'accepted', updated_at = NOW()
    WHERE token = invitation_token;
    
    RETURN json_build_object('success', true, 'message', 'Successfully joined team');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error accepting invitation: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_team_invitation(TEXT) TO authenticated;
