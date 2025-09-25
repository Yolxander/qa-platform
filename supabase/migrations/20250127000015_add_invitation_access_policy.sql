-- Add policy to allow users to view projects they have pending invitations for
-- This migration allows users to see project names for invitations they've received

CREATE POLICY "Users can view projects they have invitations for" ON projects
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        ) OR
        EXISTS (
            SELECT 1 FROM team_invitations ti
            JOIN teams t ON t.id = ti.team_id
            WHERE ti.email = (SELECT email FROM auth.users WHERE id = auth.uid())
            AND ti.status = 'pending'
            AND t.project_id = projects.id
        )
    );
