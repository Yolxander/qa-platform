-- Quick Fix - Just Drop Problematic Policies
-- This script only drops the policies causing infinite recursion

-- Drop the specific policy causing infinite recursion
DROP POLICY IF EXISTS "Users can access projects from their teams" ON public.projects;

-- That's it! The basic policies should remain and work correctly
-- The database functions will handle the security for member teams and projects
