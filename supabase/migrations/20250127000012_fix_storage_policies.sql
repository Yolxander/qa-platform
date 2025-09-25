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
