-- Complete Todo Management Schema
-- This file includes all necessary tables for the todo management system

-- =============================================
-- 1. Projects Table (if not exists)
-- =============================================
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 2. Teams Table (if not exists)
-- =============================================
CREATE TABLE IF NOT EXISTS teams (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 3. Team Members Table (if not exists)
-- =============================================
CREATE TABLE IF NOT EXISTS team_members (
    id SERIAL PRIMARY KEY,
    team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- =============================================
-- 4. Profiles Table (if not exists)
-- =============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    email VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 5. Bugs Table (if not exists)
-- =============================================
CREATE TABLE IF NOT EXISTS bugs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(20) NOT NULL DEFAULT 'Open',
    environment VARCHAR(20) NOT NULL DEFAULT 'Dev',
    assignee VARCHAR(255),
    reporter_id UUID NOT NULL REFERENCES auth.users(id),
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 6. Todos Table (if not exists)
-- =============================================
CREATE TABLE IF NOT EXISTS todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    issue_link VARCHAR(255),
    severity VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    environment VARCHAR(20) NOT NULL DEFAULT 'Dev',
    assignee VARCHAR(255),
    due_date VARCHAR(50) NOT NULL DEFAULT 'Today',
    quick_action VARCHAR(50) NOT NULL DEFAULT 'Start',
    user_id UUID NOT NULL REFERENCES auth.users(id),
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 7. Todo Time Entries Table
-- =============================================
CREATE TABLE IF NOT EXISTS todo_time_entries (
    id SERIAL PRIMARY KEY,
    todo_id INTEGER NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Projects indexes
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects(created_by);

-- Teams indexes
CREATE INDEX IF NOT EXISTS idx_teams_project_id ON teams(project_id);

-- Team members indexes
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);

-- Bugs indexes
CREATE INDEX IF NOT EXISTS idx_bugs_project_id ON bugs(project_id);
CREATE INDEX IF NOT EXISTS idx_bugs_reporter_id ON bugs(reporter_id);
CREATE INDEX IF NOT EXISTS idx_bugs_status ON bugs(status);
CREATE INDEX IF NOT EXISTS idx_bugs_severity ON bugs(severity);

-- Todos indexes
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON todos(project_id);
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_status ON todos(status);
CREATE INDEX IF NOT EXISTS idx_todos_severity ON todos(severity);
CREATE INDEX IF NOT EXISTS idx_todos_assignee ON todos(assignee);

-- Time entries indexes
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_todo_id ON todo_time_entries(todo_id);
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_project_id ON todo_time_entries(project_id);
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_user_id ON todo_time_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_created_at ON todo_time_entries(created_at);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- Enable RLS on all tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo_time_entries ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS POLICIES
-- =============================================

-- Projects policies
CREATE POLICY "Users can view projects they're members of" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

CREATE POLICY "Users can create projects" ON projects
    FOR INSERT WITH CHECK (created_by = auth.uid());

-- Teams policies
CREATE POLICY "Users can view teams for their projects" ON teams
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            WHERE tm.team_id = teams.id
            AND tm.user_id = auth.uid()
        )
    );

-- Team members policies
CREATE POLICY "Users can view team members for their teams" ON team_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm2
            WHERE tm2.team_id = team_members.team_id
            AND tm2.user_id = auth.uid()
        )
    );

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (id = auth.uid());

-- Bugs policies
CREATE POLICY "Users can view bugs for their projects" ON bugs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = bugs.project_id
        )
    );

CREATE POLICY "Users can create bugs for their projects" ON bugs
    FOR INSERT WITH CHECK (
        reporter_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = bugs.project_id
        )
    );

-- Todos policies
CREATE POLICY "Users can view todos for their projects" ON todos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todos.project_id
        )
    );

CREATE POLICY "Users can create todos for their projects" ON todos
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todos.project_id
        )
    );

CREATE POLICY "Users can update todos for their projects" ON todos
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todos.project_id
        )
    );

CREATE POLICY "Users can delete todos for their projects" ON todos
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todos.project_id
        )
    );

-- Time entries policies
CREATE POLICY "Users can view time entries for their projects" ON todo_time_entries
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todo_time_entries.project_id
        )
    );

CREATE POLICY "Users can insert time entries for their projects" ON todo_time_entries
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todo_time_entries.project_id
        )
    );

CREATE POLICY "Users can update their own time entries" ON todo_time_entries
    FOR UPDATE USING (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todo_time_entries.project_id
        )
    );

CREATE POLICY "Users can delete their own time entries" ON todo_time_entries
    FOR DELETE USING (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todo_time_entries.project_id
        )
    );

-- =============================================
-- TRIGGERS FOR UPDATED_AT
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables with updated_at
CREATE TRIGGER trigger_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_bugs_updated_at
    BEFORE UPDATE ON bugs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_todos_updated_at
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_todo_time_entries_updated_at
    BEFORE UPDATE ON todo_time_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================

COMMENT ON TABLE projects IS 'Projects that contain todos and bugs';
COMMENT ON TABLE teams IS 'Teams within projects';
COMMENT ON TABLE team_members IS 'Members of teams with roles';
COMMENT ON TABLE profiles IS 'User profile information';
COMMENT ON TABLE bugs IS 'Bug reports and issues';
COMMENT ON TABLE todos IS 'Todo items and tasks';
COMMENT ON TABLE todo_time_entries IS 'Time tracking entries for todos';

COMMENT ON COLUMN todo_time_entries.duration_seconds IS 'Time spent in seconds';
COMMENT ON COLUMN todo_time_entries.notes IS 'Optional notes about the work done';

