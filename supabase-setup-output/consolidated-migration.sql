-- Consolidated Migration for Smasher Light
-- Generated on: 2025-09-26T15:00:19.318Z
-- This file contains all migrations in the correct order

-- =============================================================================
-- MIGRATION HEADER
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- MIGRATIONS
-- =============================================================================

-- =============================================================================
-- MIGRATION 1: 20250127000000_add_token_to_team_invitations.sql
-- =============================================================================

-- Add token column to team_invitations table
-- This column is required for the invitation system to work properly

-- Add token column to team_invitations table
ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS token TEXT UNIQUE;

-- Create index for better performance on token lookups
CREATE INDEX IF NOT EXISTS idx_team_invitations_token ON team_invitations(token);

-- Update existing invitations to have tokens (if any exist)
-- Generate random tokens for existing invitations that don't have them
UPDATE team_invitations 
SET token = encode(gen_random_bytes(32), 'base64')
WHERE token IS NULL;


-- =============================================================================
-- MIGRATION 2: 20250127000001_add_token_column_to_team_invitations.sql
-- =============================================================================

-- Add token column to team_invitations table
-- This migration fixes the missing token column that's required for the invitation system

-- Add token column to team_invitations table
ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS token TEXT UNIQUE;

-- Create index for better performance on token lookups
CREATE INDEX IF NOT EXISTS idx_team_invitations_token ON team_invitations(token);

-- Update existing invitations to have tokens (if any exist)
-- Generate random tokens for existing invitations that don't have them
UPDATE team_invitations 
SET token = encode(gen_random_bytes(32), 'base64')
WHERE token IS NULL;

