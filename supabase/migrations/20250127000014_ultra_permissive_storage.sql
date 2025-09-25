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
