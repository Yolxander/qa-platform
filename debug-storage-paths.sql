-- Debug script to check storage paths and policies
-- Run this to see what's happening with file paths

-- Check existing storage objects
SELECT 
  name,
  bucket_id,
  created_at,
  owner
FROM storage.objects 
WHERE bucket_id = 'bug-images'
ORDER BY created_at DESC
LIMIT 10;

-- Check if the bucket exists and is configured correctly
SELECT 
  id,
  name,
  public,
  created_at
FROM storage.buckets 
WHERE id = 'bug-images';

-- Check storage policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;
