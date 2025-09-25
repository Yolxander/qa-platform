-- Create initial database schema for Smasher Light application
-- This migration creates all necessary tables, indexes, and RLS policies

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create teams table
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create team_members table (junction table)
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Create team_invitations table
CREATE TABLE IF NOT EXISTS team_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    invited_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bugs table
CREATE TABLE IF NOT EXISTS bugs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Open', 'In Progress', 'Closed', 'Ready for QA')),
    environment VARCHAR(20) NOT NULL CHECK (environment IN ('Prod', 'Stage', 'Dev')),
    reporter VARCHAR(255) NOT NULL,
    assignee VARCHAR(255),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create todos table
CREATE TABLE IF NOT EXISTS todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    issue_link TEXT,
    status VARCHAR(20) NOT NULL CHECK (status IN ('OPEN', 'IN_PROGRESS', 'DONE', 'READY_FOR_QA')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    environment VARCHAR(20) NOT NULL CHECK (environment IN ('Prod', 'Stage', 'Dev')),
    assignee VARCHAR(255) NOT NULL,
    quick_action TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bug_images table for storing bug attachments
CREATE TABLE IF NOT EXISTS bug_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_name VARCHAR(255),
    image_size INTEGER,
    uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at);

CREATE INDEX IF NOT EXISTS idx_teams_project_id ON teams(project_id);
CREATE INDEX IF NOT EXISTS idx_teams_created_by ON teams(created_by);

CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);

CREATE INDEX IF NOT EXISTS idx_team_invitations_email ON team_invitations(email);
CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON team_invitations(team_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_status ON team_invitations(status);

CREATE INDEX IF NOT EXISTS idx_bugs_user_id ON bugs(user_id);
CREATE INDEX IF NOT EXISTS idx_bugs_project_id ON bugs(project_id);
CREATE INDEX IF NOT EXISTS idx_bugs_status ON bugs(status);
CREATE INDEX IF NOT EXISTS idx_bugs_severity ON bugs(severity);
CREATE INDEX IF NOT EXISTS idx_bugs_created_at ON bugs(created_at);

CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON todos(project_id);
CREATE INDEX IF NOT EXISTS idx_todos_status ON todos(status);
CREATE INDEX IF NOT EXISTS idx_todos_assignee ON todos(assignee);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);

CREATE INDEX IF NOT EXISTS idx_bug_images_bug_id ON bug_images(bug_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_invitations_updated_at BEFORE UPDATE ON team_invitations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bugs_updated_at BEFORE UPDATE ON bugs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON todos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to get team members
CREATE OR REPLACE FUNCTION get_team_members(team_uuid UUID)
RETURNS TABLE (
    member_id UUID,
    member_name TEXT,
    member_email TEXT,
    member_avatar_url TEXT,
    role VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.user_id as member_id,
        COALESCE(au.raw_user_meta_data->>'name', au.email) as member_name,
        au.email as member_email,
        au.raw_user_meta_data->>'avatar_url' as member_avatar_url,
        tm.role,
        tm.joined_at
    FROM team_members tm
    JOIN auth.users au ON tm.user_id = au.id
    WHERE tm.team_id = team_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get member projects (for invited projects)
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

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for projects
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own projects" ON projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects" ON projects
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects" ON projects
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for teams
CREATE POLICY "Users can view teams they created or are members of" ON teams
    FOR SELECT USING (
        auth.uid() = created_by OR 
        EXISTS (
            SELECT 1 FROM team_members tm 
            WHERE tm.team_id = teams.id 
            AND tm.user_id = auth.uid()
        )
    );

CREATE POLICY "Project owners can create teams" ON teams
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        auth.uid() IN (
            SELECT user_id FROM projects WHERE id = project_id
        )
    );

CREATE POLICY "Team owners can update teams" ON teams
    FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Team owners can delete teams" ON teams
    FOR DELETE USING (auth.uid() = created_by);

-- Create RLS policies for team_members
CREATE POLICY "Users can view team members if they're in the team or created it" ON team_members
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

CREATE POLICY "Team owners can add members" ON team_members
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for team_invitations
CREATE POLICY "Users can view their own invitations" ON team_invitations
    FOR SELECT USING (email = auth.jwt() ->> 'email');

CREATE POLICY "Team owners can create invitations" ON team_invitations
    FOR INSERT WITH CHECK (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

CREATE POLICY "Team owners can update invitations" ON team_invitations
    FOR UPDATE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Create RLS policies for bugs
CREATE POLICY "Users can view all bugs" ON bugs
    FOR SELECT USING (true);

CREATE POLICY "Users can create bugs" ON bugs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bugs" ON bugs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bugs" ON bugs
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for todos
CREATE POLICY "Users can view all todos" ON todos
    FOR SELECT USING (true);

CREATE POLICY "Users can create todos" ON todos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own todos" ON todos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own todos" ON todos
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for bug_images
CREATE POLICY "Users can view bug images" ON bug_images
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM bugs WHERE id = bug_id
        )
    );

CREATE POLICY "Users can upload bug images" ON bug_images
    FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can delete their own bug images" ON bug_images
    FOR DELETE USING (auth.uid() = uploaded_by);

-- Create function to handle project assignment for bugs and todos
CREATE OR REPLACE FUNCTION assign_to_current_project()
RETURNS TRIGGER AS $$
BEGIN
    -- If project_id is not provided, try to get it from the user's current project
    -- This is a placeholder - you might want to implement project selection logic
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic project assignment (optional)
-- You can uncomment these if you want automatic project assignment
-- CREATE TRIGGER assign_bug_to_project BEFORE INSERT ON bugs
--     FOR EACH ROW EXECUTE FUNCTION assign_to_current_project();

-- CREATE TRIGGER assign_todo_to_project BEFORE INSERT ON todos
--     FOR EACH ROW EXECUTE FUNCTION assign_to_current_project();

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_team_invitation(TEXT) TO authenticated;
