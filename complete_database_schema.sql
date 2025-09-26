-- =============================================================================
-- COMPLETE DATABASE SCHEMA FOR SMASHER LIGHT APPLICATION
-- =============================================================================
-- This script consolidates all migrations, functions, and policies from the
-- Supabase instance into a single comprehensive schema file.
-- 
-- USAGE:
-- 1. Connect to your new Supabase instance
-- 2. Run this script to set up the complete database schema
-- 3. Update your application's environment variables to point to the new instance
--
-- Created: 2025-01-27
-- Version: 1.0
-- =============================================================================

-- =============================================================================
-- 1. ENABLE EXTENSIONS
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 2. CREATE TABLES
-- =============================================================================

-- Create profiles table (user profiles)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    invited_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    role VARCHAR(50) DEFAULT 'member',
    token TEXT UNIQUE,
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
    steps_to_reproduce TEXT,
    url TEXT,
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
    url TEXT NOT NULL,
    name VARCHAR(255),
    size INTEGER,
    path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bug_comments table for storing comments on bugs
CREATE TABLE IF NOT EXISTS bug_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
    author VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    attachments TEXT[], -- Array of attachment filenames
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- 3. CREATE INDEXES
-- =============================================================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_name ON profiles(name);

-- Projects indexes
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at);

-- Teams indexes
CREATE INDEX IF NOT EXISTS idx_teams_project_id ON teams(project_id);
CREATE INDEX IF NOT EXISTS idx_teams_created_by ON teams(created_by);

-- Team members indexes
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);

