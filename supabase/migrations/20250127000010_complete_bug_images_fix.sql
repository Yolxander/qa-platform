-- Complete fix for bug images and comments functionality
-- This migration fixes all database and storage issues

-- =============================================================================
-- 1. FIX BUG_IMAGES TABLE SCHEMA
-- =============================================================================

-- Drop existing bug_images table if it exists (to recreate with correct schema)
DROP TABLE IF EXISTS bug_images CASCADE;

-- Create bug_images table with correct schema matching the code expectations
CREATE TABLE bug_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
    url TEXT NOT NULL,  -- Changed from image_url to url
    name VARCHAR(255),  -- Changed from image_name to name
    size INTEGER,       -- Changed from image_size to size
    path TEXT,          -- Added path column for storage path
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bug_images_bug_id ON bug_images(bug_id);
CREATE INDEX IF NOT EXISTS idx_bug_images_created_at ON bug_images(created_at);

-- =============================================================================
-- 2. CREATE BUG_COMMENTS TABLE
-- =============================================================================

-- Create bug_comments table for storing comments on bugs
CREATE TABLE bug_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
    author VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    attachments TEXT[], -- Array of attachment filenames
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bug_comments_bug_id ON bug_comments(bug_id);
CREATE INDEX IF NOT EXISTS idx_bug_comments_created_at ON bug_comments(created_at);

-- =============================================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on both tables
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_comments ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 4. CREATE RLS POLICIES FOR BUG_IMAGES
-- =============================================================================

-- Users can view bug images for bugs in their projects
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

-- Users can upload bug images for bugs in their projects
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

-- Users can delete bug images for bugs in their projects
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

-- =============================================================================
-- 5. CREATE RLS POLICIES FOR BUG_COMMENTS
-- =============================================================================

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
-- 6. CREATE STORAGE BUCKET
-- =============================================================================

-- Create the bug-images storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'bug-images',
    'bug-images',
    true, -- Public bucket for easy access
    52428800, -- 50MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];

-- =============================================================================
-- 7. CREATE STORAGE POLICIES
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
