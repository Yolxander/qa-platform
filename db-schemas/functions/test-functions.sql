-- Test Functions
-- Run this in Supabase SQL Editor to test if the functions are working

-- Test 1: Check if get_user_invitations function exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc 
      WHERE proname = 'get_user_invitations' 
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) 
    THEN '✅ get_user_invitations function exists'
    ELSE '❌ get_user_invitations function missing'
  END as function_status;

-- Test 2: Check if create_team_invitation function exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc 
      WHERE proname = 'create_team_invitation' 
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) 
    THEN '✅ create_team_invitation function exists'
    ELSE '❌ create_team_invitation function missing'
  END as function_status;

-- Test 3: Check if accept_team_invitation function exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc 
      WHERE proname = 'accept_team_invitation' 
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) 
    THEN '✅ accept_team_invitation function exists'
    ELSE '❌ accept_team_invitation function missing'
  END as function_status;

-- Test 4: Check if team_invitations table exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'team_invitations'
    ) 
    THEN '✅ team_invitations table exists'
    ELSE '❌ team_invitations table missing'
  END as table_status;

-- Test 5: Check table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'team_invitations'
ORDER BY ordinal_position;
