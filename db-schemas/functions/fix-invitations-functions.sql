-- Fix Invitations Functions
-- This script creates the missing database functions for the invitation system
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. DROP EXISTING FUNCTIONS (if they exist)
-- =============================================

DROP FUNCTION IF EXISTS public.get_user_invitations();
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.accept_team_invitation(TEXT);

-- =============================================
-- 2. CREATE get_user_invitations FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION public.get_user_invitations()
RETURNS TABLE (
  id UUID,
  email TEXT,
  name TEXT,
  role TEXT,
  project_id UUID,
  invited_by UUID,
  status TEXT,
  token TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  project_name TEXT,
  inviter_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ti.id,
    ti.email,
    ti.name,
    ti.role,
    ti.project_id,
    ti.invited_by,
    ti.status,
    ti.token,
    ti.expires_at,
    ti.created_at,
    p.name as project_name,
    COALESCE(prof.name, u.email) as inviter_name
  FROM public.team_invitations ti
  JOIN public.projects p ON ti.project_id = p.id
  JOIN auth.users u ON ti.invited_by = u.id
  LEFT JOIN public.profiles prof ON ti.invited_by = prof.id
  WHERE ti.email = (SELECT email FROM auth.users WHERE id = auth.uid())
  AND ti.status = 'pending'
  AND ti.expires_at > NOW()
  ORDER BY ti.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 3. CREATE create_team_invitation FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION public.create_team_invitation(
  invite_email TEXT,
  invite_name TEXT,
  project_id_param UUID,
  invite_role TEXT DEFAULT 'developer'
)
RETURNS UUID AS $$
DECLARE
  invitation_id UUID;
  user_id_param UUID;
BEGIN
  -- Get the current user ID
  user_id_param := auth.uid();
  
  -- Check if user has access to the project
  IF NOT EXISTS (
    SELECT 1 FROM public.projects 
    WHERE id = project_id_param 
    AND user_id = user_id_param
  ) THEN
    RAISE EXCEPTION 'Access denied: You do not have permission to invite members to this project';
  END IF;
  
  -- Check if invitation already exists
  IF EXISTS (
    SELECT 1 FROM public.team_invitations 
    WHERE email = invite_email 
    AND project_id = project_id_param 
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'An invitation for this email already exists for this project';
  END IF;
  
  -- Create the invitation
  INSERT INTO public.team_invitations (email, name, role, project_id, invited_by)
  VALUES (invite_email, invite_name, invite_role, project_id_param, user_id_param)
  RETURNING id INTO invitation_id;
  
  RETURN invitation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 4. CREATE accept_team_invitation FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION public.accept_team_invitation(
  invitation_token TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  invitation_record RECORD;
  team_id UUID;
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
  SELECT id INTO team_id 
  FROM public.teams 
  WHERE project_id = invitation_record.project_id;
  
  IF team_id IS NULL THEN
    RAISE EXCEPTION 'No team found for this project';
  END IF;
  
  -- Add the user to the team
  INSERT INTO public.team_members (team_id, profile_id, role)
  VALUES (team_id, auth.uid(), invitation_record.role)
  ON CONFLICT (team_id, profile_id) DO NOTHING;
  
  -- Update invitation status
  UPDATE public.team_invitations 
  SET status = 'accepted', updated_at = NOW()
  WHERE id = invitation_record.id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 5. GRANT PERMISSIONS
-- =============================================

GRANT EXECUTE ON FUNCTION public.get_user_invitations() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(TEXT) TO authenticated;

-- =============================================
-- 6. VERIFICATION QUERIES
-- =============================================

-- Test that functions exist
SELECT 'get_user_invitations function created' as status;
SELECT 'create_team_invitation function created' as status;
SELECT 'accept_team_invitation function created' as status;
