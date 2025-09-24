# 🔧 Project Creation Fix Guide

## The Problem
You're getting a 400 error when trying to create a new project because the `projects` table doesn't exist in your Supabase database yet.

## The Solution
You need to run the complete database schema to create the `projects` table and all related tables with proper permissions.

## Step 1: Set Up Database Schema

### Option A: Run Complete Schema (Recommended)
1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Navigate to your project
3. Go to **SQL Editor** in the left sidebar
4. Copy and paste the **entire contents** of `db-schemas/complete-schema.sql` into the SQL editor
5. Click **Run** to execute the complete schema

### Option B: Run Projects Schema Only
If you only want to add the projects table:
1. Go to **SQL Editor** in your Supabase dashboard
2. Copy and paste the contents of `db-schemas/projects-schema.sql` into the SQL editor
3. Click **Run** to execute the schema

## Step 2: Verify Environment Variables

Make sure your `.env.local` file contains:
```bash
NEXT_PUBLIC_SUPABASE_URL=https://noiegksrvddmkbabkrux.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_actual_anon_key_here
```

## Step 3: Test the Fix

1. Restart your development server:
   ```bash
   npm run dev
   ```

2. Navigate to the dashboard
3. Try creating a new project
4. Check the browser console for any error messages

## What the Schema Creates

The complete schema will create:
- ✅ `projects` table with proper RLS policies
- ✅ `teams` table for project teams
- ✅ `team_members` junction table
- ✅ Updated `bugs` and `todos` tables with `project_id` foreign keys
- ✅ All necessary RLS policies for security
- ✅ Triggers for automatic project assignment
- ✅ Indexes for better performance

## Troubleshooting

### If you still get 400 errors:
1. **Check browser console** for specific error messages
2. **Verify the projects table exists** in your Supabase dashboard (Table Editor)
3. **Check RLS policies** are enabled and working
4. **Restart your development server** after schema changes

### If you get permission errors:
1. **Check RLS policies** are created correctly
2. **Verify user authentication** is working
3. **Check database permissions** in Supabase dashboard

### If projects table doesn't exist:
1. **Run the complete schema** from `complete-schema.sql`
2. **Check for SQL errors** in the Supabase SQL editor
3. **Verify all tables were created** in the Table Editor

## Expected Behavior After Fix

After running the schema, you should be able to:
- ✅ Create new projects through the modal
- ✅ See projects in the sidebar
- ✅ Switch between projects
- ✅ Projects persist after page refresh
- ✅ No more 400 errors in console

## Quick Verification

To verify the fix worked:
1. Open browser console (F12)
2. Try creating a project
3. You should see "Project created successfully" in console
4. No 400 errors should appear
5. Project should appear in the sidebar

## Need Help?

If you're still having issues:
1. Check the browser console for specific error messages
2. Verify your Supabase project URL and API key
3. Make sure you're logged in to the application
4. Check that all database tables were created successfully
