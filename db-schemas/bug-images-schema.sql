-- Bug Images Schema
-- This schema creates tables for storing images associated with bugs

-- Create bug_images table
CREATE TABLE IF NOT EXISTS public.bug_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bug_id INTEGER NOT NULL REFERENCES public.bugs(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  name TEXT NOT NULL,
  size INTEGER NOT NULL,
  path TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bug_images_bug_id ON public.bug_images(bug_id);
CREATE INDEX IF NOT EXISTS idx_bug_images_created_at ON public.bug_images(created_at);

-- Enable RLS on bug_images table
ALTER TABLE public.bug_images ENABLE ROW LEVEL SECURITY;

-- RLS Policies for bug_images (with IF NOT EXISTS handling)
DO $$
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can view bug images in their projects" ON public.bug_images;
  DROP POLICY IF EXISTS "Users can insert bug images in their projects" ON public.bug_images;
  DROP POLICY IF EXISTS "Users can update bug images in their projects" ON public.bug_images;
  DROP POLICY IF EXISTS "Users can delete bug images in their projects" ON public.bug_images;
  
  -- Create new policies
  CREATE POLICY "Users can view bug images in their projects" ON public.bug_images
    FOR SELECT USING (
      EXISTS (
        SELECT 1 FROM public.bugs 
        JOIN public.projects ON projects.id = bugs.project_id
        WHERE bugs.id = bug_images.bug_id 
        AND projects.user_id = auth.uid()
      )
    );

  CREATE POLICY "Users can insert bug images in their projects" ON public.bug_images
    FOR INSERT WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.bugs 
        JOIN public.projects ON projects.id = bugs.project_id
        WHERE bugs.id = bug_images.bug_id 
        AND projects.user_id = auth.uid()
      )
    );

  CREATE POLICY "Users can update bug images in their projects" ON public.bug_images
    FOR UPDATE USING (
      EXISTS (
        SELECT 1 FROM public.bugs 
        JOIN public.projects ON projects.id = bugs.project_id
        WHERE bugs.id = bug_images.bug_id 
        AND projects.user_id = auth.uid()
      )
    );

  CREATE POLICY "Users can delete bug images in their projects" ON public.bug_images
    FOR DELETE USING (
      EXISTS (
        SELECT 1 FROM public.bugs 
        JOIN public.projects ON projects.id = bugs.project_id
        WHERE bugs.id = bug_images.bug_id 
        AND projects.user_id = auth.uid()
      )
    );
END $$;

-- Grant permissions
GRANT ALL ON public.bug_images TO authenticated;

-- Add comments
COMMENT ON TABLE public.bug_images IS 'Images associated with bug reports';
COMMENT ON COLUMN public.bug_images.bug_id IS 'Foreign key reference to bugs table';
COMMENT ON COLUMN public.bug_images.url IS 'Public URL of the uploaded image';
COMMENT ON COLUMN public.bug_images.path IS 'Storage path of the image file';
COMMENT ON COLUMN public.bug_images.size IS 'File size in bytes';
