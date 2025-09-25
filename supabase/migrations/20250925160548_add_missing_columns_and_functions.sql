-- Comprehensive migration to add missing columns, tables, and functions
-- This migration adds all the missing database elements needed for full functionality

-- =============================================================================
-- 1. CREATE MISSING PROFILES TABLE
-- =============================================================================

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_name ON profiles(name);

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. ADD MISSING COLUMNS TO EXISTING TABLES
-- =============================================================================

-- Add missing columns to bugs table
ALTER TABLE bugs ADD COLUMN IF NOT EXISTS steps_to_reproduce TEXT;
ALTER TABLE bugs ADD COLUMN IF NOT EXISTS url TEXT;

-- Add missing columns to team_invitations table
ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'member';
ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_team_invitations_project_id ON team_invitations(project_id);

-- =============================================================================
-- 3. CREATE ESSENTIAL FUNCTIONS
-- =============================================================================

-- Drop existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS get_team_members(UUID);

-- Create function to get team members with proper text casting
CREATE FUNCTION get_team_members(team_uuid UUID)
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

-- Drop existing function first to avoid conflicts
DROP FUNCTION IF EXISTS get_member_projects(UUID);

-- Create function to get member projects (for invited projects)
CREATE FUNCTION get_member_projects(user_profile_id UUID)
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

-- Drop existing function first to avoid conflicts
DROP FUNCTION IF EXISTS accept_team_invitation(TEXT);

-- Create function to accept team invitations
CREATE FUNCTION accept_team_invitation(invitation_token TEXT)
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

-- Create function to create team invitations
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

-- =============================================================================
-- 4. CREATE USER PROFILE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Create function to handle new user signup and create profile
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

-- Create function to sync existing users to profiles table
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

-- Create function to create profile for team member
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

-- =============================================================================
-- 5. CREATE TRIGGERS
-- =============================================================================

-- Create trigger to automatically create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================================================
-- 6. GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_team_invitation(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_profile_for_team_member(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- =============================================================================
-- 7. SYNC EXISTING DATA
-- =============================================================================

-- Sync existing users to profiles table
SELECT sync_existing_users_to_profiles();