-- Fix the create_team_invitation function to actually store the token
CREATE OR REPLACE FUNCTION create_team_invitation(
    invite_email TEXT,
    invite_name TEXT,
    project_id_param UUID,
    team_id_param UUID,
    invite_role TEXT DEFAULT 'member'
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    team_exists BOOLEAN;
    project_exists BOOLEAN;
    user_is_team_owner BOOLEAN;
    invitation_exists BOOLEAN;
    invitation_id UUID;
    invitation_token TEXT;
BEGIN
    -- Get the current user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Check if team exists
    SELECT EXISTS(SELECT 1 FROM teams WHERE id = team_id_param) INTO team_exists;
    IF NOT team_exists THEN
        RETURN json_build_object('success', false, 'message', 'Team does not exist');
    END IF;
    
    -- Check if project exists
    SELECT EXISTS(SELECT 1 FROM projects WHERE id = project_id_param) INTO project_exists;
    IF NOT project_exists THEN
        RETURN json_build_object('success', false, 'message', 'Project does not exist');
    END IF;
    
    -- Check if user is the owner of the team
    SELECT EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND created_by = current_user_id
    ) INTO user_is_team_owner;
    
    IF NOT user_is_team_owner THEN
        RETURN json_build_object('success', false, 'message', 'Access denied: You are not the owner of this team');
    END IF;
    
    -- Check if team belongs to the specified project
    IF NOT EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND project_id = project_id_param
    ) THEN
        RETURN json_build_object('success', false, 'message', 'Team does not belong to the specified project');
    END IF;
    
    -- Check if invitation already exists for this email and team
    SELECT EXISTS(
        SELECT 1 FROM team_invitations 
        WHERE email = invite_email 
        AND team_id = team_id_param 
        AND status = 'pending'
    ) INTO invitation_exists;
    
    IF invitation_exists THEN
        RETURN json_build_object('success', false, 'message', 'An invitation for this email already exists for this team');
    END IF;
    
    -- Generate a unique token for the invitation
    invitation_token := encode(gen_random_bytes(32), 'base64');
    
    -- Create the invitation with project_id and token
    INSERT INTO team_invitations (
        team_id,
        project_id,
        email,
        invited_by,
        status,
        expires_at,
        role,
        token
    ) VALUES (
        team_id_param,
        project_id_param,
        invite_email,
        current_user_id,
        'pending',
        NOW() + INTERVAL '7 days', -- Invitation expires in 7 days
        invite_role,
        invitation_token
    ) RETURNING id INTO invitation_id;
    
    -- Return success response
    RETURN json_build_object(
        'success', true, 
        'message', 'Invitation created successfully',
        'invitation_id', invitation_id,
        'token', invitation_token
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating invitation: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================================
-- MIGRATION 3: 20250127000002_fix_accept_team_invitation_function.sql
-- =============================================================================

-- Fix accept_team_invitation function to resolve ambiguous column reference
-- This migration fixes the invitation acceptance functionality

-- Drop and recreate the accept_team_invitation function with proper variable naming
DROP FUNCTION IF EXISTS accept_team_invitation(TEXT);

CREATE OR REPLACE FUNCTION accept_team_invitation(invitation_token TEXT)
RETURNS JSON AS $$
DECLARE
    invitation_record RECORD;
    current_user_id UUID;
BEGIN
    -- Get the current user ID
    current_user_id := auth.uid();
    
    -- Find the invitation by token
    SELECT * INTO invitation_record
    FROM team_invitations
    WHERE token = invitation_token
    AND status = 'pending'
    AND expires_at > NOW();
    
    -- Check if invitation exists and is valid
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Invalid or expired invitation');
    END IF;
    
    -- Check if user email matches invitation email
    IF (SELECT email FROM auth.users WHERE id = current_user_id) != invitation_record.email THEN
        RETURN json_build_object('success', false, 'message', 'Email does not match invitation');
    END IF;
    
    -- Add user to team
    INSERT INTO team_members (team_id, user_id, role)
    VALUES (invitation_record.team_id, current_user_id, COALESCE(invitation_record.role, 'member'))
    ON CONFLICT (team_id, user_id) DO NOTHING;
    
    -- Update invitation status
    UPDATE team_invitations
    SET status = 'accepted', updated_at = NOW()
    WHERE token = invitation_token;
    
    RETURN json_build_object('success', true, 'message', 'Successfully joined team');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error accepting invitation: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean up debug function if it exists
DROP FUNCTION IF EXISTS accept_team_invitation_debug(TEXT);


-- =============================================================================
-- MIGRATION 4: 20250127000003_document_invitation_timing_fix.sql
-- =============================================================================

-- Documentation migration for invitation acceptance timing fix
-- This migration documents the frontend timing fix for invitation acceptance

-- This is a documentation-only migration to record the frontend timing fix
-- that was applied to prevent race conditions in invitation acceptance.

-- Frontend Fix Applied:
-- - Added 500ms delay before refreshing data after invitation acceptance
-- - This ensures the database has time to process the status update
-- - Prevents race conditions where UI refreshes before database update completes

-- The fix was applied in contexts/AuthContext.tsx in the acceptInvitation function:
-- 
-- Before:
-- await fetchInvitations()
-- await fetchProjects()
--
-- After:
-- await new Promise(resolve => setTimeout(resolve, 500))
-- await fetchInvitations()
-- await fetchProjects()

-- This migration serves as documentation and doesn't change any database schema.


-- =============================================================================
-- MIGRATION 5: 20250127000004_create_get_member_teams_function.sql
-- =============================================================================

-- Create get_member_teams function to get teams where user is a member
-- This function is needed for the teams page to show all teams the user belongs to

CREATE OR REPLACE FUNCTION get_member_teams(user_profile_id UUID)
RETURNS TABLE (
    team_id UUID,
    team_name VARCHAR(255),
    team_description TEXT,
    team_created_at TIMESTAMP WITH TIME ZONE,
    project_id UUID,
    project_name VARCHAR(255),
    project_description TEXT,
    project_owner_id UUID,
    project_created_at TIMESTAMP WITH TIME ZONE,
    role VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id as team_id,
        t.name as team_name,
        t.description as team_description,
        t.created_at as team_created_at,
        p.id as project_id,
        p.name as project_name,
        p.description as project_description,
        p.user_id as project_owner_id,
        p.created_at as project_created_at,
        tm.role,
        tm.joined_at
    FROM teams t
    JOIN projects p ON t.project_id = p.id
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = user_profile_id
    ORDER BY tm.joined_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================================
-- MIGRATION 6: 20250127000005_auto_add_team_creator_as_owner.sql
-- =============================================================================

-- Auto-add team creator as team member with owner role
-- This ensures the team creator is automatically added as a team member

-- Create or replace function to create teams and auto-add creator as owner
CREATE OR REPLACE FUNCTION create_team_with_owner(
    team_name VARCHAR(255),
    team_description TEXT,
    project_id_param UUID
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    new_team_id UUID;
    project_exists BOOLEAN;
    user_is_project_owner BOOLEAN;
BEGIN
    -- Get the current user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Check if project exists
    SELECT EXISTS(SELECT 1 FROM projects WHERE id = project_id_param) INTO project_exists;
    IF NOT project_exists THEN
        RETURN json_build_object('success', false, 'message', 'Project does not exist');
    END IF;
    
    -- Check if user is the owner of the project
    SELECT EXISTS(
        SELECT 1 FROM projects 
        WHERE id = project_id_param 
        AND user_id = current_user_id
    ) INTO user_is_project_owner;
    
    IF NOT user_is_project_owner THEN
        RETURN json_build_object('success', false, 'message', 'Access denied: You are not the owner of this project');
    END IF;
    
    -- Create the team
    INSERT INTO teams (name, description, project_id, created_by)
    VALUES (team_name, team_description, project_id_param, current_user_id)
    RETURNING id INTO new_team_id;
    
    -- Automatically add the creator as a team member with 'owner' role
    INSERT INTO team_members (team_id, user_id, role)
    VALUES (new_team_id, current_user_id, 'owner')
    ON CONFLICT (team_id, user_id) DO NOTHING;
    
    RETURN json_build_object(
        'success', true, 
        'message', 'Team created successfully',
        'team_id', new_team_id
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating team: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing teams to add their creators as team members if not already present
-- This is a one-time fix for existing teams
INSERT INTO team_members (team_id, user_id, role)
SELECT t.id, t.created_by, 'owner'
FROM teams t
WHERE NOT EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.team_id = t.id AND tm.user_id = t.created_by
)
ON CONFLICT (team_id, user_id) DO NOTHING;


-- =============================================================================
-- MIGRATION 7: 20250127000010_complete_bug_images_fix.sql
-- =============================================================================

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


-- =============================================================================
-- MIGRATION 8: 20250127000011_fix_bug_images_and_comments_safe.sql
-- =============================================================================

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


-- =============================================================================
-- MIGRATION 9: 20250127000012_fix_storage_policies.sql
-- =============================================================================

-- Fix storage policies to be more permissive for debugging
-- This migration simplifies the storage policies to resolve upload issues

-- Drop existing storage policies
DROP POLICY IF EXISTS "Public access for bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete bug images" ON storage.objects;

-- Create simpler, more permissive policies

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
);

-- Policy for updating images (authenticated users only)
CREATE POLICY "Authenticated users can update bug images" ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'bug-images'
    AND auth.role() = 'authenticated'
);

-- Policy for deleting images (authenticated users only)
CREATE POLICY "Authenticated users can delete bug images" ON storage.objects
FOR DELETE
USING (
    bucket_id = 'bug-images'
    AND auth.role() = 'authenticated'
);


-- =============================================================================
-- MIGRATION 10: 20250127000013_fix_bug_images_rls.sql
-- =============================================================================

-- Fix bug_images RLS policies to be more permissive for debugging
-- This migration simplifies the RLS policies to resolve insert issues

-- Drop existing RLS policies
DROP POLICY IF EXISTS "Users can view bug images" ON bug_images;
DROP POLICY IF EXISTS "Users can upload bug images" ON bug_images;
DROP POLICY IF EXISTS "Users can delete bug images" ON bug_images;

-- Create simpler, more permissive RLS policies

-- Users can view all bug images (for debugging)
CREATE POLICY "Users can view bug images" ON bug_images
FOR SELECT
USING (auth.role() = 'authenticated');

-- Users can upload bug images (for debugging)
CREATE POLICY "Users can upload bug images" ON bug_images
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- Users can delete bug images (for debugging)
CREATE POLICY "Users can delete bug images" ON bug_images
FOR DELETE
USING (auth.role() = 'authenticated');


-- =============================================================================
-- MIGRATION 11: 20250127000014_ultra_permissive_storage.sql
-- =============================================================================

-- Ultra permissive storage policies for debugging
-- This migration creates the most permissive policies possible

-- Drop all existing storage policies
DROP POLICY IF EXISTS "Public access for bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update bug images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete bug images" ON storage.objects;

-- Create ultra permissive policies

-- Allow anyone to view objects in bug-images bucket
CREATE POLICY "Anyone can view bug images" ON storage.objects
FOR SELECT
USING (bucket_id = 'bug-images');

-- Allow any authenticated user to upload to bug-images bucket
CREATE POLICY "Any authenticated user can upload bug images" ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'bug-images');

