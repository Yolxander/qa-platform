-- Comprehensive RLS policies migration
-- This migration creates all necessary Row Level Security policies for proper data access control

-- =============================================================================
-- 1. CLEAN UP EXISTING POLICIES (SAFE CLEANUP)
-- =============================================================================

-- Drop all existing policies to start fresh (safe because we'll recreate them)
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;
DROP POLICY IF EXISTS "Users can create their own projects" ON projects;
DROP POLICY IF EXISTS "Users can update their own projects" ON projects;
DROP POLICY IF EXISTS "Users can delete their own projects" ON projects;

DROP POLICY IF EXISTS "Users can view teams they created or are members of" ON teams;
DROP POLICY IF EXISTS "Project owners can create teams" ON teams;
DROP POLICY IF EXISTS "Team owners can update teams" ON teams;
DROP POLICY IF EXISTS "Team owners can delete teams" ON teams;
DROP POLICY IF EXISTS "Users can view teams in their projects" ON teams;

DROP POLICY IF EXISTS "Users can view team members if they're in the team or created it" ON team_members;
DROP POLICY IF EXISTS "Team owners can add members" ON team_members;
DROP POLICY IF EXISTS "Users can leave teams" ON team_members;
DROP POLICY IF EXISTS "Users can view team members in their teams" ON team_members;

DROP POLICY IF EXISTS "Users can view their own invitations" ON team_invitations;
DROP POLICY IF EXISTS "Team owners can create invitations" ON team_invitations;
DROP POLICY IF EXISTS "Team owners can update invitations" ON team_invitations;

DROP POLICY IF EXISTS "Users can view all bugs" ON bugs;
DROP POLICY IF EXISTS "Users can create bugs" ON bugs;
DROP POLICY IF EXISTS "Users can update their own bugs" ON bugs;
DROP POLICY IF EXISTS "Users can delete their own bugs" ON bugs;

DROP POLICY IF EXISTS "Users can view all todos" ON todos;
DROP POLICY IF EXISTS "Users can create todos" ON todos;
DROP POLICY IF EXISTS "Users can update their own todos" ON todos;
DROP POLICY IF EXISTS "Users can delete their own todos" ON todos;

DROP POLICY IF EXISTS "Users can view bug images" ON bug_images;
DROP POLICY IF EXISTS "Users can upload bug images" ON bug_images;
DROP POLICY IF EXISTS "Users can delete their own bug images" ON bug_images;

-- =============================================================================
-- 2. PROJECTS TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own projects
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Users can view projects they are team members of
CREATE POLICY "Users can view projects they are team members of" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

-- Users can create their own projects
CREATE POLICY "Users can create their own projects" ON projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own projects
CREATE POLICY "Users can update their own projects" ON projects
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own projects
CREATE POLICY "Users can delete their own projects" ON projects
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 3. TEAMS TABLE RLS POLICIES
-- =============================================================================

-- Users can view teams they created
CREATE POLICY "Users can view teams they created" ON teams
    FOR SELECT USING (auth.uid() = created_by);

-- Users can view teams they are members of
CREATE POLICY "Users can view teams they are members of" ON teams
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm 
            WHERE tm.team_id = teams.id 
            AND tm.user_id = auth.uid()
        )
    );

-- Project owners can create teams for their projects
CREATE POLICY "Project owners can create teams" ON teams
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        auth.uid() IN (
            SELECT user_id FROM projects WHERE id = project_id
        )
    );

-- Team owners can update teams they created
CREATE POLICY "Team owners can update teams" ON teams
    FOR UPDATE USING (auth.uid() = created_by);

-- Team owners can delete teams they created
CREATE POLICY "Team owners can delete teams" ON teams
    FOR DELETE USING (auth.uid() = created_by);

-- =============================================================================
-- 4. TEAM_MEMBERS TABLE RLS POLICIES
-- =============================================================================

-- Users can view team members of teams they created
CREATE POLICY "Users can view team members of teams they created" ON team_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

-- Users can view themselves as team members
CREATE POLICY "Users can view themselves as team members" ON team_members
    FOR SELECT USING (auth.uid() = user_id);

-- Team owners can add members to their teams
CREATE POLICY "Team owners can add members" ON team_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

-- Users can leave teams (delete themselves)
CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);

-- Team owners can remove members from their teams
CREATE POLICY "Team owners can remove members" ON team_members
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

-- =============================================================================
-- 5. TEAM_INVITATIONS TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own invitations
CREATE POLICY "Users can view their own invitations" ON team_invitations
    FOR SELECT USING (email = auth.jwt() ->> 'email');

-- Team owners can create invitations for their teams
CREATE POLICY "Team owners can create invitations" ON team_invitations
    FOR INSERT WITH CHECK (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Team owners can update invitations for their teams
CREATE POLICY "Team owners can update invitations" ON team_invitations
    FOR UPDATE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Team owners can delete invitations for their teams
CREATE POLICY "Team owners can delete invitations" ON team_invitations
    FOR DELETE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- =============================================================================
-- 6. BUGS TABLE RLS POLICIES
-- =============================================================================

-- Users can view all bugs (for collaboration)
CREATE POLICY "Users can view all bugs" ON bugs
    FOR SELECT USING (true);

-- Users can create bugs
CREATE POLICY "Users can create bugs" ON bugs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own bugs
CREATE POLICY "Users can update their own bugs" ON bugs
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own bugs
CREATE POLICY "Users can delete their own bugs" ON bugs
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 7. TODOS TABLE RLS POLICIES
-- =============================================================================

-- Users can view all todos (for collaboration)
CREATE POLICY "Users can view all todos" ON todos
    FOR SELECT USING (true);

-- Users can create todos
CREATE POLICY "Users can create todos" ON todos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own todos
CREATE POLICY "Users can update their own todos" ON todos
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own todos
CREATE POLICY "Users can delete their own todos" ON todos
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 8. BUG_IMAGES TABLE RLS POLICIES
-- =============================================================================

-- Users can view bug images for bugs they can access
CREATE POLICY "Users can view bug images" ON bug_images
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM bugs WHERE id = bug_id
        )
    );

-- Users can upload bug images for their own bugs
CREATE POLICY "Users can upload bug images" ON bug_images
    FOR INSERT WITH CHECK (
        auth.uid() = uploaded_by AND
        auth.uid() IN (
            SELECT user_id FROM bugs WHERE id = bug_id
        )
    );

-- Users can delete their own bug images
CREATE POLICY "Users can delete their own bug images" ON bug_images
    FOR DELETE USING (auth.uid() = uploaded_by);

-- =============================================================================
-- 9. PROFILES TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can view profiles of team members in their projects
CREATE POLICY "Users can view team member profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id IN (
                SELECT p.id FROM projects p
                WHERE p.user_id = auth.uid()
            )
            AND profiles.id = tm.user_id
        )
    );

-- =============================================================================
-- 10. ADDITIONAL SECURITY MEASURES
-- =============================================================================

-- Ensure all tables have RLS enabled
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 11. GRANT NECESSARY PERMISSIONS
-- =============================================================================

-- Grant necessary permissions for authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Ensure RLS is properly configured
-- (This is already done above, but being explicit)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
