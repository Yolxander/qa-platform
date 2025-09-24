# 🚀 Supabase Setup Instructions

## The Issue
You're getting a 404 error because Supabase environment variables are not configured. Here's how to fix it:

## Step 1: Create Environment File

Create a `.env.local` file in your project root with the following content:

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://noiegksrvddmkbabkrux.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_actual_anon_key_here
```

## Step 2: Get Your Supabase Keys

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (ID: `noiegksrvddmkbabkrux`)
3. Go to **Settings** > **API**
4. Copy the following values:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **anon/public key** → `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Step 3: Set Up Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Copy and paste the contents of `supabase-schema.sql` into the SQL editor
3. Click **Run** to execute the schema

## Step 4: Test the Connection

1. Restart your development server:
   ```bash
   npm run dev
   ```

2. Navigate to `/my-todos` and try creating a todo
3. You should see success messages instead of 404 errors

## Alternative: Use Static Data (Temporary)

If you want to test the forms without Supabase setup:

1. The app will automatically fall back to static data
2. Forms will show a "Database not configured" error
3. You can still see the UI and form functionality

## Troubleshooting

### If you still get 404 errors:
1. **Check your environment variables** are correctly set
2. **Restart your development server** after adding `.env.local`
3. **Verify the Supabase project URL** is correct
4. **Check browser console** for specific error messages

### If the database schema is missing:
1. **Run the SQL schema** from `supabase-schema.sql`
2. **Check RLS policies** are enabled
3. **Verify table permissions** in Supabase dashboard

## Quick Test

After setup, you should be able to:
- ✅ Create new todos
- ✅ Use quick add for multiple todos  
- ✅ Assign tasks to team members
- ✅ See real-time data updates

The app will work with both Supabase (recommended) and static data fallback.