-- Allow any authenticated user to update objects in bug-images bucket
CREATE POLICY "Any authenticated user can update bug images" ON storage.objects
FOR UPDATE
USING (bucket_id = 'bug-images');

-- Allow any authenticated user to delete objects in bug-images bucket
CREATE POLICY "Any authenticated user can delete bug images" ON storage.objects
FOR DELETE
USING (bucket_id = 'bug-images');


-- =============================================================================
-- MIGRATION 12: 20250127000015_add_assignee_display_name_function.sql
-- =============================================================================

-- Migration: Add function to get assignee display name
-- This function takes a user ID (string) and returns the display name from profiles table

CREATE OR REPLACE FUNCTION get_assignee_display_name(user_id TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Handle null, empty, or 'Unassigned' cases
  IF user_id IS NULL OR user_id = '' OR user_id = 'Unassigned' THEN
    RETURN 'Unassigned';
  END IF;
  
  -- Return the name from profiles table, or 'Unknown User' if not found
  RETURN (
    SELECT COALESCE(name, 'Unknown User')
    FROM profiles
    WHERE id::text = user_id
  );
END;
$$;

-- Add a comment explaining the function
COMMENT ON FUNCTION get_assignee_display_name(TEXT) IS 'Returns the display name for a user ID from the profiles table, or "Unknown User" if not found';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_assignee_display_name(TEXT) TO authenticated;

-- Test the function (optional - can be removed in production)
-- SELECT get_assignee_display_name('some-uuid-here') as test_result;


-- =============================================================================
-- MIGRATION 13: 20250127000016_create_todos_with_assignee_names_view.sql
-- =============================================================================

-- Migration: Create a view for todos with assignee names
-- This view joins todos with profiles to get assignee display names

CREATE OR REPLACE VIEW todos_with_assignee_names AS
SELECT 
  t.*,
  CASE 
    WHEN t.assignee IS NULL OR t.assignee = '' THEN 'Unassigned'
    WHEN t.assignee = 'Unassigned' THEN 'Unassigned'
    ELSE COALESCE(p.name, 'Unknown User')
  END as assignee_name
FROM todos t
LEFT JOIN profiles p ON t.assignee::uuid = p.id;

-- Add a comment explaining the view
COMMENT ON VIEW todos_with_assignee_names IS 'View that includes todos with resolved assignee names instead of UUIDs';

-- Grant select permission to authenticated users
GRANT SELECT ON todos_with_assignee_names TO authenticated;

-- Create RLS policy for the view (inherits from base todos table)
-- The view will respect the same RLS policies as the todos table


-- =============================================================================
-- MIGRATION 14: 20250925160547_create_initial_schema.sql
-- =============================================================================

-- Create initial database schema for Smasher Light application
-- This migration creates all necessary tables, indexes, and RLS policies

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create teams table
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create team_members table (junction table)
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Create team_invitations table
CREATE TABLE IF NOT EXISTS team_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    invited_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bugs table
CREATE TABLE IF NOT EXISTS bugs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Open', 'In Progress', 'Closed', 'Ready for QA')),
    environment VARCHAR(20) NOT NULL CHECK (environment IN ('Prod', 'Stage', 'Dev')),
    reporter VARCHAR(255) NOT NULL,
    assignee VARCHAR(255),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create todos table
CREATE TABLE IF NOT EXISTS todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    issue_link TEXT,
    status VARCHAR(20) NOT NULL CHECK (status IN ('OPEN', 'IN_PROGRESS', 'DONE', 'READY_FOR_QA')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    environment VARCHAR(20) NOT NULL CHECK (environment IN ('Prod', 'Stage', 'Dev')),
    assignee VARCHAR(255) NOT NULL,
    quick_action TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bug_images table for storing bug attachments
CREATE TABLE IF NOT EXISTS bug_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_name VARCHAR(255),
    image_size INTEGER,
    uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at);

CREATE INDEX IF NOT EXISTS idx_teams_project_id ON teams(project_id);
CREATE INDEX IF NOT EXISTS idx_teams_created_by ON teams(created_by);

CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);

