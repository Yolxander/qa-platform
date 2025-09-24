-- Fix storage bucket access for bug images
-- This script ensures the storage bucket is properly configured for public access

-- First, check if the bucket exists and is public
SELECT 
  id,
  name,
  public,
  created_at
FROM storage.buckets 
WHERE id = 'bug-images';

-- If the bucket doesn't exist or isn't public, create/update it
INSERT INTO storage.buckets (id, name, public)
VALUES ('bug-images', 'bug-images', true)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  name = 'bug-images';

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can view bug images in their projects" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload bug images in their projects" ON storage.objects;
DROP POLICY IF EXISTS "Users can update bug images in their projects" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete bug images in their projects" ON storage.objects;

-- Create very permissive policies for the bug-images bucket
-- This allows all authenticated users to access images
CREATE POLICY "Allow public access to bug images" ON storage.objects
FOR ALL USING (bucket_id = 'bug-images');

-- Alternative: If you want more restrictive access, use this instead:
-- CREATE POLICY "Allow authenticated users to access bug images" ON storage.objects
-- FOR ALL USING (bucket_id = 'bug-images' AND auth.uid() IS NOT NULL);

-- Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Check the bucket configuration
SELECT 
  id,
  name,
  public,
  created_at
FROM storage.buckets 
WHERE id = 'bug-images';

-- Check existing objects in the bucket
SELECT 
  name,
  bucket_id,
  created_at,
  owner
FROM storage.objects 
WHERE bucket_id = 'bug-images'
ORDER BY created_at DESC
LIMIT 10;