-- Team invitations indexes
CREATE INDEX IF NOT EXISTS idx_team_invitations_email ON team_invitations(email);
CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON team_invitations(team_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_status ON team_invitations(status);
CREATE INDEX IF NOT EXISTS idx_team_invitations_project_id ON team_invitations(project_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_token ON team_invitations(token);

-- Bugs indexes
CREATE INDEX IF NOT EXISTS idx_bugs_user_id ON bugs(user_id);
CREATE INDEX IF NOT EXISTS idx_bugs_project_id ON bugs(project_id);
CREATE INDEX IF NOT EXISTS idx_bugs_status ON bugs(status);
CREATE INDEX IF NOT EXISTS idx_bugs_severity ON bugs(severity);
CREATE INDEX IF NOT EXISTS idx_bugs_created_at ON bugs(created_at);

-- Todos indexes
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON todos(project_id);
CREATE INDEX IF NOT EXISTS idx_todos_status ON todos(status);
CREATE INDEX IF NOT EXISTS idx_todos_assignee ON todos(assignee);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);

-- Bug images indexes
CREATE INDEX IF NOT EXISTS idx_bug_images_bug_id ON bug_images(bug_id);
CREATE INDEX IF NOT EXISTS idx_bug_images_created_at ON bug_images(created_at);

-- Bug comments indexes
CREATE INDEX IF NOT EXISTS idx_bug_comments_bug_id ON bug_comments(bug_id);
CREATE INDEX IF NOT EXISTS idx_bug_comments_created_at ON bug_comments(created_at);

-- =============================================================================
-- 4. CREATE FUNCTIONS
-- =============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to get team members
CREATE OR REPLACE FUNCTION get_team_members(team_uuid UUID)
RETURNS TABLE (
    member_id UUID,
    member_name TEXT,
    member_email TEXT,
    member_avatar_url TEXT,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.user_id as member_id,
        COALESCE(au.raw_user_meta_data->>'name', au.email)::TEXT as member_name,
        au.email::TEXT as member_email,
        COALESCE(au.raw_user_meta_data->>'avatar_url', '')::TEXT as member_avatar_url,
        tm.role::TEXT,
        tm.joined_at
    FROM team_members tm
    JOIN auth.users au ON tm.user_id = au.id
    WHERE tm.team_id = team_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get member projects (for invited projects)
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

-- Function to get member teams
CREATE OR REPLACE FUNCTION get_member_teams(user_profile_id UUID)
RETURNS TABLE (
    team_id UUID,
    team_name VARCHAR(255),
    team_description TEXT,
    team_created_at TIMESTAMP WITH TIME ZONE,
    project_id UUID,
    project_name VARCHAR(255),
    project_description TEXT,
    project_owner_id UUID,
    project_created_at TIMESTAMP WITH TIME ZONE,
    role VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id as team_id,
        t.name as team_name,
        t.description as team_description,
        t.created_at as team_created_at,
        p.id as project_id,
        p.name as project_name,
        p.description as project_description,
        p.user_id as project_owner_id,
        p.created_at as project_created_at,
        tm.role,
        tm.joined_at
    FROM teams t
    JOIN projects p ON t.project_id = p.id
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = user_profile_id
    ORDER BY tm.joined_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept team invitations
CREATE OR REPLACE FUNCTION accept_team_invitation(invitation_token TEXT)
RETURNS JSON AS $$
DECLARE
    invitation_record RECORD;
    current_user_id UUID;
BEGIN
    -- Get the current user ID
    current_user_id := auth.uid();
    
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
    IF (SELECT email FROM auth.users WHERE id = current_user_id) != invitation_record.email THEN
        RETURN json_build_object('success', false, 'message', 'Email does not match invitation');
    END IF;
    
    -- Add user to team
    INSERT INTO team_members (team_id, user_id, role)
    VALUES (invitation_record.team_id, current_user_id, COALESCE(invitation_record.role, 'member'))
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

-- Function to create team invitations
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
    
    -- Create the invitation with project_id and token
    INSERT INTO team_invitations (
        team_id,
        project_id,
        email,
        invited_by,
        status,
        expires_at,
        role,
        token
    ) VALUES (
        team_id_param,
        project_id_param,
        invite_email,
        current_user_id,
        'pending',
        NOW() + INTERVAL '7 days', -- Invitation expires in 7 days
        invite_role,
        invitation_token
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

-- Function to create teams with auto-add creator as owner
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

-- Function to handle new user signup and create profile
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to sync existing users to profiles table
CREATE OR REPLACE FUNCTION sync_existing_users_to_profiles()
RETURNS INTEGER AS $$
DECLARE
    user_count INTEGER;
BEGIN
    INSERT INTO public.profiles (id, name, email, avatar_url)
    SELECT 
        id,
        COALESCE(raw_user_meta_data->>'name', email),
        email,
        raw_user_meta_data->>'avatar_url'
    FROM auth.users
    WHERE id NOT IN (SELECT id FROM public.profiles)
    ON CONFLICT (id) DO NOTHING;
    
    GET DIAGNOSTICS user_count = ROW_COUNT;
    RETURN user_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create profile for team member
CREATE OR REPLACE FUNCTION create_profile_for_team_member(
    user_id_param UUID,
    name_param TEXT,
    email_param TEXT,
    avatar_url_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Insert or update profile
    INSERT INTO public.profiles (id, name, email, avatar_url)
    VALUES (user_id_param, name_param, email_param, avatar_url_param)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        avatar_url = EXCLUDED.avatar_url,
        updated_at = NOW();
    
    RETURN json_build_object('success', true, 'message', 'Profile created/updated successfully');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating profile: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is team owner (avoids policy recursion)
CREATE OR REPLACE FUNCTION is_team_owner(user_id_param UUID, team_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND created_by = user_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is team member (avoids policy recursion)
CREATE OR REPLACE FUNCTION is_team_member(user_id_param UUID, team_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM team_members 
        WHERE team_id = team_id_param 
        AND user_id = user_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get assignee display name
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

-- =============================================================================
-- 5. CREATE VIEWS
-- =============================================================================

-- View for todos with assignee names
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

-- =============================================================================
-- 6. CREATE TRIGGERS
-- =============================================================================

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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

CREATE TRIGGER update_bug_comments_updated_at BEFORE UPDATE ON bug_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create trigger to automatically create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================================================
-- 7. ENABLE ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_comments ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 8. CREATE ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- =============================================================================
-- PROFILES TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can view profiles of team members in their projects
CREATE POLICY "Users can view team member profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm1
            JOIN team_members tm2 ON tm1.team_id = tm2.team_id
            WHERE tm1.user_id = auth.uid()
            AND tm2.user_id = profiles.id
        )
    );

-- Users can view inviter profiles for their invitations
CREATE POLICY "Users can view inviter profiles for their invitations" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.invited_by = profiles.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- =============================================================================
-- PROJECTS TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own projects
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Users can view project names for projects they have invitations to
CREATE POLICY "Users can view project names for their invitations" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.project_id = projects.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- Users can view project names for projects they are team members of
CREATE POLICY "Users can view project names for their team projects" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

-- Users can create their own projects
CREATE POLICY "Users can create their own projects" ON projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own projects
CREATE POLICY "Users can update their own projects" ON projects
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own projects
CREATE POLICY "Users can delete their own projects" ON projects
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- TEAMS TABLE RLS POLICIES
-- =============================================================================

-- Users can view teams they created
CREATE POLICY "Users can view teams they created" ON teams
    FOR SELECT USING (auth.uid() = created_by);

-- Users can view teams they are members of
CREATE POLICY "Users can view teams they are members of" ON teams
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm 
            WHERE tm.team_id = teams.id 
            AND tm.user_id = auth.uid()
        )
    );

-- Project owners can create teams for their projects
CREATE POLICY "Project owners can create teams" ON teams
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        auth.uid() IN (
            SELECT user_id FROM projects WHERE id = project_id
        )
    );

-- Team owners can update teams they created
CREATE POLICY "Team owners can update teams" ON teams
    FOR UPDATE USING (auth.uid() = created_by);

-- Team owners can delete teams they created
CREATE POLICY "Team owners can delete teams" ON teams
    FOR DELETE USING (auth.uid() = created_by);

-- =============================================================================
-- TEAM_MEMBERS TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own team memberships
CREATE POLICY "Users can view their own team memberships" ON team_members
    FOR SELECT USING (auth.uid() = user_id);

-- Team owners can view their team members (using function to avoid recursion)
CREATE POLICY "Team owners can view their team members" ON team_members
    FOR SELECT USING (
        is_team_owner(auth.uid(), team_id)
    );

-- Users can join teams (for invitation acceptance)
CREATE POLICY "Users can join teams" ON team_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Team owners can add members to their teams (using function to avoid recursion)
CREATE POLICY "Team owners can add members to their teams" ON team_members
    FOR INSERT WITH CHECK (
        is_team_owner(auth.uid(), team_id)
    );

-- Users can leave teams (delete themselves)
CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);

-- Team owners can remove members from their teams (using function to avoid recursion)
CREATE POLICY "Team owners can remove members from their teams" ON team_members
    FOR DELETE USING (
        is_team_owner(auth.uid(), team_id)
    );

-- =============================================================================
-- TEAM_INVITATIONS TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own invitations
CREATE POLICY "Users can view their own invitations" ON team_invitations
    FOR SELECT USING (email = auth.jwt() ->> 'email');

-- Team owners can create invitations for their teams
CREATE POLICY "Team owners can create invitations" ON team_invitations
    FOR INSERT WITH CHECK (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Team owners can update invitations for their teams
CREATE POLICY "Team owners can update invitations" ON team_invitations
    FOR UPDATE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Team owners can delete invitations for their teams
CREATE POLICY "Team owners can delete invitations" ON team_invitations
    FOR DELETE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- =============================================================================
-- BUGS TABLE RLS POLICIES
-- =============================================================================

-- Users can view all bugs (for collaboration)
CREATE POLICY "Users can view all bugs" ON bugs
    FOR SELECT USING (true);

-- Users can create bugs
CREATE POLICY "Users can create bugs" ON bugs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own bugs
CREATE POLICY "Users can update their own bugs" ON bugs
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own bugs
CREATE POLICY "Users can delete their own bugs" ON bugs
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- TODOS TABLE RLS POLICIES
-- =============================================================================

-- Users can view all todos (for collaboration)
CREATE POLICY "Users can view all todos" ON todos
    FOR SELECT USING (true);

-- Users can create todos
CREATE POLICY "Users can create todos" ON todos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own todos
CREATE POLICY "Users can update their own todos" ON todos
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own todos
CREATE POLICY "Users can delete their own todos" ON todos
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- BUG_IMAGES TABLE RLS POLICIES
-- =============================================================================

-- Users can view bug images (for debugging - permissive)
CREATE POLICY "Users can view bug images" ON bug_images
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Users can upload bug images (for debugging - permissive)
CREATE POLICY "Users can upload bug images" ON bug_images
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Users can delete bug images (for debugging - permissive)
CREATE POLICY "Users can delete bug images" ON bug_images
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- =============================================================================
-- BUG_COMMENTS TABLE RLS POLICIES
-- =============================================================================

-- Users can view comments for bugs in their projects
CREATE POLICY "Users can view bug comments" ON bug_comments
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bugs b
            JOIN projects p ON b.project_id = p.id
            WHERE b.id = bug_comments.bug_id
            AND (p.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM team_members tm
                JOIN teams t ON tm.team_id = t.id
                WHERE t.project_id = p.id
                AND tm.user_id = auth.uid()
            ))
        )
    );

