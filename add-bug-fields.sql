-- Add new fields to bugs table for URL of Occurrence and Steps to Reproduce
-- Run this migration to add the new columns to the bugs table

-- Add URL of Occurrence field
ALTER TABLE public.bugs 
ADD COLUMN IF NOT EXISTS url TEXT;

-- Add Steps to Reproduce field  
ALTER TABLE public.bugs 
ADD COLUMN IF NOT EXISTS steps_to_reproduce TEXT;

-- Add comments for documentation
COMMENT ON COLUMN public.bugs.url IS 'URL where the bug was encountered';
COMMENT ON COLUMN public.bugs.steps_to_reproduce IS 'Detailed steps to reproduce the bug';
