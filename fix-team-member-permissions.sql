-- Fix Team Member Permission Issues
-- This script fixes the RLS policies to allow team member creation
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. DROP EXISTING RESTRICTIVE POLICIES
-- =============================================

-- Drop the restrictive profiles policies that prevent team member creation
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- =============================================
-- 2. CREATE NEW FLEXIBLE POLICIES
-- =============================================

-- Allow users to view profiles of team members in their projects
CREATE POLICY "Users can view profiles in their project teams" ON public.profiles
  FOR SELECT USING (
    -- Users can always view their own profile
    auth.uid() = id OR
    -- Users can view profiles of team members in their projects
    EXISTS (
      SELECT 1 FROM public.team_members tm
      JOIN public.teams t ON t.id = tm.team_id
      JOIN public.projects p ON p.id = t.project_id
      WHERE tm.profile_id = profiles.id
      AND p.user_id = auth.uid()
    ) OR
    -- Users can view all profiles to add new team members (for the dropdown)
    EXISTS (
      SELECT 1 FROM public.projects
      WHERE projects.user_id = auth.uid()
    )
  );

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert profiles for team members in their projects
CREATE POLICY "Users can insert profiles for team members" ON public.profiles
  FOR INSERT WITH CHECK (
    -- Users can always insert their own profile
    auth.uid() = id OR
    -- Users can insert profiles for team members in their projects
    EXISTS (
      SELECT 1 FROM public.projects
      WHERE projects.user_id = auth.uid()
    )
  );

-- =============================================
-- 3. CREATE HELPER FUNCTION FOR TEAM MEMBER CREATION
-- =============================================

-- Function to safely create a profile for team member if it doesn't exist
CREATE OR REPLACE FUNCTION public.create_profile_for_team_member(
  profile_email TEXT,
  profile_name TEXT,
  project_id_param UUID
)
RETURNS UUID AS $$
DECLARE
  profile_id UUID;
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
    RAISE EXCEPTION 'Access denied: You do not have permission to add members to this project';
  END IF;
  
  -- Check if profile already exists
  SELECT id INTO profile_id 
  FROM public.profiles 
  WHERE email = profile_email;
  
  -- If profile doesn't exist, we can't create it because profiles must reference auth.users
  -- Instead, we'll create a placeholder and let the user know they need to register
  IF profile_id IS NULL THEN
    RAISE EXCEPTION 'User with email % does not exist. They must register first before being added to the team.', profile_email;
  END IF;
  
  RETURN profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 4. CREATE FUNCTION TO ADD TEAM MEMBER SAFELY
-- =============================================

-- Function to add a team member with proper permission checks
CREATE OR REPLACE FUNCTION public.add_team_member_safely(
  member_email TEXT,
  member_name TEXT,
  project_id_param UUID,
  member_role TEXT DEFAULT 'developer'
)
RETURNS BOOLEAN AS $$
DECLARE
  profile_id UUID;
  team_id UUID;
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
    RAISE EXCEPTION 'Access denied: You do not have permission to add members to this project';
  END IF;
  
  -- Create or get profile
  profile_id := public.create_profile_for_team_member(
    member_email, 
    member_name, 
    project_id_param
  );
  
  -- Get the team for this project
  SELECT id INTO team_id 
  FROM public.teams 
  WHERE project_id = project_id_param;
  
  IF team_id IS NULL THEN
    RAISE EXCEPTION 'No team found for this project';
  END IF;
  
  -- Add member to team (ignore if already exists)
  INSERT INTO public.team_members (team_id, profile_id, role)
  VALUES (team_id, profile_id, member_role)
  ON CONFLICT (team_id, profile_id) DO NOTHING;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 5. GRANT PERMISSIONS
-- =============================================

-- Grant execute permissions on the new functions
GRANT EXECUTE ON FUNCTION public.create_profile_for_team_member TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_team_member_safely TO authenticated;

-- =============================================
-- 6. VERIFICATION QUERIES
-- =============================================

-- Verify the new policies exist
SELECT 
  schemaname, 
  tablename, 
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'profiles'
ORDER BY policyname;

-- Verify the new functions exist
SELECT 
  routine_name,
  routine_type,
  security_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('create_profile_for_team_member', 'add_team_member_safely');

-- =============================================
-- 7. TEST THE FIX
-- =============================================

-- Test query to verify profiles can be viewed
-- (This should work without 403/406 errors)
SELECT 
  'Profiles accessible: ' || COUNT(*) as test_result
FROM public.profiles;

-- Test that the helper function works
-- (Replace with actual project_id from your database)
-- SELECT public.add_team_member_safely(
--   'test@example.com',
--   'Test User',
--   'developer',
--   'your-project-id-here'
-- );