CREATE INDEX IF NOT EXISTS idx_team_invitations_email ON team_invitations(email);
CREATE INDEX IF NOT EXISTS idx_team_invitations_team_id ON team_invitations(team_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_status ON team_invitations(status);

CREATE INDEX IF NOT EXISTS idx_bugs_user_id ON bugs(user_id);
CREATE INDEX IF NOT EXISTS idx_bugs_project_id ON bugs(project_id);
CREATE INDEX IF NOT EXISTS idx_bugs_status ON bugs(status);
CREATE INDEX IF NOT EXISTS idx_bugs_severity ON bugs(severity);
CREATE INDEX IF NOT EXISTS idx_bugs_created_at ON bugs(created_at);

CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_project_id ON todos(project_id);
CREATE INDEX IF NOT EXISTS idx_todos_status ON todos(status);
CREATE INDEX IF NOT EXISTS idx_todos_assignee ON todos(assignee);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);

CREATE INDEX IF NOT EXISTS idx_bug_images_bug_id ON bug_images(bug_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_invitations_updated_at BEFORE UPDATE ON team_invitations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bugs_updated_at BEFORE UPDATE ON bugs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON todos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to get team members
CREATE OR REPLACE FUNCTION get_team_members(team_uuid UUID)
RETURNS TABLE (
    member_id UUID,
    member_name TEXT,
    member_email TEXT,
    member_avatar_url TEXT,
    role VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.user_id as member_id,
        COALESCE(au.raw_user_meta_data->>'name', au.email) as member_name,
        au.email as member_email,
        au.raw_user_meta_data->>'avatar_url' as member_avatar_url,
        tm.role,
        tm.joined_at
    FROM team_members tm
    JOIN auth.users au ON tm.user_id = au.id
    WHERE tm.team_id = team_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get member projects (for invited projects)
CREATE OR REPLACE FUNCTION get_member_projects(user_profile_id UUID)
RETURNS TABLE (
    project_id UUID,
    project_name VARCHAR(255),
    project_description TEXT,
    project_owner_id UUID,
    project_created_at TIMESTAMP WITH TIME ZONE,
    team_id UUID,
    team_name VARCHAR(255),
    role VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as project_id,
        p.name as project_name,
        p.description as project_description,
        p.user_id as project_owner_id,
        p.created_at as project_created_at,
        t.id as team_id,
        t.name as team_name,
        tm.role,
        tm.joined_at
    FROM projects p
    JOIN teams t ON t.project_id = p.id
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = user_profile_id
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to accept team invitations
CREATE OR REPLACE FUNCTION accept_team_invitation(invitation_token TEXT)
RETURNS JSON AS $$
DECLARE
    invitation_record RECORD;
    user_id UUID;
BEGIN
    -- Get the current user ID
    user_id := auth.uid();
    
    -- Find the invitation by token
    SELECT * INTO invitation_record
    FROM team_invitations
    WHERE token = invitation_token
    AND status = 'pending'
    AND expires_at > NOW();
    
    -- Check if invitation exists and is valid
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Invalid or expired invitation');
    END IF;
    
    -- Check if user email matches invitation email
    IF (SELECT email FROM auth.users WHERE id = user_id) != invitation_record.email THEN
        RETURN json_build_object('success', false, 'message', 'Email does not match invitation');
    END IF;
    
    -- Add user to team
    INSERT INTO team_members (team_id, user_id, role)
    VALUES (invitation_record.team_id, user_id, COALESCE(invitation_record.role, 'member'))
    ON CONFLICT (team_id, user_id) DO NOTHING;
    
    -- Update invitation status
    UPDATE team_invitations
    SET status = 'accepted', updated_at = NOW()
    WHERE token = invitation_token;
    
    RETURN json_build_object('success', true, 'message', 'Successfully joined team');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error accepting invitation: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for projects
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own projects" ON projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects" ON projects
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects" ON projects
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for teams
CREATE POLICY "Users can view teams they created or are members of" ON teams
    FOR SELECT USING (
        auth.uid() = created_by OR 
        EXISTS (
            SELECT 1 FROM team_members tm 
            WHERE tm.team_id = teams.id 
            AND tm.user_id = auth.uid()
        )
    );

CREATE POLICY "Project owners can create teams" ON teams
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        auth.uid() IN (
            SELECT user_id FROM projects WHERE id = project_id
        )
    );

CREATE POLICY "Team owners can update teams" ON teams
    FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Team owners can delete teams" ON teams
    FOR DELETE USING (auth.uid() = created_by);

-- Create RLS policies for team_members
CREATE POLICY "Users can view team members if they're in the team or created it" ON team_members
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

CREATE POLICY "Team owners can add members" ON team_members
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for team_invitations
CREATE POLICY "Users can view their own invitations" ON team_invitations
    FOR SELECT USING (email = auth.jwt() ->> 'email');

CREATE POLICY "Team owners can create invitations" ON team_invitations
    FOR INSERT WITH CHECK (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

CREATE POLICY "Team owners can update invitations" ON team_invitations
    FOR UPDATE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Create RLS policies for bugs
CREATE POLICY "Users can view all bugs" ON bugs
    FOR SELECT USING (true);

CREATE POLICY "Users can create bugs" ON bugs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bugs" ON bugs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bugs" ON bugs
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for todos
CREATE POLICY "Users can view all todos" ON todos
    FOR SELECT USING (true);

CREATE POLICY "Users can create todos" ON todos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own todos" ON todos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own todos" ON todos
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for bug_images
CREATE POLICY "Users can view bug images" ON bug_images
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM bugs WHERE id = bug_id
        )
    );

CREATE POLICY "Users can upload bug images" ON bug_images
    FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can delete their own bug images" ON bug_images
    FOR DELETE USING (auth.uid() = uploaded_by);

-- Create function to handle project assignment for bugs and todos
CREATE OR REPLACE FUNCTION assign_to_current_project()
RETURNS TRIGGER AS $$
BEGIN
    -- If project_id is not provided, try to get it from the user's current project
    -- This is a placeholder - you might want to implement project selection logic
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic project assignment (optional)
-- You can uncomment these if you want automatic project assignment
-- CREATE TRIGGER assign_bug_to_project BEFORE INSERT ON bugs
--     FOR EACH ROW EXECUTE FUNCTION assign_to_current_project();

-- CREATE TRIGGER assign_todo_to_project BEFORE INSERT ON todos
--     FOR EACH ROW EXECUTE FUNCTION assign_to_current_project();

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_team_invitation(TEXT) TO authenticated;


-- =============================================================================
-- MIGRATION 15: 20250925160548_add_missing_columns_and_functions.sql
-- =============================================================================

-- Comprehensive migration to add missing columns, tables, and functions
-- This migration adds all the missing database elements needed for full functionality

-- =============================================================================
-- 1. CREATE MISSING PROFILES TABLE
-- =============================================================================

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_name ON profiles(name);

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. ADD MISSING COLUMNS TO EXISTING TABLES
-- =============================================================================

-- Add missing columns to bugs table
ALTER TABLE bugs ADD COLUMN IF NOT EXISTS steps_to_reproduce TEXT;
ALTER TABLE bugs ADD COLUMN IF NOT EXISTS url TEXT;

-- Add missing columns to team_invitations table
ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'member';
ALTER TABLE team_invitations ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_team_invitations_project_id ON team_invitations(project_id);

-- =============================================================================
-- 3. CREATE ESSENTIAL FUNCTIONS
-- =============================================================================

-- Drop existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS get_team_members(UUID);

-- Create function to get team members with proper text casting
CREATE FUNCTION get_team_members(team_uuid UUID)
RETURNS TABLE (
    member_id UUID,
    member_name TEXT,
    member_email TEXT,
    member_avatar_url TEXT,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.user_id as member_id,
        COALESCE(au.raw_user_meta_data->>'name', au.email)::TEXT as member_name,
        au.email::TEXT as member_email,
        COALESCE(au.raw_user_meta_data->>'avatar_url', '')::TEXT as member_avatar_url,
        tm.role::TEXT,
        tm.joined_at
    FROM team_members tm
    JOIN auth.users au ON tm.user_id = au.id
    WHERE tm.team_id = team_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing function first to avoid conflicts
DROP FUNCTION IF EXISTS get_member_projects(UUID);

-- Create function to get member projects (for invited projects)
CREATE FUNCTION get_member_projects(user_profile_id UUID)
RETURNS TABLE (
    project_id UUID,
    project_name VARCHAR(255),
    project_description TEXT,
    project_owner_id UUID,
    project_created_at TIMESTAMP WITH TIME ZONE,
    team_id UUID,
    team_name VARCHAR(255),
    role VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as project_id,
        p.name as project_name,
        p.description as project_description,
        p.user_id as project_owner_id,
        p.created_at as project_created_at,
        t.id as team_id,
        t.name as team_name,
        tm.role,
        tm.joined_at
    FROM projects p
    JOIN teams t ON t.project_id = p.id
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = user_profile_id
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing function first to avoid conflicts
DROP FUNCTION IF EXISTS accept_team_invitation(TEXT);

-- Create function to accept team invitations
CREATE FUNCTION accept_team_invitation(invitation_token TEXT)
RETURNS JSON AS $$
DECLARE
    invitation_record RECORD;
    user_id UUID;
BEGIN
    -- Get the current user ID
    user_id := auth.uid();
    
    -- Find the invitation by token
    SELECT * INTO invitation_record
    FROM team_invitations
    WHERE token = invitation_token
    AND status = 'pending'
    AND expires_at > NOW();
    
    -- Check if invitation exists and is valid
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Invalid or expired invitation');
    END IF;
    
    -- Check if user email matches invitation email
    IF (SELECT email FROM auth.users WHERE id = user_id) != invitation_record.email THEN
        RETURN json_build_object('success', false, 'message', 'Email does not match invitation');
    END IF;
    
    -- Add user to team
    INSERT INTO team_members (team_id, user_id, role)
    VALUES (invitation_record.team_id, user_id, COALESCE(invitation_record.role, 'member'))
    ON CONFLICT (team_id, user_id) DO NOTHING;
    
    -- Update invitation status
    UPDATE team_invitations
    SET status = 'accepted', updated_at = NOW()
    WHERE token = invitation_token;
    
    RETURN json_build_object('success', true, 'message', 'Successfully joined team');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error accepting invitation: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to create team invitations
CREATE OR REPLACE FUNCTION create_team_invitation(
    invite_email TEXT,
    invite_name TEXT,
    project_id_param UUID,
    team_id_param UUID,
    invite_role TEXT DEFAULT 'member'
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    team_exists BOOLEAN;
    project_exists BOOLEAN;
    user_is_team_owner BOOLEAN;
    invitation_exists BOOLEAN;
    invitation_id UUID;
    invitation_token TEXT;
BEGIN
    -- Get the current user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Check if team exists
    SELECT EXISTS(SELECT 1 FROM teams WHERE id = team_id_param) INTO team_exists;
    IF NOT team_exists THEN
        RETURN json_build_object('success', false, 'message', 'Team does not exist');
    END IF;
    
    -- Check if project exists
    SELECT EXISTS(SELECT 1 FROM projects WHERE id = project_id_param) INTO project_exists;
    IF NOT project_exists THEN
        RETURN json_build_object('success', false, 'message', 'Project does not exist');
    END IF;
    
    -- Check if user is the owner of the team
    SELECT EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND created_by = current_user_id
    ) INTO user_is_team_owner;
    
    IF NOT user_is_team_owner THEN
        RETURN json_build_object('success', false, 'message', 'Access denied: You are not the owner of this team');
    END IF;
    
    -- Check if team belongs to the specified project
    IF NOT EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND project_id = project_id_param
    ) THEN
        RETURN json_build_object('success', false, 'message', 'Team does not belong to the specified project');
    END IF;
    
    -- Check if invitation already exists for this email and team
    SELECT EXISTS(
        SELECT 1 FROM team_invitations 
        WHERE email = invite_email 
        AND team_id = team_id_param 
        AND status = 'pending'
    ) INTO invitation_exists;
    
    IF invitation_exists THEN
        RETURN json_build_object('success', false, 'message', 'An invitation for this email already exists for this team');
    END IF;
    
    -- Generate a unique token for the invitation
    invitation_token := encode(gen_random_bytes(32), 'base64');
    
    -- Create the invitation with project_id
    INSERT INTO team_invitations (
        team_id,
        project_id,
        email,
        invited_by,
        status,
        expires_at,
        role
    ) VALUES (
        team_id_param,
        project_id_param,
        invite_email,
        current_user_id,
        'pending',
        NOW() + INTERVAL '7 days', -- Invitation expires in 7 days
        invite_role
    ) RETURNING id INTO invitation_id;
    
    -- Return success response
    RETURN json_build_object(
        'success', true, 
        'message', 'Invitation created successfully',
        'invitation_id', invitation_id,
        'token', invitation_token
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating invitation: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 4. CREATE USER PROFILE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Create function to handle new user signup and create profile
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to sync existing users to profiles table
CREATE OR REPLACE FUNCTION sync_existing_users_to_profiles()
RETURNS INTEGER AS $$
DECLARE
    user_count INTEGER;
BEGIN
    INSERT INTO public.profiles (id, name, email, avatar_url)
    SELECT 
        id,
        COALESCE(raw_user_meta_data->>'name', email),
        email,
        raw_user_meta_data->>'avatar_url'
    FROM auth.users
    WHERE id NOT IN (SELECT id FROM public.profiles)
    ON CONFLICT (id) DO NOTHING;
    
    GET DIAGNOSTICS user_count = ROW_COUNT;
    RETURN user_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to create profile for team member
CREATE OR REPLACE FUNCTION create_profile_for_team_member(
    user_id_param UUID,
    name_param TEXT,
    email_param TEXT,
    avatar_url_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Insert or update profile
    INSERT INTO public.profiles (id, name, email, avatar_url)
    VALUES (user_id_param, name_param, email_param, avatar_url_param)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        avatar_url = EXCLUDED.avatar_url,
        updated_at = NOW();
    
    RETURN json_build_object('success', true, 'message', 'Profile created/updated successfully');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating profile: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 5. CREATE TRIGGERS
-- =============================================================================

-- Create trigger to automatically create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================================================
-- 6. GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_team_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_projects(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_team_invitation(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_team_invitation(TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_profile_for_team_member(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- =============================================================================
-- 7. SYNC EXISTING DATA
-- =============================================================================

-- Sync existing users to profiles table
SELECT sync_existing_users_to_profiles();


-- =============================================================================
-- MIGRATION 16: 20250925160549_comprehensive_rls_policies.sql
-- =============================================================================

-- Comprehensive RLS policies migration
-- This migration creates all necessary Row Level Security policies for proper data access control

-- =============================================================================
-- 1. CLEAN UP EXISTING POLICIES (SAFE CLEANUP)
-- =============================================================================

-- Drop all existing policies to start fresh (safe because we'll recreate them)
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;
DROP POLICY IF EXISTS "Users can create their own projects" ON projects;
DROP POLICY IF EXISTS "Users can update their own projects" ON projects;
DROP POLICY IF EXISTS "Users can delete their own projects" ON projects;

DROP POLICY IF EXISTS "Users can view teams they created or are members of" ON teams;
DROP POLICY IF EXISTS "Project owners can create teams" ON teams;
DROP POLICY IF EXISTS "Team owners can update teams" ON teams;
DROP POLICY IF EXISTS "Team owners can delete teams" ON teams;
DROP POLICY IF EXISTS "Users can view teams in their projects" ON teams;

DROP POLICY IF EXISTS "Users can view team members if they're in the team or created it" ON team_members;
DROP POLICY IF EXISTS "Team owners can add members" ON team_members;
DROP POLICY IF EXISTS "Users can leave teams" ON team_members;
DROP POLICY IF EXISTS "Users can view team members in their teams" ON team_members;

DROP POLICY IF EXISTS "Users can view their own invitations" ON team_invitations;
DROP POLICY IF EXISTS "Team owners can create invitations" ON team_invitations;
DROP POLICY IF EXISTS "Team owners can update invitations" ON team_invitations;

DROP POLICY IF EXISTS "Users can view all bugs" ON bugs;
DROP POLICY IF EXISTS "Users can create bugs" ON bugs;
DROP POLICY IF EXISTS "Users can update their own bugs" ON bugs;
DROP POLICY IF EXISTS "Users can delete their own bugs" ON bugs;

DROP POLICY IF EXISTS "Users can view all todos" ON todos;
DROP POLICY IF EXISTS "Users can create todos" ON todos;
DROP POLICY IF EXISTS "Users can update their own todos" ON todos;
DROP POLICY IF EXISTS "Users can delete their own todos" ON todos;

DROP POLICY IF EXISTS "Users can view bug images" ON bug_images;
DROP POLICY IF EXISTS "Users can upload bug images" ON bug_images;
DROP POLICY IF EXISTS "Users can delete their own bug images" ON bug_images;

-- =============================================================================
-- 2. PROJECTS TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own projects
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Users can view projects they are team members of
CREATE POLICY "Users can view projects they are team members of" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

-- Users can create their own projects
CREATE POLICY "Users can create their own projects" ON projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own projects
CREATE POLICY "Users can update their own projects" ON projects
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own projects
CREATE POLICY "Users can delete their own projects" ON projects
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 3. TEAMS TABLE RLS POLICIES
-- =============================================================================

-- Users can view teams they created
CREATE POLICY "Users can view teams they created" ON teams
    FOR SELECT USING (auth.uid() = created_by);

-- Users can view teams they are members of
CREATE POLICY "Users can view teams they are members of" ON teams
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm 
            WHERE tm.team_id = teams.id 
            AND tm.user_id = auth.uid()
        )
    );

-- Project owners can create teams for their projects
CREATE POLICY "Project owners can create teams" ON teams
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        auth.uid() IN (
            SELECT user_id FROM projects WHERE id = project_id
        )
    );

-- Team owners can update teams they created
CREATE POLICY "Team owners can update teams" ON teams
    FOR UPDATE USING (auth.uid() = created_by);

-- Team owners can delete teams they created
CREATE POLICY "Team owners can delete teams" ON teams
    FOR DELETE USING (auth.uid() = created_by);

-- =============================================================================
-- 4. TEAM_MEMBERS TABLE RLS POLICIES
-- =============================================================================

-- Users can view team members of teams they created
CREATE POLICY "Users can view team members of teams they created" ON team_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

-- Users can view themselves as team members
CREATE POLICY "Users can view themselves as team members" ON team_members
    FOR SELECT USING (auth.uid() = user_id);

-- Team owners can add members to their teams
CREATE POLICY "Team owners can add members" ON team_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

-- Users can leave teams (delete themselves)
CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);

-- Team owners can remove members from their teams
CREATE POLICY "Team owners can remove members" ON team_members
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM teams t 
            WHERE t.id = team_members.team_id 
            AND t.created_by = auth.uid()
        )
    );

-- =============================================================================
-- 5. TEAM_INVITATIONS TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own invitations
CREATE POLICY "Users can view their own invitations" ON team_invitations
    FOR SELECT USING (email = auth.jwt() ->> 'email');

-- Team owners can create invitations for their teams
CREATE POLICY "Team owners can create invitations" ON team_invitations
    FOR INSERT WITH CHECK (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Team owners can update invitations for their teams
CREATE POLICY "Team owners can update invitations" ON team_invitations
    FOR UPDATE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- Team owners can delete invitations for their teams
CREATE POLICY "Team owners can delete invitations" ON team_invitations
    FOR DELETE USING (
        auth.uid() = invited_by AND
        auth.uid() IN (
            SELECT created_by FROM teams WHERE id = team_id
        )
    );

-- =============================================================================
-- 6. BUGS TABLE RLS POLICIES
-- =============================================================================

-- Users can view all bugs (for collaboration)
CREATE POLICY "Users can view all bugs" ON bugs
    FOR SELECT USING (true);

-- Users can create bugs
CREATE POLICY "Users can create bugs" ON bugs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own bugs
CREATE POLICY "Users can update their own bugs" ON bugs
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own bugs
CREATE POLICY "Users can delete their own bugs" ON bugs
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 7. TODOS TABLE RLS POLICIES
-- =============================================================================

-- Users can view all todos (for collaboration)
CREATE POLICY "Users can view all todos" ON todos
    FOR SELECT USING (true);

-- Users can create todos
CREATE POLICY "Users can create todos" ON todos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own todos
CREATE POLICY "Users can update their own todos" ON todos
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own todos
CREATE POLICY "Users can delete their own todos" ON todos
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 8. BUG_IMAGES TABLE RLS POLICIES
-- =============================================================================

-- Users can view bug images for bugs they can access
CREATE POLICY "Users can view bug images" ON bug_images
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM bugs WHERE id = bug_id
        )
    );

-- Users can upload bug images for their own bugs
CREATE POLICY "Users can upload bug images" ON bug_images
    FOR INSERT WITH CHECK (
        auth.uid() = uploaded_by AND
        auth.uid() IN (
            SELECT user_id FROM bugs WHERE id = bug_id
        )
    );

-- Users can delete their own bug images
CREATE POLICY "Users can delete their own bug images" ON bug_images
    FOR DELETE USING (auth.uid() = uploaded_by);

-- =============================================================================
-- 9. PROFILES TABLE RLS POLICIES
-- =============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can view profiles of team members in their projects
CREATE POLICY "Users can view team member profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id IN (
                SELECT p.id FROM projects p
                WHERE p.user_id = auth.uid()
            )
            AND profiles.id = tm.user_id
        )
    );