-- Users can create comments for bugs in their projects
CREATE POLICY "Users can create bug comments" ON bug_comments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM bugs b
            JOIN projects p ON b.project_id = p.id
            WHERE b.id = bug_comments.bug_id
            AND (p.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM team_members tm
                JOIN teams t ON tm.team_id = t.id
                WHERE t.project_id = p.id
                AND tm.user_id = auth.uid()
            ))
        )
    );

-- Users can update their own comments
CREATE POLICY "Users can update their own comments" ON bug_comments
    FOR UPDATE
    USING (
        author = (SELECT COALESCE(raw_user_meta_data->>'name', email) FROM auth.users WHERE id = auth.uid())
        AND EXISTS (
            SELECT 1 FROM bugs b
            JOIN projects p ON b.project_id = p.id
            WHERE b.id = bug_comments.bug_id
            AND (p.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM team_members tm
                JOIN teams t ON tm.team_id = t.id
                WHERE t.project_id = p.id
                AND tm.user_id = auth.uid()
            ))
        )
    );

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments" ON bug_comments
    FOR DELETE
    USING (
        author = (SELECT COALESCE(raw_user_meta_data->>'name', email) FROM auth.users WHERE id = auth.uid())
        AND EXISTS (
            SELECT 1 FROM bugs b
            JOIN projects p ON b.project_id = p.id
            WHERE b.id = bug_comments.bug_id
            AND (p.user_id = auth.uid() OR EXISTS (
                SELECT 1 FROM team_members tm
                JOIN teams t ON tm.team_id = t.id
                WHERE t.project_id = p.id
                AND tm.user_id = auth.uid()
            ))
        )
    );

