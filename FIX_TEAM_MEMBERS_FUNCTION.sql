-- Fix Team Members Function to Handle Both Owner and Member Access
-- This script updates the get_team_members function to work for both project owners and team members

-- =============================================
-- 1. DROP AND RECREATE THE FUNCTION
-- =============================================

DROP FUNCTION IF EXISTS get_team_members(UUID);

-- =============================================
-- 2. CREATE UPDATED FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION get_team_members(team_uuid UUID)
RETURNS TABLE (
  member_id UUID,
  member_name TEXT,
  member_email TEXT,
  member_avatar_url TEXT,
  role TEXT,
  joined_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Security check: ensure the user has access to this team
  -- Either they are a member of the team OR they own the project
  IF NOT EXISTS (
    SELECT 1 FROM public.team_members 
    WHERE team_id = team_uuid AND profile_id = auth.uid()
  ) AND NOT EXISTS (
    SELECT 1 FROM public.teams t
    INNER JOIN public.projects p ON t.project_id = p.id
    WHERE t.id = team_uuid AND p.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: not authorized to view this team';
  END IF;

  RETURN QUERY
  SELECT 
    p.id as member_id,
    p.name as member_name,
    p.email as member_email,
    p.avatar_url as member_avatar_url,
    tm.role,
    tm.joined_at
  FROM public.team_members tm
  INNER JOIN public.profiles p ON tm.profile_id = p.id
  WHERE tm.team_id = team_uuid
  ORDER BY tm.joined_at ASC;
END;
$$;

-- =============================================
-- 3. GRANT PERMISSIONS
-- =============================================

GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;

-- =============================================
-- 4. VERIFY THE FUNCTION
-- =============================================

-- Check that the function was created
SELECT 
  routine_name, 
  routine_type,
  security_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'get_team_members';
