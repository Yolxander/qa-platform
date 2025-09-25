-- Fix RLS policies for notifications functionality
-- This migration adds the necessary permissions for fetching project and profile names in invitations

-- =============================================================================
-- 1. ADD POLICIES FOR PROJECT NAME ACCESS IN INVITATIONS
-- =============================================================================

-- Allow users to view project names for projects they have invitations to
CREATE POLICY "Users can view project names for their invitations" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.project_id = projects.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- =============================================================================
-- 2. ADD POLICIES FOR PROFILE NAME ACCESS IN INVITATIONS
-- =============================================================================

-- Allow users to view profile names of users who invited them
CREATE POLICY "Users can view inviter profiles for their invitations" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.invited_by = profiles.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- =============================================================================
-- 3. ADD MORE PERMISSIVE POLICIES FOR TEAM COLLABORATION
-- =============================================================================

-- Allow users to view project names for projects they are team members of
CREATE POLICY "Users can view project names for their team projects" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

-- Allow users to view profile names of their team members
CREATE POLICY "Users can view team member profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm1
            JOIN team_members tm2 ON tm1.team_id = tm2.team_id
            WHERE tm1.user_id = auth.uid()
            AND tm2.user_id = profiles.id
        )
    );

-- =============================================================================
-- 4. GRANT ADDITIONAL PERMISSIONS
-- =============================================================================

-- Ensure authenticated users have the necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
