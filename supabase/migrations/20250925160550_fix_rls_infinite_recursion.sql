-- Fix infinite recursion in RLS policies
-- This migration resolves the circular dependency issue in team_members policies

-- =============================================================================
-- 1. DROP PROBLEMATIC POLICIES
-- =============================================================================

-- Drop the policies that are causing infinite recursion
DROP POLICY IF EXISTS "Users can view team members of teams they created" ON team_members;
DROP POLICY IF EXISTS "Users can view themselves as team members" ON team_members;
DROP POLICY IF EXISTS "Team owners can add members" ON team_members;
DROP POLICY IF EXISTS "Users can leave teams" ON team_members;
DROP POLICY IF EXISTS "Team owners can remove members" ON team_members;

-- Also drop the problematic projects policy that might be causing issues
DROP POLICY IF EXISTS "Users can view projects they are team members of" ON projects;

-- =============================================================================
-- 2. CREATE SIMPLIFIED, NON-RECURSIVE POLICIES
-- =============================================================================

-- Projects: Users can view their own projects only (simplified to avoid recursion)
CREATE POLICY "Users can view their own projects only" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Team Members: Simplified policies that don't create circular dependencies

-- Users can view team members where they are the user_id (themselves)
CREATE POLICY "Users can view their own team memberships" ON team_members
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert themselves into teams (for invitation acceptance)
CREATE POLICY "Users can join teams" ON team_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can remove themselves from teams (leave teams)
CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 3. CREATE HELPER FUNCTIONS FOR TEAM ACCESS
-- =============================================================================

-- Create a function to check if user is team owner (avoids policy recursion)
CREATE OR REPLACE FUNCTION is_team_owner(user_id_param UUID, team_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND created_by = user_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if user is team member (avoids policy recursion)
CREATE OR REPLACE FUNCTION is_team_member(user_id_param UUID, team_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM team_members 
        WHERE team_id = team_id_param 
        AND user_id = user_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 4. ADD MORE PERMISSIVE POLICIES FOR TEAM OWNERS (USING FUNCTIONS)
-- =============================================================================

-- Team owners can view all members of their teams (using function to avoid recursion)
CREATE POLICY "Team owners can view their team members" ON team_members
    FOR SELECT USING (
        is_team_owner(auth.uid(), team_id)
    );

-- Team owners can add members to their teams (using function to avoid recursion)
CREATE POLICY "Team owners can add members to their teams" ON team_members
    FOR INSERT WITH CHECK (
        is_team_owner(auth.uid(), team_id)
    );

-- Team owners can remove members from their teams (using function to avoid recursion)
CREATE POLICY "Team owners can remove members from their teams" ON team_members
    FOR DELETE USING (
        is_team_owner(auth.uid(), team_id)
    );

-- =============================================================================
-- 5. GRANT PERMISSIONS ON HELPER FUNCTIONS
-- =============================================================================

GRANT EXECUTE ON FUNCTION is_team_owner(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_team_member(UUID, UUID) TO authenticated;
