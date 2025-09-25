-- Safe migration to fix bug images and comments functionality
-- This migration handles existing tables and avoids conflicts

-- =============================================================================
-- 1. FIX BUG_IMAGES TABLE SCHEMA (if it exists with wrong columns)
-- =============================================================================

-- Check if bug_images table exists and has wrong column names, then recreate
DO $$
BEGIN
    -- If the table exists with old column names, drop and recreate
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bug_images' 
        AND column_name = 'image_url'
    ) THEN
        DROP TABLE IF EXISTS bug_images CASCADE;
        
        -- Create bug_images table with correct schema
        CREATE TABLE bug_images (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
            url TEXT NOT NULL,
            name VARCHAR(255),
            size INTEGER,
            path TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_bug_images_bug_id ON bug_images(bug_id);
        CREATE INDEX IF NOT EXISTS idx_bug_images_created_at ON bug_images(created_at);
        
        -- Enable RLS
        ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;
        
        -- Create RLS policies
        CREATE POLICY "Users can view bug images" ON bug_images
        FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM bugs b
                JOIN projects p ON b.project_id = p.id
                WHERE b.id = bug_images.bug_id
                AND (p.user_id = auth.uid() OR EXISTS (
                    SELECT 1 FROM team_members tm
                    JOIN teams t ON tm.team_id = t.id
                    WHERE t.project_id = p.id
                    AND tm.user_id = auth.uid()
                ))
            )
        );

        CREATE POLICY "Users can upload bug images" ON bug_images
        FOR INSERT
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM bugs b
                JOIN projects p ON b.project_id = p.id
                WHERE b.id = bug_images.bug_id
                AND (p.user_id = auth.uid() OR EXISTS (
                    SELECT 1 FROM team_members tm
                    JOIN teams t ON tm.team_id = t.id
                    WHERE t.project_id = p.id
                    AND tm.user_id = auth.uid()
                ))
            )
        );

        CREATE POLICY "Users can delete bug images" ON bug_images
        FOR DELETE
        USING (
            EXISTS (
                SELECT 1 FROM bugs b
                JOIN projects p ON b.project_id = p.id
                WHERE b.id = bug_images.bug_id
                AND (p.user_id = auth.uid() OR EXISTS (
                    SELECT 1 FROM team_members tm
                    JOIN teams t ON tm.team_id = t.id
                    WHERE t.project_id = p.id
                    AND tm.user_id = auth.uid()
                ))
            )
        );
    END IF;
END $$;

-- =============================================================================
-- 2. CREATE BUG_COMMENTS TABLE (if it doesn't exist)
-- =============================================================================

-- Create bug_comments table if it doesn't exist
CREATE TABLE IF NOT EXISTS bug_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
    author VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    attachments TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_bug_comments_bug_id ON bug_comments(bug_id);
CREATE INDEX IF NOT EXISTS idx_bug_comments_created_at ON bug_comments(created_at);

-- Enable RLS if not already enabled
ALTER TABLE bug_comments ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 3. CREATE RLS POLICIES FOR BUG_COMMENTS (drop first to avoid conflicts)
-- =============================================================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view bug comments" ON bug_comments;
DROP POLICY IF EXISTS "Users can create bug comments" ON bug_comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON bug_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON bug_comments;

-- Users can view comments for bugs in their projects
CREATE POLICY "Users can view bug comments" ON bug_comments
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM bugs b
        JOIN projects p ON b.project_id = p.id
        WHERE b.id = bug_comments.bug_id
        AND (p.user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE t.project_id = p.id
            AND tm.user_id = auth.uid()
        ))
    )
);

-- Users can create comments for bugs in their projects
CREATE POLICY "Users can create bug comments" ON bug_comments
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM bugs b
        JOIN projects p ON b.project_id = p.id
        WHERE b.id = bug_comments.bug_id
        AND (p.user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE t.project_id = p.id
            AND tm.user_id = auth.uid()
        ))
    )
);

-- Users can update their own comments
CREATE POLICY "Users can update their own comments" ON bug_comments
FOR UPDATE
USING (
    author = (SELECT COALESCE(raw_user_meta_data->>'name', email) FROM auth.users WHERE id = auth.uid())
    AND EXISTS (
        SELECT 1 FROM bugs b
        JOIN projects p ON b.project_id = p.id
        WHERE b.id = bug_comments.bug_id
        AND (p.user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE t.project_id = p.id
            AND tm.user_id = auth.uid()
        ))
    )
);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments" ON bug_comments
FOR DELETE
USING (
    author = (SELECT COALESCE(raw_user_meta_data->>'name', email) FROM auth.users WHERE id = auth.uid())
    AND EXISTS (
        SELECT 1 FROM bugs b
        JOIN projects p ON b.project_id = p.id
        WHERE b.id = bug_comments.bug_id
        AND (p.user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE t.project_id = p.id
            AND tm.user_id = auth.uid()
        ))
    )
);

-- =============================================================================
-- 4. CREATE STORAGE BUCKET (if it doesn't exist)
-- =============================================================================

-- Create the bug-images storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'bug-images',
    'bug-images',
    true,
    52428800, -- 50MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];

-- =============================================================================
-- 5. CREATE STORAGE POLICIES
-- =============================================================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public access for bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete bug images" ON storage.objects;

-- Policy for viewing images (public access)
CREATE POLICY "Public access for bug images" ON storage.objects
FOR SELECT
USING (bucket_id = 'bug-images');

-- Policy for uploading images (authenticated users only)
CREATE POLICY "Authenticated users can upload bug images" ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'bug-images'
    AND auth.role() = 'authenticated'
    AND EXISTS (
        -- Check if user has access to the bug (extract bug_id from path)
        SELECT 1 FROM bugs b
        JOIN projects p ON b.project_id = p.id
        WHERE b.id = (split_part(name, '/', 1))::integer
        AND (p.user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE t.project_id = p.id
            AND tm.user_id = auth.uid()
        ))
    )
);

-- Policy for updating images (authenticated users only)
CREATE POLICY "Authenticated users can update bug images" ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'bug-images'
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM bugs b
        JOIN projects p ON b.project_id = p.id
        WHERE b.id = (split_part(name, '/', 1))::integer
        AND (p.user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE t.project_id = p.id
            AND tm.user_id = auth.uid()
        ))
    )
);

-- Policy for deleting images (authenticated users only)
CREATE POLICY "Authenticated users can delete bug images" ON storage.objects
FOR DELETE
USING (
    bucket_id = 'bug-images'
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM bugs b
        JOIN projects p ON b.project_id = p.id
        WHERE b.id = (split_part(name, '/', 1))::integer
        AND (p.user_id = auth.uid() OR EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON tm.team_id = t.id
            WHERE t.project_id = p.id
            AND tm.user_id = auth.uid()
        ))
    )
);
