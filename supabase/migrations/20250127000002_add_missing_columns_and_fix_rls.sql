-- Add missing columns to bugs table and fix remaining RLS issues
-- This migration adds the missing columns and ensures RLS policies work correctly

-- Add missing columns to bugs table
ALTER TABLE bugs ADD COLUMN IF NOT EXISTS steps_to_reproduce TEXT;
ALTER TABLE bugs ADD COLUMN IF NOT EXISTS url TEXT;

-- The RLS policies should already be fixed, but let's make sure they're correct
-- Drop and recreate the teams policy to ensure it's working correctly
DROP POLICY IF EXISTS "Users can view teams they created or are members of" ON teams;

CREATE POLICY "Users can view teams they created or are members of" ON teams
    FOR SELECT USING (
        auth.uid() = created_by OR 
        EXISTS (
            SELECT 1 FROM team_members tm 
            WHERE tm.team_id = teams.id 
            AND tm.user_id = auth.uid()
        )
    );

-- Also ensure the team_members policy is correct
DROP POLICY IF EXISTS "Users can view team members if they're in the team or created it" ON team_members;

CREATE POLICY "Users can view team members if they're in the team or created it" ON team_members
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );
