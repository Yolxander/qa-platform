-- Storage Setup for Smasher Light
-- Run this after setting up your Supabase project

-- Create storage bucket for bug images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'bug-images',
  'bug-images',
  true,
  52428800, -- 50MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create storage policies for bug images
CREATE POLICY "Users can view bug images" ON storage.objects
FOR SELECT USING (bucket_id = 'bug-images');

CREATE POLICY "Users can upload bug images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'bug-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own bug images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'bug-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own bug images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'bug-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;
