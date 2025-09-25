-- Fix get_team_members function to properly cast all text fields
-- This migration ensures all returned text fields are properly cast to TEXT type

-- Drop and recreate the function with proper text casting
DROP FUNCTION IF EXISTS get_team_members(UUID);

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
        COALESCE(au.raw_user_meta_data->>'name', au.email)::TEXT as member_name,  -- Cast to TEXT
        au.email::TEXT as member_email,  -- Cast to TEXT
        COALESCE(au.raw_user_meta_data->>'avatar_url', '')::TEXT as member_avatar_url,  -- Cast to TEXT
        tm.role::TEXT,  -- Cast to TEXT
        tm.joined_at
    FROM team_members tm
    JOIN auth.users au ON tm.user_id = au.id
    WHERE tm.team_id = team_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function to authenticated users
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;
