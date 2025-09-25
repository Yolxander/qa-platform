-- Function to get projects from teams where user is a member but not the owner
-- This function returns projects that the user has access to through team membership

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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;

-- Create RLS policy to allow users to call this function
CREATE POLICY "Users can get their member projects" ON public.team_members
  FOR SELECT USING (profile_id = auth.uid());
