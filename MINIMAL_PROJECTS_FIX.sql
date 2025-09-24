-- =============================================
-- MINIMAL PROJECTS FIX - RUN THIS IN SUPABASE SQL EDITOR
-- =============================================
-- This script ONLY adds the projects table and fixes the 400 error
-- It won't conflict with existing tables/policies you already have

-- =============================================
-- 1. CREATE PROJECTS TABLE (THE MAIN FIX)
-- =============================================

-- Create projects table (this fixes the 400 error)
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 2. ENABLE RLS ON PROJECTS TABLE
-- =============================================

-- Enable RLS on projects table
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 3. CREATE PROJECTS RLS POLICIES
-- =============================================

-- Create RLS policies for projects (these are new, won't conflict)
CREATE POLICY "Users can view own projects" ON public.projects
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own projects" ON public.projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects" ON public.projects
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects" ON public.projects
  FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 4. ADD PROJECT_ID COLUMNS TO EXISTING TABLES
-- =============================================

-- Add project_id to existing bugs table (if not already added)
ALTER TABLE public.bugs 
ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;

-- Add project_id to existing todos table (if not already added)
ALTER TABLE public.todos 
ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;

-- =============================================
-- 5. CREATE UPDATED_AT FUNCTION (IF NOT EXISTS)
-- =============================================

-- Create function to update updated_at timestamp (if not exists)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 6. CREATE TRIGGERS FOR PROJECTS
-- =============================================

-- Create trigger for updated_at on projects
CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- 7. CREATE INDEXES FOR PERFORMANCE
-- =============================================

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS idx_bugs_project_id ON public.bugs(project_id);
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON public.todos(project_id);

-- =============================================
-- 8. GRANT PERMISSIONS
-- =============================================

-- Grant necessary permissions for projects table
GRANT ALL ON public.projects TO authenticated;

-- =============================================
-- 9. VERIFICATION
-- =============================================

-- This query will show you that the projects table was created
SELECT 'Projects table created successfully!' as status;

-- Check if projects table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'projects';

-- =============================================
-- SETUP COMPLETE!
-- =============================================
-- After running this script:
-- 1. Restart your development server: npm run dev
-- 2. Try creating a project - the 400 error should be gone!
-- 3. Check browser console for "Project created successfully" message