-- =============================================================================
-- 10. ADDITIONAL SECURITY MEASURES
-- =============================================================================

-- Ensure all tables have RLS enabled
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 11. GRANT NECESSARY PERMISSIONS
-- =============================================================================

-- Grant necessary permissions for authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Ensure RLS is properly configured
-- (This is already done above, but being explicit)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bug_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- MIGRATION 17: 20250925160550_fix_rls_infinite_recursion.sql
-- =============================================================================

-- Fix infinite recursion in RLS policies
-- This migration resolves the circular dependency issue in team_members policies

-- =============================================================================
-- 1. DROP PROBLEMATIC POLICIES
-- =============================================================================

-- Drop the policies that are causing infinite recursion
DROP POLICY IF EXISTS "Users can view team members of teams they created" ON team_members;
DROP POLICY IF EXISTS "Users can view themselves as team members" ON team_members;
DROP POLICY IF EXISTS "Team owners can add members" ON team_members;
DROP POLICY IF EXISTS "Users can leave teams" ON team_members;
DROP POLICY IF EXISTS "Team owners can remove members" ON team_members;

-- Also drop the problematic projects policy that might be causing issues
DROP POLICY IF EXISTS "Users can view projects they are team members of" ON projects;

-- =============================================================================
-- 2. CREATE SIMPLIFIED, NON-RECURSIVE POLICIES
-- =============================================================================

