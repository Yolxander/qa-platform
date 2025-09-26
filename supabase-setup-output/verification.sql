-- Verification Script for Smasher Light Setup
-- Run this to verify that all tables, functions, and policies are properly set up

-- Check if all tables exist
SELECT 
  'Tables Check' as check_type,
  CASE 
    WHEN COUNT(*) = 8 THEN 'PASS' 
    ELSE 'FAIL - Expected 8 tables, found ' || COUNT(*) 
  END as result
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('projects', 'teams', 'team_members', 'team_invitations', 'bugs', 'todos', 'bug_images', 'profiles');

-- Check if all functions exist
SELECT 
  'Functions Check' as check_type,
  CASE 
    WHEN COUNT(*) >= 5 THEN 'PASS' 
    ELSE 'FAIL - Expected at least 5 functions, found ' || COUNT(*) 
  END as result
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';

-- Check if RLS is enabled on all tables
SELECT 
  'RLS Check' as check_type,
  CASE 
    WHEN COUNT(*) = 8 THEN 'PASS' 
    ELSE 'FAIL - Expected 8 tables with RLS enabled, found ' || COUNT(*) 
  END as result
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
AND c.relname IN ('projects', 'teams', 'team_members', 'team_invitations', 'bugs', 'todos', 'bug_images', 'profiles')
AND c.relrowsecurity = true;

-- Check storage bucket
SELECT 
  'Storage Check' as check_type,
  CASE 
    WHEN COUNT(*) = 1 THEN 'PASS' 
    ELSE 'FAIL - Expected 1 storage bucket, found ' || COUNT(*) 
  END as result
FROM storage.buckets 
WHERE id = 'bug-images';

-- Summary
SELECT 'Setup Verification Complete' as status;
