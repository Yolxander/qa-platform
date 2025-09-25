-- Fix circular dependency in teams RLS policies
-- This migration simplifies the RLS policies to avoid circular references

-- Drop all existing policies that cause circular dependencies
DROP POLICY IF EXISTS "Project owners can create teams" ON teams;
DROP POLICY IF EXISTS "Team owners can update teams" ON teams;
DROP POLICY IF EXISTS "Team owners can delete teams" ON teams;
DROP POLICY IF EXISTS "Users can view teams they created or are members of" ON teams;

DROP POLICY IF EXISTS "Team owners can add members" ON team_members;
DROP POLICY IF EXISTS "Users can leave teams" ON team_members;
DROP POLICY IF EXISTS "Users can view team members if they're in the team or created it" ON team_members;

-- Create simplified policies that avoid circular dependencies

-- Teams policies - simplified to avoid circular references
CREATE POLICY "Users can create teams for their own projects" ON teams
    FOR INSERT WITH CHECK (
        auth.uid() = created_by
    );

CREATE POLICY "Users can view teams they created" ON teams
    FOR SELECT USING (auth.uid() = created_by);

CREATE POLICY "Users can update teams they created" ON teams
    FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Users can delete teams they created" ON teams
    FOR DELETE USING (auth.uid() = created_by);

-- Team members policies - simplified to avoid circular references
CREATE POLICY "Users can add members to teams they created" ON team_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

CREATE POLICY "Users can view team members of teams they created" ON team_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);
