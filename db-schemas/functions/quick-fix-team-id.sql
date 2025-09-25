-- Quick fix: Add team_id column to team_invitations table
-- Run this first to fix the immediate error

-- Add the team_id column
ALTER TABLE public.team_invitations 
ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE;

-- Create index for the new column
CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON public.team_invitations(team_id);

-- Add comment
COMMENT ON COLUMN public.team_invitations.team_id IS 'Foreign key reference to teams table';
