-- Diagnose and fix team invitation issues
-- Run this in your Supabase SQL Editor to check current state and fix issues

-- =============================================
-- 1. DIAGNOSE CURRENT STATE
-- =============================================

-- Check if team_invitations table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'team_invitations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if team_id column exists
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'team_invitations' 
    AND column_name = 'team_id'
    AND table_schema = 'public'
) AS team_id_exists;

-- Check existing functions
SELECT 
    routine_name, 
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_name LIKE '%invitation%' 
AND routine_schema = 'public';

-- =============================================
-- 2. FIX MISSING COLUMN
-- =============================================

-- Add team_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'team_invitations' 
        AND column_name = 'team_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.team_invitations 
        ADD COLUMN team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Added team_id column to team_invitations table';
    ELSE
        RAISE NOTICE 'team_id column already exists';
    END IF;
END $$;

-- =============================================
-- 3. CREATE INDEX
-- =============================================

CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON public.team_invitations(team_id);

-- =============================================
-- 4. DROP AND RECREATE FUNCTION
-- =============================================

-- Drop all existing invitation functions
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.accept_team_invitation(TEXT);

-- Create the new team-specific invitation function
CREATE OR REPLACE FUNCTION public.create_team_invitation(
  invite_email TEXT,
  invite_name TEXT,
  project_id_param UUID,
  team_id_param UUID,
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
  
  -- Check if team belongs to the project
  IF NOT EXISTS (
    SELECT 1 FROM public.teams 
    WHERE id = team_id_param 
    AND project_id = project_id_param
  ) THEN
    RAISE EXCEPTION 'Team does not belong to the specified project';
  END IF;
  
  -- Check if invitation already exists for this email, project, and team
  IF EXISTS (
    SELECT 1 FROM public.team_invitations 
    WHERE email = invite_email 
    AND project_id = project_id_param 
    AND team_id = team_id_param
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'An invitation for this email already exists for this team in this project';
  END IF;
  
  -- Create the invitation
  INSERT INTO public.team_invitations (email, name, role, project_id, team_id, invited_by)
  VALUES (invite_email, invite_name, invite_role, project_id_param, team_id_param, user_id_param)
  RETURNING id INTO invitation_id;
  
  RETURN invitation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the accept invitation function
CREATE OR REPLACE FUNCTION public.accept_team_invitation(
  invitation_token TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  invitation_record RECORD;
BEGIN
  -- Get the invitation
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
  
  -- Add user to the specific team
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
-- 5. GRANT PERMISSIONS
-- =============================================

-- Grant execute permissions on the functions
GRANT EXECUTE ON FUNCTION public.create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(TEXT) TO authenticated;

-- =============================================
-- 6. VERIFY SETUP
-- =============================================

-- Check if functions were created successfully
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'create_team_invitation' 
AND routine_schema = 'public';

-- Check function parameters
SELECT 
    parameter_name,
    data_type,
    parameter_default
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'create_team_invitation' 
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- =============================================
-- 7. TEST FUNCTION (Optional)
-- =============================================

-- Uncomment and modify this section to test the function
-- You'll need to replace the UUIDs with actual values from your database

/*
-- Test the function (replace with actual values)
SELECT public.create_team_invitation(
    'test@example.com',
    'Test User',
    'your-project-uuid-here',
    'your-team-uuid-here',
    'developer'
);
*/
