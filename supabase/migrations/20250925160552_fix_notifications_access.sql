-- Fix notifications access by updating RLS policies
-- This migration properly handles existing policies and adds necessary permissions

-- =============================================================================
-- 1. DROP DUPLICATE AND PROBLEMATIC POLICIES
-- =============================================================================

-- Drop duplicate policies
DROP POLICY IF EXISTS "Users can view their own projects only" ON projects;
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;

-- =============================================================================
-- 2. CREATE CORRECTED PROJECT POLICIES
-- =============================================================================

-- Users can view their own projects
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Users can view project names for projects they have invitations to
CREATE POLICY "Users can view project names for their invitations" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.project_id = projects.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- Users can view project names for projects they are team members of
CREATE POLICY "Users can view project names for their team projects" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

-- =============================================================================
-- 3. CREATE CORRECTED PROFILE POLICIES
-- =============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can view inviter profiles for their invitations
CREATE POLICY "Users can view inviter profiles for their invitations" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.invited_by = profiles.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- Users can view team member profiles
CREATE POLICY "Users can view team member profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm1
            JOIN team_members tm2 ON tm1.team_id = tm2.team_id
            WHERE tm1.user_id = auth.uid()
            AND tm2.user_id = profiles.id
        )
    );
