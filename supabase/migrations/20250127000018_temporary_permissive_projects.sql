-- Temporarily allow all authenticated users to view projects
-- This is a temporary fix to resolve the 403 errors

-- Drop the complex policy that might be causing issues
DROP POLICY IF EXISTS "Users can view projects with their invitations" ON projects;

-- Create a simple policy that allows all authenticated users to view projects
CREATE POLICY "Authenticated users can view all projects" ON projects
    FOR SELECT USING (auth.uid() IS NOT NULL);
