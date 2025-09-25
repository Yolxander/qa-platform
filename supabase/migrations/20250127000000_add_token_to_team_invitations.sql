-- Add token column to team_invitations table
-- This column is required for the invitation system to work properly

-- Add token column to team_invitations table
ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS token TEXT UNIQUE;

-- Create index for better performance on token lookups
CREATE INDEX IF NOT EXISTS idx_team_invitations_token ON team_invitations(token);

-- Update existing invitations to have tokens (if any exist)
-- Generate random tokens for existing invitations that don't have them
UPDATE team_invitations 
SET token = encode(gen_random_bytes(32), 'base64')
WHERE token IS NULL;
