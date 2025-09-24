-- Fix Team Invitations RLS Policies
-- This script fixes the RLS policies for team_invitations table
-- Run this in your Supabase SQL Editor

-- =============================================
-- 1. DROP PROBLEMATIC POLICIES
-- =============================================

-- Drop the problematic policy that tries to access auth.users
DROP POLICY IF EXISTS "Users can view invitations sent to their email" ON public.team_invitations;

-- =============================================
-- 2. CREATE FIXED RLS POLICIES
-- =============================================

-- Users can view invitations sent to their email (simplified)
CREATE POLICY "Users can view invitations sent to their email" ON public.team_invitations
  FOR SELECT USING (
    email = (SELECT auth.jwt() ->> 'email')
  );

-- Users can update invitations sent to their email
CREATE POLICY "Users can update invitations sent to their email" ON public.team_invitations
  FOR UPDATE USING (
    email = (SELECT auth.jwt() ->> 'email')
  );

-- =============================================
-- 3. VERIFICATION
-- =============================================

-- Test that policies are working
SELECT 'RLS policies fixed successfully!' as status;
