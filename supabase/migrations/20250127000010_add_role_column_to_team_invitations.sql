-- Add missing role column to team_invitations table
-- This migration adds the role column that the create_team_invitation function expects

ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'member';
