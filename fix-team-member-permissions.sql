-- Fix for team_members foreign key constraint error
-- This script updates the add_project_owner_to_team function to properly handle profile_id

-- Drop the existing function and trigger if they exist
DROP TRIGGER IF EXISTS add_project_owner_to_team_trigger ON public.teams;
DROP FUNCTION IF EXISTS public.add_project_owner_to_team();

-- Create the corrected function
CREATE OR REPLACE FUNCTION public.add_project_owner_to_team()
RETURNS TRIGGER AS $$
DECLARE
  owner_profile_id UUID;
BEGIN
  -- Get the profile_id for the user
  SELECT id INTO owner_profile_id 
  FROM public.profiles 
  WHERE id = NEW.created_by;
  
  -- Only insert if profile exists
  IF owner_profile_id IS NOT NULL THEN
    INSERT INTO public.team_members (team_id, profile_id, role)
    VALUES (NEW.id, owner_profile_id, 'owner');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER add_project_owner_to_team_trigger
  AFTER INSERT ON public.teams
  FOR EACH ROW EXECUTE FUNCTION public.add_project_owner_to_team();

-- Grant permissions for teams and team_members tables
GRANT ALL ON public.teams TO authenticated;
GRANT ALL ON public.team_members TO authenticated;