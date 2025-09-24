-- Setup script for bug images storage
-- Run this in your Supabase SQL editor to set up the storage bucket and policies

-- Create the storage bucket for bug images
INSERT INTO storage.buckets (id, name, public)
VALUES ('bug-images', 'bug-images', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for bug-images bucket
-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view bug images in their projects" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload bug images in their projects" ON storage.objects;
DROP POLICY IF EXISTS "Users can update bug images in their projects" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete bug images in their projects" ON storage.objects;

-- Simplified policies that allow authenticated users to manage images
-- The actual access control is handled at the application level through the bug_images table

-- Policy for viewing images
CREATE POLICY "Users can view bug images in their projects" ON storage.objects
FOR SELECT USING (
  bucket_id = 'bug-images' AND
  auth.uid() IS NOT NULL
);

-- Policy for uploading images
CREATE POLICY "Users can upload bug images in their projects" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'bug-images' AND
  auth.uid() IS NOT NULL
);

-- Policy for updating images
CREATE POLICY "Users can update bug images in their projects" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'bug-images' AND
  auth.uid() IS NOT NULL
);

-- Policy for deleting images
CREATE POLICY "Users can delete bug images in their projects" ON storage.objects
FOR DELETE USING (
  bucket_id = 'bug-images' AND
  auth.uid() IS NOT NULL
);

-- Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;
