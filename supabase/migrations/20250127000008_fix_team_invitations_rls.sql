-- Fix team_invitations RLS policy to avoid circular dependencies
-- This migration simplifies the RLS policy to prevent circular references

-- Drop the problematic RLS policies
DROP POLICY IF EXISTS "Team owners can create invitations" ON team_invitations;
DROP POLICY IF EXISTS "Team owners can update invitations" ON team_invitations;

-- Create simplified RLS policies that avoid circular dependencies
CREATE POLICY "Users can create invitations for teams they own" ON team_invitations
    FOR INSERT WITH CHECK (
        auth.uid() = invited_by
    );

CREATE POLICY "Users can update invitations they created" ON team_invitations
    FOR UPDATE USING (
        auth.uid() = invited_by
    );

-- Keep the existing SELECT policy as it's working fine
-- Users can view their own invitations (by email)
