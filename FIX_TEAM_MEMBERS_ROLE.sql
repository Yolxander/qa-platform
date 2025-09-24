-- =============================================
-- FIX TEAM MEMBERS ROLE CONSTRAINT
-- =============================================
-- This script fixes the "team_members_role_check" constraint error
-- Run this in Supabase SQL Editor

-- =============================================
-- 1. CHECK IF TEAM_MEMBERS TABLE EXISTS
-- =============================================

-- First, let's see what tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('projects', 'teams', 'team_members')
ORDER BY table_name;

-- =============================================
-- 2. FIX THE ROLE CONSTRAINT
-- =============================================

-- Update the check constraint to allow 'owner' role
ALTER TABLE public.team_members 
DROP CONSTRAINT IF EXISTS team_members_role_check;

-- Create new constraint that allows 'owner' role
ALTER TABLE public.team_members 
ADD CONSTRAINT team_members_role_check 
CHECK (role IN ('developer', 'tester', 'guest', 'owner'));

-- =============================================
-- 3. ALTERNATIVE: IF TEAM_MEMBERS TABLE DOESN'T EXIST
-- =============================================

-- If the team_members table doesn't exist, create it with proper constraints
CREATE TABLE IF NOT EXISTS public.team_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'developer' CHECK (role IN ('developer', 'tester', 'guest', 'owner')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, profile_id)
);

-- =============================================
-- 4. CREATE TEAMS TABLE IF IT DOESN'T EXIST
-- =============================================

-- Create teams table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 5. ENABLE RLS ON NEW TABLES
-- =============================================

-- Enable RLS on teams and team_members tables
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 6. CREATE RLS POLICIES FOR TEAMS
-- =============================================

-- Teams policies
CREATE POLICY "Users can view teams in their projects" ON public.teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = teams.project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create teams in their projects" ON public.teams
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- Team members policies
CREATE POLICY "Users can view team members in their project teams" ON public.team_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can add team members to their project teams" ON public.team_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

-- =============================================
-- 7. GRANT PERMISSIONS
-- =============================================

-- Grant necessary permissions
GRANT ALL ON public.teams TO authenticated;
GRANT ALL ON public.team_members TO authenticated;

-- =============================================
-- 8. VERIFICATION
-- =============================================

-- Check the constraint was updated
SELECT constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE table_name = 'team_members' 
AND constraint_name = 'team_members_role_check';

-- Show all tables that exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('projects', 'teams', 'team_members')
ORDER BY table_name;

-- =============================================
-- FIX COMPLETE!
-- =============================================
-- After running this script:
-- 1. The role constraint will allow 'owner' role
-- 2. Project creation should work without team_members errors
-- 3. Try creating a project again
