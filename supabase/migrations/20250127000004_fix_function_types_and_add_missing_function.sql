-- Fix function type mismatches and add missing get_member_teams function
-- This migration fixes the type issues and adds the missing function

-- Drop the existing function first to change return type
DROP FUNCTION IF EXISTS get_team_members(UUID);

-- Recreate the get_team_members function with correct types
CREATE FUNCTION get_team_members(team_uuid UUID)
RETURNS TABLE (
    member_id UUID,
    member_name TEXT,
    member_email TEXT,
    member_avatar_url TEXT,
    role TEXT,  -- Changed from VARCHAR to TEXT
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.user_id as member_id,
        COALESCE(au.raw_user_meta_data->>'name', au.email) as member_name,
        au.email as member_email,
        au.raw_user_meta_data->>'avatar_url' as member_avatar_url,
        tm.role::TEXT,  -- Cast to TEXT
        tm.joined_at
    FROM team_members tm
    JOIN auth.users au ON tm.user_id = au.id
    WHERE tm.team_id = team_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the missing get_member_teams function
CREATE OR REPLACE FUNCTION get_member_teams(user_profile_id UUID)
RETURNS TABLE (
    team_id UUID,
    team_name VARCHAR(255),
    team_description TEXT,
    project_id UUID,
    project_name VARCHAR(255),
    project_description TEXT,
    team_created_at TIMESTAMP WITH TIME ZONE,
    user_role TEXT,
    project_owner_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id as team_id,
        t.name as team_name,
        t.description as team_description,
        p.id as project_id,
        p.name as project_name,
        p.description as project_description,
        t.created_at as team_created_at,
        tm.role::TEXT as user_role,
        p.user_id as project_owner_id
    FROM teams t
    JOIN projects p ON p.id = t.project_id
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = user_profile_id
    ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_teams(UUID) TO authenticated;
