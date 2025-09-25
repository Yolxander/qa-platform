-- Secure Functions Without Complex RLS Dependencies
-- This script creates secure database functions that don't rely on complex RLS policies

-- =============================================
-- 1. DROP EXISTING FUNCTIONS (to recreate them)
-- =============================================

DROP FUNCTION IF EXISTS get_member_teams(UUID);
DROP FUNCTION IF EXISTS get_member_projects(UUID);
DROP FUNCTION IF EXISTS get_team_members(UUID);

-- =============================================
-- 2. CREATE SECURE FUNCTIONS
-- =============================================

-- Function to get teams where user is a member but not the owner
-- This function is SECURITY DEFINER and handles its own security
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
SET search_path = public
AS $$
BEGIN
  -- Security check: ensure the user is requesting their own data
  IF user_profile_id != auth.uid() THEN
    RAISE EXCEPTION 'Access denied: can only access own data';
  END IF;

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

-- Function to get projects from teams where user is a member but not the owner
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
SET search_path = public
AS $$
BEGIN
  -- Security check: ensure the user is requesting their own data
  IF user_profile_id != auth.uid() THEN
    RAISE EXCEPTION 'Access denied: can only access own data';
  END IF;

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

-- Function to get team members for a specific team
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
  -- Security check: ensure the user is a member of this team
  IF NOT EXISTS (
    SELECT 1 FROM public.team_members 
    WHERE team_id = team_uuid AND profile_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: not a member of this team';
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_member_teams(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;

-- =============================================
-- 4. CREATE MINIMAL RLS POLICIES
-- =============================================

-- Drop all existing policies first
DROP POLICY IF EXISTS "Users can access projects from their teams" ON public.projects;
DROP POLICY IF EXISTS "Users can view teams in their projects" ON public.teams;
DROP POLICY IF EXISTS "Users can access teams they are members of" ON public.teams;
DROP POLICY IF EXISTS "Users can view team members in their project teams" ON public.team_members;
DROP POLICY IF EXISTS "Users can access their team memberships" ON public.team_members;
DROP POLICY IF EXISTS "Users can view own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can view teams in own projects" ON public.teams;
DROP POLICY IF EXISTS "Users can view own memberships" ON public.team_members;

-- Create minimal policies that won't cause recursion
CREATE POLICY "Users can view own projects" ON public.projects
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view teams in own projects" ON public.teams
  FOR SELECT USING (
    project_id IN (
      SELECT id FROM public.projects WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view own memberships" ON public.team_members
  FOR SELECT USING (profile_id = auth.uid());

-- =============================================
-- 5. VERIFY SETUP
-- =============================================

-- Check functions exist
SELECT 
  routine_name, 
  routine_type,
  security_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('get_member_teams', 'get_member_projects', 'get_team_members');

-- Check policies exist
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  cmd
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('projects', 'teams', 'team_members')
ORDER BY tablename, policyname;
