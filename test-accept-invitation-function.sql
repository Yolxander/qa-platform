-- Test Accept Team Invitation Function
-- This script helps test the updated accept_team_invitation function
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. VERIFY FUNCTION EXISTS
-- =============================================

-- Check if the function exists and get its definition
SELECT 
  routine_name, 
  routine_type,
  routine_definition 
FROM information_schema.routines 
WHERE routine_name = 'accept_team_invitation' 
AND routine_schema = 'public';

-- =============================================
-- 2. VERIFY TEAM_INVITATIONS TABLE STRUCTURE
-- =============================================

-- Check if team_invitations table has team_id column
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'team_invitations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =============================================
-- 3. CHECK SAMPLE INVITATION DATA
-- =============================================

-- View recent invitations to see the structure
SELECT 
  id,
  email,
  role,
  project_id,
  team_id,
  status,
  token,
  expires_at,
  created_at
FROM public.team_invitations 
ORDER BY created_at DESC 
LIMIT 5;

-- =============================================
-- 4. VERIFY TEAM_MEMBERS TABLE STRUCTURE
-- =============================================

-- Check team_members table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'team_members' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =============================================
-- 5. CHECK SAMPLE TEAM MEMBERS DATA
-- =============================================

-- View recent team members
SELECT 
  tm.id,
  tm.team_id,
  tm.profile_id,
  tm.role,
  tm.joined_at,
  t.name as team_name,
  t.project_id,
  p.email as user_email
FROM public.team_members tm
JOIN public.teams t ON t.id = tm.team_id
JOIN public.profiles p ON p.id = tm.profile_id
ORDER BY tm.joined_at DESC 
LIMIT 5;

-- =============================================
-- 6. TEST DATA VALIDATION QUERIES
-- =============================================

-- Check if there are any invitations with NULL team_id
SELECT COUNT(*) as invitations_with_null_team_id
FROM public.team_invitations 
WHERE team_id IS NULL;

-- Check if there are any invitations with invalid team_id
SELECT COUNT(*) as invitations_with_invalid_team_id
FROM public.team_invitations ti
LEFT JOIN public.teams t ON t.id = ti.team_id
WHERE ti.team_id IS NOT NULL 
AND t.id IS NULL;

-- Check if there are any invitations where team doesn't belong to project
SELECT COUNT(*) as invitations_with_mismatched_team_project
FROM public.team_invitations ti
JOIN public.teams t ON t.id = ti.team_id
WHERE t.project_id != ti.project_id;
