-- Add a more permissive policy for projects to allow invitation access
-- This migration adds a policy that allows users to view projects they have invitations for

-- Add policy for invitation access (simplified approach)
CREATE POLICY "Users can view projects with their invitations" ON projects
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM team_invitations ti
            JOIN teams t ON t.id = ti.team_id
            WHERE ti.email = (SELECT email FROM auth.users WHERE id = auth.uid())
            AND ti.status = 'pending'
            AND t.project_id = projects.id
        )
    );
