-- Create todo_time_entries table for tracking time spent on todos
-- This table stores time tracking entries for each todo item

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

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_todo_id ON todo_time_entries(todo_id);
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_project_id ON todo_time_entries(project_id);
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_user_id ON todo_time_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_todo_time_entries_created_at ON todo_time_entries(created_at);

-- Add RLS (Row Level Security) policies
ALTER TABLE todo_time_entries ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see time entries for projects they have access to
CREATE POLICY "Users can view time entries for their projects" ON todo_time_entries
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todo_time_entries.project_id
        )
    );

-- Policy: Users can insert time entries for todos in their projects
CREATE POLICY "Users can insert time entries for their projects" ON todo_time_entries
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = todo_time_entries.project_id
        )
        AND user_id = auth.uid()
    );

-- Policy: Users can update their own time entries
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

-- Policy: Users can delete their own time entries
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

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_todo_time_entries_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_todo_time_entries_updated_at
    BEFORE UPDATE ON todo_time_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_todo_time_entries_updated_at();

-- Add comments for documentation
COMMENT ON TABLE todo_time_entries IS 'Stores time tracking entries for todo items';
COMMENT ON COLUMN todo_time_entries.todo_id IS 'Reference to the todo item';
COMMENT ON COLUMN todo_time_entries.project_id IS 'Reference to the project for RLS';
COMMENT ON COLUMN todo_time_entries.user_id IS 'User who logged the time';
COMMENT ON COLUMN todo_time_entries.duration_seconds IS 'Time spent in seconds';
COMMENT ON COLUMN todo_time_entries.notes IS 'Optional notes about the work done';
COMMENT ON COLUMN todo_time_entries.created_at IS 'When the time entry was created';
COMMENT ON COLUMN todo_time_entries.updated_at IS 'When the time entry was last updated';

