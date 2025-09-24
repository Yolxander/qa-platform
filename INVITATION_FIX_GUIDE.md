# Invitation System Fix Guide

## 🚨 Current Issue
You're getting **500 Internal Server Error** when trying to fetch invitations because the database functions are missing.

## ✅ Solution

### Step 1: Run the Database Setup Script

1. **Open your Supabase Dashboard**
   - Go to your Supabase project
   - Navigate to the SQL Editor

2. **Copy and paste the setup script**
   ```bash
   # In your terminal, run this command to copy the script:
   cat db-schemas/functions/complete-invitations-setup.sql
   ```

3. **Execute the script in Supabase SQL Editor**
   - Paste the contents into the SQL Editor
   - Click "Run" to execute

### Step 2: Verify the Setup

1. **Test the functions**
   ```bash
   # Copy this script and run it in Supabase SQL Editor:
   cat db-schemas/functions/test-functions.sql
   ```

2. **Expected results:**
   - ✅ get_user_invitations function exists
   - ✅ create_team_invitation function exists  
   - ✅ accept_team_invitation function exists
   - ✅ team_invitations table exists

### Step 3: Test the Application

1. **Restart your Next.js app** (if running)
   ```bash
   npm run dev
   ```

2. **Log in and test**
   - Log in to your application
   - Check the notifications page at `/notifications`
   - The 500 errors should be resolved

## 🔧 Alternative: Quick Fix Script

If you only want to create the missing functions:

```bash
# Copy and run this script in Supabase SQL Editor:
cat db-schemas/functions/fix-invitations-functions.sql
```

## 📋 What the Scripts Do

### `db-schemas/functions/complete-invitations-setup.sql`
- Creates the `team_invitations` table
- Sets up all indexes and RLS policies
- Creates all required functions:
  - `get_user_invitations()` - Fetches user's pending invitations
  - `create_team_invitation()` - Creates new invitations
  - `accept_team_invitation()` - Accepts invitations and adds user to team
- Sets up proper permissions and triggers

### `db-schemas/functions/fix-invitations-functions.sql`
- Only creates the missing functions
- Use this if the table already exists but functions are missing

### `db-schemas/functions/test-functions.sql`
- Verifies that all functions and tables exist
- Shows the table structure
- Use this to confirm the setup worked

## 🐛 Troubleshooting

### If you still get 500 errors:
1. Check the browser console for specific error messages
2. Run `test-functions.sql` to verify functions exist
3. Make sure you're logged in to the application
4. Check that your Supabase environment variables are correct

### If functions still don't exist:
1. Make sure you ran the script in the correct Supabase project
2. Check for any SQL errors in the Supabase SQL Editor
3. Try running `fix-invitations-functions.sql` instead

### If you get permission errors:
1. Make sure you're running the script as the database owner
2. Check that RLS policies are properly set up
3. Verify your user has the correct permissions

## ✅ Success Indicators

After running the setup script, you should see:
- No more 500 errors in the browser console
- The notifications page loads without errors
- Invitation notifications work properly
- The notification badge appears in the sidebar when there are pending invitations

## 📞 Need Help?

If you're still having issues:
1. Check the browser console for specific error messages
2. Run the test script to verify what's missing
3. Make sure all environment variables are set correctly
4. Verify you're using the correct Supabase project
