# 🚨 Supabase Configuration Fix

## The Problem
You're seeing a "Network error" when trying to create a project. This is because Supabase is not properly configured.

## Quick Fix

### Step 1: Create Environment File
Create a `.env.local` file in your project root with the following content:

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://noiegksrvddmkbabkrux.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_actual_anon_key_here
```

### Step 2: Get Your Supabase Keys
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (ID: `noiegksrvddmkbabkrux`)
3. Go to **Settings** > **API**
4. Copy the following values:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **anon/public key** → `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### Step 3: Set Up Database Schema
1. In your Supabase dashboard, go to **SQL Editor**
2. Copy and paste the contents of the latest migration file into the SQL editor:
   - Use: `supabase/migrations/20250925160547_create_initial_schema.sql`
3. Click **Run** to execute the schema

### Step 4: Restart Development Server
```bash
npm run dev
```

## Alternative: Use Static Data (Temporary)
If you want to test the UI without Supabase setup, the app will show more helpful error messages but still allow you to see the interface.

## Error Messages You Might See

### "Supabase not configured"
- **Cause**: Missing or incorrect environment variables
- **Fix**: Create `.env.local` file with correct Supabase credentials

### "User not authenticated"
- **Cause**: User is not logged in
- **Fix**: Log in to the application first

### "Projects table does not exist"
- **Cause**: Database schema not set up
- **Fix**: Run the database migration in Supabase SQL Editor

### "Network error" or "Failed to fetch"
- **Cause**: Connection issues or wrong Supabase URL
- **Fix**: Check your internet connection and verify Supabase URL

## Testing the Fix
After completing the setup:
1. Try creating a new project
2. You should see success instead of error messages
3. The project should appear in your sidebar dropdown

## Still Having Issues?
1. Check the browser console for detailed error messages
2. Verify your Supabase project is active and accessible
3. Ensure the database schema has been applied correctly
4. Check that your environment variables are correctly set

The improved error handling will now provide more specific guidance based on the type of error encountered.
