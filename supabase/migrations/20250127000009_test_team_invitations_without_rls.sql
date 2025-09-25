-- Temporarily disable RLS on team_invitations to test if that's the issue
-- This is for debugging purposes only

-- Disable RLS temporarily
ALTER TABLE team_invitations DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS with a simple policy
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;

-- Create a very simple policy that allows all authenticated users
CREATE POLICY "Allow all authenticated users" ON team_invitations
    FOR ALL USING (auth.uid() IS NOT NULL);
