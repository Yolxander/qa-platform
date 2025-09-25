-- Updated Accept Team Invitation Function
-- This script ensures the team_invitations table has team_id column and updates the accept function
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. ENSURE TEAM_ID COLUMN EXISTS
-- =============================================

-- Add team_id column to team_invitations table if it doesn't exist
ALTER TABLE public.team_invitations 
ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE;

-- Create index for the team_id column if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON public.team_invitations(team_id);

-- =============================================
-- 2. UPDATE EXISTING INVITATIONS (if needed)
-- =============================================

-- If there are existing invitations without team_id, set them to the default team for their project
UPDATE public.team_invitations 
SET team_id = (
  SELECT t.id 
  FROM public.teams t 
  WHERE t.project_id = team_invitations.project_id 
  LIMIT 1
)
WHERE team_id IS NULL;

-- =============================================
-- 3. CREATE UPDATED ACCEPT TEAM INVITATION FUNCTION
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
-- 4. GRANT PERMISSIONS
-- =============================================

-- Grant execute permissions on the function
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(TEXT) TO authenticated;

-- =============================================
-- 5. ADD COMMENTS
-- =============================================

COMMENT ON FUNCTION public.accept_team_invitation IS 'Accepts a team invitation and adds user to the specific team using team_id from the invitation';

-- =============================================
-- 6. VERIFY THE UPDATE
-- =============================================

-- Optional: You can run this query to verify the function was created successfully
-- SELECT routine_name, routine_definition 
-- FROM information_schema.routines 
-- WHERE routine_name = 'accept_team_invitation' 
-- AND routine_schema = 'public';
