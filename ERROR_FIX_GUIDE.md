# Error Fix Guide

This guide will help you fix the errors you're experiencing with bug images and comments.

## Issues Identified

1. **404 Error for resource loading** - Missing database tables
2. **Comments fetching error** - `bug_comments` table doesn't exist
3. **StorageApiError: Bucket not found** - `bug-images` storage bucket doesn't exist
4. **Database schema mismatch** - `bug_images` table has wrong column names

## Fix Steps

### Step 1: Fix Database Schema

Run the following SQL in your Supabase SQL Editor:

```sql
-- Copy and paste the contents of fix-database-issues.sql
```

This will:
- Drop and recreate the `bug_images` table with correct column names
- Create the missing `bug_comments` table
- Set up proper RLS policies for both tables

### Step 2: Create Storage Bucket

Run the following SQL in your Supabase SQL Editor:

```sql
-- Copy and paste the contents of fix-storage-bucket.sql
```

This will:
- Create the `bug-images` storage bucket
- Set up storage policies for image uploads
- Configure file size limits and allowed MIME types

### Step 3: Verify the Fix

After running both SQL scripts:

1. **Check Database Tables**:
   - Go to your Supabase dashboard → Table Editor
   - Verify `bug_images` table exists with columns: `id`, `bug_id`, `url`, `name`, `size`, `path`, `created_at`
   - Verify `bug_comments` table exists with columns: `id`, `bug_id`, `author`, `content`, `attachments`, `created_at`, `updated_at`

2. **Check Storage Bucket**:
   - Go to your Supabase dashboard → Storage
   - Verify `bug-images` bucket exists and is public

3. **Test the Application**:
   - Navigate to a bug details page
   - Try uploading an image
   - Try adding a comment
   - Check browser console for any remaining errors

## What Was Fixed

### Database Schema Issues
- **Before**: `bug_images` table had columns `image_url`, `image_name`, `image_size`
- **After**: `bug_images` table now has columns `url`, `name`, `size`, `path`

### Missing Tables
- **Added**: `bug_comments` table for storing comments on bugs
- **Added**: Proper RLS policies for both tables

### Storage Issues
- **Added**: `bug-images` storage bucket
- **Added**: Storage policies for authenticated users
- **Added**: File size limits (50MB) and MIME type restrictions

### Code Improvements
- **Fixed**: `handleAddComment` function now properly saves comments to database
- **Fixed**: Image upload functionality now works with correct database schema
- **Fixed**: Proper error handling and user feedback

## Files Modified

1. **Database Migrations**:
   - `supabase/migrations/20250127000006_fix_bug_images_and_comments.sql`
   - `supabase/migrations/20250127000007_create_bug_images_storage.sql`

2. **Application Code**:
   - `components/bug-details-content.tsx` - Fixed comment handling

3. **Fix Scripts**:
   - `fix-database-issues.sql` - Manual database fix
   - `fix-storage-bucket.sql` - Manual storage bucket fix

## Troubleshooting

If you still encounter issues:

1. **Check Supabase Connection**:
   - Verify your environment variables are set correctly
   - Check that your Supabase project is running

2. **Check RLS Policies**:
   - Ensure you're logged in as a user with proper permissions
   - Verify the user has access to the project containing the bug

3. **Check Storage Permissions**:
   - Ensure the storage bucket is public
   - Verify storage policies are correctly applied

4. **Clear Browser Cache**:
   - Hard refresh the page (Ctrl+F5 or Cmd+Shift+R)
   - Clear browser cache and cookies

## Next Steps

After applying these fixes:

1. Test image uploads on existing bugs
2. Test comment functionality
3. Verify that images display correctly
4. Check that all error messages are resolved

The application should now work without the reported errors!
