-- Add project_id column to todos table
-- This script adds the project_id foreign key to the todos table and updates RLS policies

-- First, ensure the projects table exists (if not already created)
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on projects table if not already enabled
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for projects if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'projects' AND policyname = 'Users can view own projects'
  ) THEN
    CREATE POLICY "Users can view own projects" ON public.projects
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'projects' AND policyname = 'Users can insert own projects'
  ) THEN
    CREATE POLICY "Users can insert own projects" ON public.projects
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'projects' AND policyname = 'Users can update own projects'
  ) THEN
    CREATE POLICY "Users can update own projects" ON public.projects
      FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'projects' AND policyname = 'Users can delete own projects'
  ) THEN
    CREATE POLICY "Users can delete own projects" ON public.projects
      FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- Create trigger for updated_at on projects if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_projects_updated_at'
  ) THEN
    CREATE TRIGGER update_projects_updated_at
      BEFORE UPDATE ON public.projects
      FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

-- Add project_id column to todos table if it doesn't exist
ALTER TABLE public.todos 
ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;

-- Create index on project_id for better query performance
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON public.todos(project_id);

-- Update existing RLS policy for todos to include project-based access
DROP POLICY IF EXISTS "Users can view all todos" ON public.todos;
DROP POLICY IF EXISTS "Users can view todos in their projects" ON public.todos;

CREATE POLICY "Users can view todos in their projects" ON public.todos
  FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = todos.project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- Update insert policy to allow project-based todos
DROP POLICY IF EXISTS "Users can insert todos" ON public.todos;
CREATE POLICY "Users can insert todos" ON public.todos
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND (
      project_id IS NULL OR 
      EXISTS (
        SELECT 1 FROM public.projects 
        WHERE projects.id = todos.project_id 
        AND projects.user_id = auth.uid()
      )
    )
  );

-- Update update policy to allow project-based todos
DROP POLICY IF EXISTS "Users can update own todos" ON public.todos;
CREATE POLICY "Users can update own todos" ON public.todos
  FOR UPDATE USING (
    auth.uid() = user_id AND (
      project_id IS NULL OR 
      EXISTS (
        SELECT 1 FROM public.projects 
        WHERE projects.id = todos.project_id 
        AND projects.user_id = auth.uid()
      )
    )
  );

-- Update delete policy to allow project-based todos
DROP POLICY IF EXISTS "Users can delete own todos" ON public.todos;
CREATE POLICY "Users can delete own todos" ON public.todos
  FOR DELETE USING (
    auth.uid() = user_id AND (
      project_id IS NULL OR 
      EXISTS (
        SELECT 1 FROM public.projects 
        WHERE projects.id = todos.project_id 
        AND projects.user_id = auth.uid()
      )
    )
  );

-- Add comment to the project_id column for documentation
COMMENT ON COLUMN public.todos.project_id IS 'Foreign key reference to projects table. Links todos to specific projects.';

-- Create a function to automatically set project_id for new todos if not provided
CREATE OR REPLACE FUNCTION public.set_default_project_for_todo()
RETURNS TRIGGER AS $$
BEGIN
  -- If project_id is not provided, try to get the user's default project
  IF NEW.project_id IS NULL THEN
    SELECT id INTO NEW.project_id 
    FROM public.projects 
    WHERE user_id = NEW.user_id 
    ORDER BY created_at ASC 
    LIMIT 1;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically set project_id for new todos
DROP TRIGGER IF EXISTS set_default_project_for_todo_trigger ON public.todos;
CREATE TRIGGER set_default_project_for_todo_trigger
  BEFORE INSERT ON public.todos
  FOR EACH ROW EXECUTE FUNCTION public.set_default_project_for_todo();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.projects TO authenticated;
GRANT ALL ON public.todos TO authenticated;
