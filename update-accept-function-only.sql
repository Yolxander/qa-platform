-- Update Accept Team Invitation Function Only
-- This script only updates the accept_team_invitation function to use team_id from invitation
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. UPDATE ACCEPT TEAM INVITATION FUNCTION
-- =============================================

-- Drop the existing function
DROP FUNCTION IF EXISTS public.accept_team_invitation(TEXT);

-- Create the updated function that uses team_id from the invitation
CREATE OR REPLACE FUNCTION public.accept_team_invitation(
  invitation_token TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  invitation_record RECORD;
BEGIN
  -- Get the invitation with all details including team_id
  SELECT * INTO invitation_record 
  FROM public.team_invitations 
  WHERE token = invitation_token 
  AND status = 'pending' 
  AND expires_at > NOW();
  
  -- Check if invitation exists and is valid
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation token';
  END IF;
  
  -- Check if user profile exists
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'User profile not found';
  END IF;
  
  -- Validate that team_id exists in the invitation
  IF invitation_record.team_id IS NULL THEN
    RAISE EXCEPTION 'Invitation does not have a valid team_id';
  END IF;
  
  -- Validate that the team exists and belongs to the project
  IF NOT EXISTS (
    SELECT 1 FROM public.teams 
    WHERE id = invitation_record.team_id 
    AND project_id = invitation_record.project_id
  ) THEN
    RAISE EXCEPTION 'Team does not exist or does not belong to the specified project';
  END IF;
  
  -- Add user to the team using the team_id from the invitation
  INSERT INTO public.team_members (team_id, profile_id, role)
  VALUES (
    invitation_record.team_id, 
    auth.uid(), 
    invitation_record.role
  )
  ON CONFLICT (team_id, profile_id) DO UPDATE SET
    role = EXCLUDED.role,
    joined_at = NOW();
  
  -- Mark invitation as accepted
  UPDATE public.team_invitations 
  SET status = 'accepted', updated_at = NOW()
  WHERE id = invitation_record.id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 2. GRANT PERMISSIONS
-- =============================================

-- Grant execute permissions on the function
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(TEXT) TO authenticated;

-- =============================================
-- 3. ADD COMMENTS
-- =============================================

COMMENT ON FUNCTION public.accept_team_invitation IS 'Accepts a team invitation and adds user to the specific team using team_id from the invitation';
