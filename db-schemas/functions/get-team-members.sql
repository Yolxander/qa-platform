-- Function to get team members for a specific team
-- This function returns all members of a team with their details

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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;

-- Create RLS policy to allow users to call this function if they are team members
CREATE POLICY "Users can get team members if they are in the team" ON public.team_members
  FOR SELECT USING (
    team_id IN (
      SELECT team_id FROM public.team_members WHERE profile_id = auth.uid()
    )
  );
