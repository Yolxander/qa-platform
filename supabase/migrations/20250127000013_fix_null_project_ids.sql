-- Fix existing invitations with null project_id
-- This migration updates existing invitations to have the correct project_id from their team

UPDATE team_invitations 
SET project_id = teams.project_id
FROM teams 
WHERE team_invitations.team_id = teams.id 
AND team_invitations.project_id IS NULL;
