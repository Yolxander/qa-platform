-- Team Member Functions
-- These functions help manage teams where users are members but not owners

-- =============================================
-- 1. GET MEMBER TEAMS FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION get_member_teams(user_profile_id UUID)
RETURNS TABLE (
  team_id UUID,
  team_name TEXT,
  team_description TEXT,
  project_id UUID,
  project_name TEXT,
  project_description TEXT,
  user_role TEXT,
  joined_at TIMESTAMP WITH TIME ZONE,
  team_created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id as team_id,
    t.name as team_name,
    t.description as team_description,
    t.project_id,
    p.name as project_name,
    p.description as project_description,
    tm.role as user_role,
    tm.joined_at,
    t.created_at as team_created_at
  FROM public.team_members tm
  INNER JOIN public.teams t ON tm.team_id = t.id
  INNER JOIN public.projects p ON t.project_id = p.id
  WHERE tm.profile_id = user_profile_id
    AND p.user_id != user_profile_id  -- User is not the project owner
  ORDER BY tm.joined_at DESC;
END;
$$;

-- =============================================
-- 2. GET MEMBER PROJECTS FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION get_member_projects(user_profile_id UUID)
RETURNS TABLE (
  project_id UUID,
  project_name TEXT,
  project_description TEXT,
  project_owner_id UUID,
  project_created_at TIMESTAMP WITH TIME ZONE,
  team_id UUID,
  team_name TEXT,
  user_role TEXT,
  joined_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    p.id as project_id,
    p.name as project_name,
    p.description as project_description,
    p.user_id as project_owner_id,
    p.created_at as project_created_at,
    t.id as team_id,
    t.name as team_name,
    tm.role as user_role,
    tm.joined_at
  FROM public.team_members tm
  INNER JOIN public.teams t ON tm.team_id = t.id
  INNER JOIN public.projects p ON t.project_id = p.id
  WHERE tm.profile_id = user_profile_id
    AND p.user_id != user_profile_id  -- User is not the project owner
  ORDER BY tm.joined_at DESC;
END;
$$;

-- =============================================
-- 3. GET TEAM MEMBERS FUNCTION
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
AS $$
BEGIN
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
-- 4. GRANT PERMISSIONS
-- =============================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_member_teams(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;

-- =============================================
-- 5. CREATE RLS POLICIES
-- =============================================

-- Policy for team members to access their own data
CREATE POLICY "Users can access their team memberships" ON public.team_members
  FOR SELECT USING (profile_id = auth.uid());

-- Policy for team members to access team data
CREATE POLICY "Users can access teams they are members of" ON public.teams
  FOR SELECT USING (
    id IN (
      SELECT team_id FROM public.team_members WHERE profile_id = auth.uid()
    )
  );

-- Policy for team members to access project data
CREATE POLICY "Users can access projects from their teams" ON public.projects
  FOR SELECT USING (
    id IN (
      SELECT DISTINCT t.project_id 
      FROM public.teams t
      INNER JOIN public.team_members tm ON t.id = tm.team_id
      WHERE tm.profile_id = auth.uid()
    )
  );