-- Projects: Users can view their own projects only (simplified to avoid recursion)
CREATE POLICY "Users can view their own projects only" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Team Members: Simplified policies that don't create circular dependencies

-- Users can view team members where they are the user_id (themselves)
CREATE POLICY "Users can view their own team memberships" ON team_members
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert themselves into teams (for invitation acceptance)
CREATE POLICY "Users can join teams" ON team_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can remove themselves from teams (leave teams)
CREATE POLICY "Users can leave teams" ON team_members
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 3. CREATE HELPER FUNCTIONS FOR TEAM ACCESS
-- =============================================================================

-- Create a function to check if user is team owner (avoids policy recursion)
CREATE OR REPLACE FUNCTION is_team_owner(user_id_param UUID, team_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM teams 
        WHERE id = team_id_param 
        AND created_by = user_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if user is team member (avoids policy recursion)
CREATE OR REPLACE FUNCTION is_team_member(user_id_param UUID, team_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM team_members 
        WHERE team_id = team_id_param 
        AND user_id = user_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 4. ADD MORE PERMISSIVE POLICIES FOR TEAM OWNERS (USING FUNCTIONS)
-- =============================================================================

-- Team owners can view all members of their teams (using function to avoid recursion)
CREATE POLICY "Team owners can view their team members" ON team_members
    FOR SELECT USING (
        is_team_owner(auth.uid(), team_id)
    );

-- Team owners can add members to their teams (using function to avoid recursion)
CREATE POLICY "Team owners can add members to their teams" ON team_members
    FOR INSERT WITH CHECK (
        is_team_owner(auth.uid(), team_id)
    );

-- Team owners can remove members from their teams (using function to avoid recursion)
CREATE POLICY "Team owners can remove members from their teams" ON team_members
    FOR DELETE USING (
        is_team_owner(auth.uid(), team_id)
    );

-- =============================================================================
-- 5. GRANT PERMISSIONS ON HELPER FUNCTIONS
-- =============================================================================

GRANT EXECUTE ON FUNCTION is_team_owner(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_team_member(UUID, UUID) TO authenticated;


-- =============================================================================
-- MIGRATION 18: 20250925160551_fix_notifications_rls_policies.sql
-- =============================================================================

-- Fix RLS policies for notifications functionality
-- This migration adds the necessary permissions for fetching project and profile names in invitations

-- =============================================================================
-- 1. ADD POLICIES FOR PROJECT NAME ACCESS IN INVITATIONS
-- =============================================================================

-- Allow users to view project names for projects they have invitations to
CREATE POLICY "Users can view project names for their invitations" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.project_id = projects.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- =============================================================================
-- 2. ADD POLICIES FOR PROFILE NAME ACCESS IN INVITATIONS
-- =============================================================================

-- Allow users to view profile names of users who invited them
CREATE POLICY "Users can view inviter profiles for their invitations" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.invited_by = profiles.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- =============================================================================
-- 3. ADD MORE PERMISSIVE POLICIES FOR TEAM COLLABORATION
-- =============================================================================

-- Allow users to view project names for projects they are team members of
CREATE POLICY "Users can view project names for their team projects" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

-- Allow users to view profile names of their team members
CREATE POLICY "Users can view team member profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm1
            JOIN team_members tm2 ON tm1.team_id = tm2.team_id
            WHERE tm1.user_id = auth.uid()
            AND tm2.user_id = profiles.id
        )
    );

-- =============================================================================
-- 4. GRANT ADDITIONAL PERMISSIONS
-- =============================================================================

-- Ensure authenticated users have the necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;


-- =============================================================================
-- MIGRATION 19: 20250925160552_fix_notifications_access.sql
-- =============================================================================

-- Fix notifications access by updating RLS policies
-- This migration properly handles existing policies and adds necessary permissions

-- =============================================================================
-- 1. DROP DUPLICATE AND PROBLEMATIC POLICIES
-- =============================================================================

-- Drop duplicate policies
DROP POLICY IF EXISTS "Users can view their own projects only" ON projects;
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;

-- =============================================================================
-- 2. CREATE CORRECTED PROJECT POLICIES
-- =============================================================================

-- Users can view their own projects
CREATE POLICY "Users can view their own projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Users can view project names for projects they have invitations to
CREATE POLICY "Users can view project names for their invitations" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.project_id = projects.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- Users can view project names for projects they are team members of
CREATE POLICY "Users can view project names for their team projects" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id = projects.id
        )
    );

-- =============================================================================
-- 3. CREATE CORRECTED PROFILE POLICIES
-- =============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can view inviter profiles for their invitations
CREATE POLICY "Users can view inviter profiles for their invitations" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_invitations ti
            WHERE ti.invited_by = profiles.id
            AND ti.email = auth.jwt() ->> 'email'
            AND ti.status = 'pending'
        )
    );

-- Users can view team member profiles
CREATE POLICY "Users can view team member profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm1
            JOIN team_members tm2 ON tm1.team_id = tm2.team_id
            WHERE tm1.user_id = auth.uid()
            AND tm2.user_id = profiles.id
        )
    );


