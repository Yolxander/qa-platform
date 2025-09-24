-- Complete Database Schema for Smasher Light
-- This file contains all the database schemas, tables, policies, and functions
-- Run this file to set up the complete database structure

-- =============================================
-- 1. CORE TABLES
-- =============================================

-- Create profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create projects table
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bugs table
CREATE TABLE IF NOT EXISTS public.bugs (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  severity TEXT CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')) NOT NULL,
  status TEXT CHECK (status IN ('Open', 'In Progress', 'Closed', 'Ready for QA')) NOT NULL DEFAULT 'Open',
  environment TEXT CHECK (environment IN ('Prod', 'Stage', 'Dev')) NOT NULL,
  reporter TEXT NOT NULL,
  assignee TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create todos table
CREATE TABLE IF NOT EXISTS public.todos (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  issue_link TEXT,
  status TEXT CHECK (status IN ('OPEN', 'IN_PROGRESS', 'DONE', 'READY_FOR_QA')) NOT NULL DEFAULT 'OPEN',
  severity TEXT CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')) NOT NULL,
  due_date TEXT NOT NULL,
  environment TEXT CHECK (environment IN ('Prod', 'Stage', 'Dev')) NOT NULL,
  assignee TEXT NOT NULL,
  quick_action TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create teams table
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create team_members junction table
CREATE TABLE IF NOT EXISTS public.team_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'developer' CHECK (role IN ('developer', 'tester', 'guest')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, profile_id)
);

-- =============================================
-- 2. INDEXES FOR PERFORMANCE
-- =============================================

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_bugs_project_id ON public.bugs(project_id);
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON public.todos(project_id);
CREATE INDEX IF NOT EXISTS idx_bugs_user_id ON public.bugs(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS idx_teams_project_id ON public.teams(project_id);
CREATE INDEX IF NOT EXISTS idx_teams_created_by ON public.teams(created_by);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_profile_id ON public.team_members(profile_id);

-- =============================================
-- 3. ROW LEVEL SECURITY
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 4. RLS POLICIES
-- =============================================

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Projects policies
CREATE POLICY "Users can view own projects" ON public.projects
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own projects" ON public.projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects" ON public.projects
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects" ON public.projects
  FOR DELETE USING (auth.uid() = user_id);

-- Bugs policies
CREATE POLICY "Users can view bugs in their projects" ON public.bugs
  FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = bugs.project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert bugs" ON public.bugs
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND (
      project_id IS NULL OR 
      EXISTS (
        SELECT 1 FROM public.projects 
        WHERE projects.id = bugs.project_id 
        AND projects.user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can update own bugs" ON public.bugs
  FOR UPDATE USING (
    auth.uid() = user_id AND (
      project_id IS NULL OR 
      EXISTS (
        SELECT 1 FROM public.projects 
        WHERE projects.id = bugs.project_id 
        AND projects.user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can delete own bugs" ON public.bugs
  FOR DELETE USING (
    auth.uid() = user_id AND (
      project_id IS NULL OR 
      EXISTS (
        SELECT 1 FROM public.projects 
        WHERE projects.id = bugs.project_id 
        AND projects.user_id = auth.uid()
      )
    )
  );

-- Todos policies
CREATE POLICY "Users can view todos in their projects" ON public.todos
  FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = todos.project_id 
      AND projects.user_id = auth.uid()
    )
  );

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

-- Teams policies
CREATE POLICY "Users can view teams in their projects" ON public.teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = teams.project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create teams in their projects" ON public.teams
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update teams in their projects" ON public.teams
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = teams.project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete teams in their projects" ON public.teams
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.projects 
      WHERE projects.id = teams.project_id 
      AND projects.user_id = auth.uid()
    )
  );

-- Team members policies
CREATE POLICY "Users can view team members in their project teams" ON public.team_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can add team members to their project teams" ON public.team_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update team members in their project teams" ON public.team_members
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can remove team members from their project teams" ON public.team_members
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.projects ON projects.id = teams.project_id
      WHERE teams.id = team_members.team_id 
      AND projects.user_id = auth.uid()
    )
  );

-- =============================================
-- 5. FUNCTIONS
-- =============================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, avatar_url)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'avatar_url');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically set project_id for new bugs if not provided
CREATE OR REPLACE FUNCTION public.set_default_project_for_bug()
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

-- Function to automatically set project_id for new todos if not provided
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

-- =============================================
-- 6. TRIGGERS
-- =============================================

-- Trigger for new user registration
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_bugs_updated_at
  BEFORE UPDATE ON public.bugs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_todos_updated_at
  BEFORE UPDATE ON public.todos
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Triggers for automatic project assignment
CREATE TRIGGER set_default_project_for_bug_trigger
  BEFORE INSERT ON public.bugs
  FOR EACH ROW EXECUTE FUNCTION public.set_default_project_for_bug();

CREATE TRIGGER set_default_project_for_todo_trigger
  BEFORE INSERT ON public.todos
  FOR EACH ROW EXECUTE FUNCTION public.set_default_project_for_todo();

-- =============================================
-- 7. PERMISSIONS
-- =============================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.projects TO authenticated;
GRANT ALL ON public.bugs TO authenticated;
GRANT ALL ON public.todos TO authenticated;

-- =============================================
-- 8. COMMENTS
-- =============================================

-- Add comments for documentation
COMMENT ON COLUMN public.bugs.project_id IS 'Foreign key reference to projects table. Links bugs to specific projects.';
COMMENT ON COLUMN public.todos.project_id IS 'Foreign key reference to projects table. Links todos to specific projects.';
COMMENT ON TABLE public.projects IS 'Projects table for organizing bugs and todos by project.';
COMMENT ON TABLE public.bugs IS 'Bug reports and issue tracking table.';
COMMENT ON TABLE public.todos IS 'Task management and todo items table.';
