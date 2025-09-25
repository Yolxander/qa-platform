-- Fix projects RLS to allow team members to view projects they're invited to
-- This migration adds a policy that allows users to view projects where they are team members

-- Add a policy that allows users to view projects where they are team members
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
