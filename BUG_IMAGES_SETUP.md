# Bug Images Setup Guide

This guide explains how to set up the bug image upload functionality in your Smasher Light application.

## Overview

The bug image upload feature allows users to:
- Upload multiple images for each bug report
- View uploaded images in a modal
- Delete images from bug reports
- Drag and drop images for easy upload

## Database Setup

### 1. Create the bug_images table

Run the following SQL in your Supabase SQL editor:

```sql
-- Run the contents of db-schemas/bug-images-schema.sql
```

### 2. Set up Supabase Storage

Run the following SQL in your Supabase SQL editor:

```sql
-- Run the contents of setup-bug-images-storage.sql
```

## Features

### Image Upload Modal
- **Location**: `components/bug-image-upload-modal.tsx`
- **Features**:
  - Drag and drop file upload
  - Multiple file selection
  - Image preview with delete functionality
  - File size display
  - Progress indication during upload

### Updated Bugs Table
- **Location**: `components/bugs-table.tsx`
- **Changes**:
  - Replaced message action with image action (IconPhoto)
  - Moved image action to be the first action button
  - Added image upload modal integration

### Database Schema
- **Table**: `bug_images`
- **Columns**:
  - `id`: UUID primary key
  - `bug_id`: Foreign key to bugs table
  - `url`: Public URL of the image
  - `name`: Original filename
  - `size`: File size in bytes
  - `path`: Storage path in Supabase Storage
  - `created_at`: Timestamp

### Storage Structure
- **Bucket**: `bug-images`
- **Path Pattern**: `bug-images/{bug_id}/{filename}`
- **Public Access**: Yes (with RLS policies)

## Security

### Row Level Security (RLS)
- Users can only view/upload/delete images for bugs in their own projects
- All operations are protected by RLS policies
- Storage policies ensure users can only access images from their projects

### File Validation
- Only image files are accepted (`image/*` MIME type)
- File size limits can be configured in Supabase Storage settings

## Usage

### For Users
1. Navigate to the Bugs page
2. Click the image icon (📷) in the Actions column for any bug
3. In the modal that opens:
   - Drag and drop images or click "Choose Files"
   - Select multiple images
   - Click "Upload X image(s)" to upload
   - View uploaded images in the grid below
   - Delete images by hovering and clicking the trash icon

### For Developers
The image upload functionality is fully integrated with:
- Supabase Storage for file storage
- Supabase Database for metadata
- React state management for UI updates
- Error handling and user feedback

## File Structure

```
components/
├── bug-image-upload-modal.tsx    # Image upload modal component
├── bugs-table.tsx               # Updated bugs table with image action
db-schemas/
├── bug-images-schema.sql        # Database schema for bug images
setup-bug-images-storage.sql   # Storage bucket and policies setup
```

## Troubleshooting

### Common Issues

1. **Storage bucket not found**
   - Run the `setup-bug-images-storage.sql` script
   - Ensure the bucket is created and public

2. **Permission denied errors**
   - Check that RLS policies are properly set up
   - Verify user authentication

3. **Images not displaying**
   - Check that the storage bucket is public
   - Verify the URL generation in the component

### Testing

1. Create a test bug
2. Click the image action button
3. Upload a test image
4. Verify the image appears in the modal
5. Check that the image is stored in Supabase Storage
6. Verify the database record is created

## Future Enhancements

Potential improvements:
- Image compression before upload
- Thumbnail generation
- Image annotation tools
- Bulk image operations
- Image search and filtering