-- =============================================================================
-- 9. CREATE STORAGE BUCKET
-- =============================================================================

-- Create the bug-images storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'bug-images',
    'bug-images',
    true, -- Public bucket for easy access
    52428800, -- 50MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];

-- =============================================================================
-- 10. CREATE STORAGE POLICIES
-- =============================================================================

-- Policy for viewing images (public access)
CREATE POLICY "Anyone can view bug images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'bug-images');

-- Policy for uploading images (authenticated users only)
CREATE POLICY "Any authenticated user can upload bug images" ON storage.objects
    FOR INSERT
    WITH CHECK (bucket_id = 'bug-images');

-- Policy for updating images (authenticated users only)
CREATE POLICY "Any authenticated user can update bug images" ON storage.objects
    FOR UPDATE
    USING (bucket_id = 'bug-images');

-- Policy for deleting images (authenticated users only)
CREATE POLICY "Any authenticated user can delete bug images" ON storage.objects
    FOR DELETE
    USING (bucket_id = 'bug-images');

-- =============================================================================
-- 11. GRANT PERMISSIONS
-- =============================================================================

-- Grant necessary permissions for authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Grant execute permissions on specific functions
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_teams(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_team_invitation(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_team_with_owner(VARCHAR, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_profile_for_team_member(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_team_owner(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_team_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_assignee_display_name(TEXT) TO authenticated;

-- Grant select permission on views
GRANT SELECT ON todos_with_assignee_names TO authenticated;

-- =============================================================================
-- 12. SYNC EXISTING DATA
-- =============================================================================

-- Sync existing users to profiles table
SELECT sync_existing_users_to_profiles();

-- Update existing teams to add their creators as team members if not already present
INSERT INTO team_members (team_id, user_id, role)
SELECT t.id, t.created_by, 'owner'
FROM teams t
WHERE NOT EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.team_id = t.id AND tm.user_id = t.created_by
)
ON CONFLICT (team_id, user_id) DO NOTHING;

-- =============================================================================
-- 13. ADD COMMENTS AND DOCUMENTATION
-- =============================================================================

-- Add comments to functions
COMMENT ON FUNCTION get_assignee_display_name(TEXT) IS 'Returns the display name for a user ID from the profiles table, or "Unknown User" if not found';
COMMENT ON VIEW todos_with_assignee_names IS 'View that includes todos with resolved assignee names instead of UUIDs';

-- =============================================================================
-- SCHEMA SETUP COMPLETE
-- =============================================================================
-- 
-- This script has successfully set up:
-- 1. All necessary tables with proper relationships
-- 2. Comprehensive indexes for performance
-- 3. All required functions for application functionality
-- 4. Row Level Security policies for data protection
-- 5. Storage bucket and policies for file uploads
-- 6. Triggers for automatic timestamp updates
-- 7. Views for enhanced data access
-- 8. Proper permissions for authenticated users
-- 
-- Your Supabase instance is now ready to use with the Smasher Light application!
-- =============================================================================
