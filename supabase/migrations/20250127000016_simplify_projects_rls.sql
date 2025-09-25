-- Simplify projects RLS policies to avoid auth.users table access
-- This migration removes complex policies that cause permission denied errors

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;
DROP POLICY IF EXISTS "Users can create their own projects" ON projects;
DROP POLICY IF EXISTS "Users can update their own projects" ON projects;
DROP POLICY IF EXISTS "Users can delete their own projects" ON projects;
DROP POLICY IF EXISTS "Users can view projects they are team members of" ON projects;
DROP POLICY IF EXISTS "Users can view projects they have invitations for" ON projects;

-- Create simplified policies that don't access auth.users table
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own projects" ON projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects" ON projects
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects" ON projects
    FOR DELETE USING (auth.uid() = user_id);

-- Allow users to view projects where they are team members (simplified)
CREATE POLICY "Users can view projects they are team members of" ON projects
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );
