-- Fix for accept_team_invitation function to resolve ambiguous column reference

CREATE OR REPLACE FUNCTION public.accept_team_invitation(
  invitation_token TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  invitation_record RECORD;
  target_team_id UUID;
BEGIN
  -- Get the invitation
  SELECT * INTO invitation_record 
  FROM public.team_invitations 
  WHERE token = invitation_token 
  AND status = 'pending' 
  AND expires_at > NOW();
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation';
  END IF;
  
  -- Get the team for the project
  SELECT teams.id INTO target_team_id 
  FROM public.teams 
  WHERE teams.project_id = invitation_record.project_id;
  
  IF target_team_id IS NULL THEN
    RAISE EXCEPTION 'No team found for this project';
  END IF;
  
  -- Add the user to the team
  INSERT INTO public.team_members (team_id, profile_id, role)
  VALUES (target_team_id, auth.uid(), invitation_record.role)
  ON CONFLICT (team_id, profile_id) DO NOTHING;
  
  -- Update invitation status
  UPDATE public.team_invitations 
  SET status = 'accepted', updated_at = NOW()
  WHERE id = invitation_record.id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(TEXT) TO authenticated;
