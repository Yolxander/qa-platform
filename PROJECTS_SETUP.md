# 🚀 Projects Setup Guide

## The Issue
Projects are not being created because the `projects` table doesn't exist in your Supabase database yet.

## Step 1: Create the Projects Table

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Navigate to your project
3. Go to **SQL Editor** in the left sidebar
4. Copy and paste the contents of `projects-schema.sql` into the SQL editor
5. Click **Run** to execute the schema

## Step 2: Verify Environment Variables

Make sure your `.env.local` file contains:

```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Step 3: Test the Setup

1. Restart your development server:
   ```bash
   npm run dev
   ```

2. Navigate to the dashboard
3. Try creating a new project
4. Check the browser console for any error messages

## Troubleshooting

### If you get "relation 'projects' does not exist" error:
- The `projects` table hasn't been created yet
- Run the SQL schema from `projects-schema.sql`

### If you get "permission denied" error:
- Check that RLS policies are created
- Verify the user is authenticated

### If you get "Database not configured" error:
- Check your `.env.local` file exists and has correct values
- Restart your development server

## Quick Test

After setup, you should be able to:
- ✅ See "Add New Project" message when no projects exist
- ✅ Create new projects through the modal
- ✅ Switch between projects in the sidebar
- ✅ Projects persist after page refresh

## Debug Information

If projects still aren't being created, check:
1. Browser console for error messages
2. Network tab for API response details
3. Supabase dashboard for table existence
4. RLS policies are enabled
