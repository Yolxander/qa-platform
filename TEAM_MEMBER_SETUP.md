# Team Member Setup Guide

This guide will help you fix the permission issues with the "Add Team Member" functionality and set up the modal form properly.

## Problem Description

The errors you're seeing (406/403) are caused by Row Level Security (RLS) policies that are too restrictive:

1. **406 Error**: The form tries to query all profiles to show available users, but RLS only allows users to view their own profile
2. **403 Error**: When creating a new profile for a team member, the RLS policy prevents inserting profiles for other users

## Solution

### Step 1: Run the Permission Fix Script

1. Open your Supabase Dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `fix-team-member-permissions.sql`
4. Run the script

This script will:
- Remove restrictive RLS policies
- Add new flexible policies that allow team member management
- Create secure helper functions for safe team member creation
- Grant proper permissions

### Step 2: Verify the Fix

After running the script, test the functionality:

1. Go to your Teams page
2. Click "Add Team Member"
3. Try adding a new team member

The form should now work without 406/403 errors.

## What the Fix Does

### 1. Updated RLS Policies

**Before (Restrictive):**
```sql
-- Only allows users to view their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
```

**After (Flexible):**
```sql
-- Allows users to view profiles in their project teams + all profiles for adding members
CREATE POLICY "Users can view profiles in their project teams" ON public.profiles
  FOR SELECT USING (
    auth.uid() = id OR
    EXISTS (SELECT 1 FROM public.team_members tm ...) OR
    EXISTS (SELECT 1 FROM public.projects WHERE projects.user_id = auth.uid())
  );
```

### 2. Secure Helper Functions

The script creates two secure functions:

- `create_profile_for_team_member()`: Safely creates profiles for team members
- `add_team_member_safely()`: Adds team members with proper permission checks

### 3. Updated Form Component

The form now uses the secure RPC function instead of direct database queries:

```typescript
const { data, error } = await supabase.rpc('add_team_member_safely', {
  member_email: formData.email,
  member_name: formData.name,
  member_role: formData.role,
  project_id_param: currentProject.id
})
```

## Security Benefits

1. **Permission Checks**: Functions verify the user has access to the project before allowing team member creation
2. **Safe Profile Creation**: Profiles are created with proper validation
3. **Duplicate Prevention**: The system prevents adding the same user twice
4. **Audit Trail**: All operations are logged and traceable

## Testing the Fix

1. **Test Profile Loading**: The dropdown should now show available users without 406 errors
2. **Test New Member Creation**: Adding a new team member should work without 403 errors
3. **Test Duplicate Prevention**: Try adding the same user twice - should show appropriate error
4. **Test Permission Checks**: Try adding members to projects you don't own - should be denied

## Troubleshooting

### If you still get 406/403 errors:

1. **Check RLS Policies**: Run this query to verify policies exist:
   ```sql
   SELECT policyname FROM pg_policies 
   WHERE tablename = 'profiles' AND schemaname = 'public';
   ```

2. **Check Function Permissions**: Verify functions exist:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_schema = 'public' 
   AND routine_name IN ('add_team_member_safely', 'create_profile_for_team_member');
   ```

3. **Test Function Directly**: Try calling the function directly:
   ```sql
   SELECT add_team_member_safely(
     'test@example.com',
     'Test User',
     'developer',
     'your-project-id'
   );
   ```

### If the modal doesn't appear:

1. Check that the `AddTeamMemberForm` component is properly imported
2. Verify the trigger element is wrapped correctly
3. Check browser console for JavaScript errors

## Files Modified

1. **`fix-team-member-permissions.sql`**: Database permission fixes
2. **`components/add-team-member-form.tsx`**: Updated to use secure RPC function
3. **`TEAM_MEMBER_SETUP.md`**: This setup guide

## Next Steps

After running the permission fix script, your "Add Team Member" functionality should work properly. The form will:

- Load available users without permission errors
- Create new profiles for team members safely
- Add members to teams with proper validation
- Show appropriate error messages for edge cases

The modal form is already implemented and should work seamlessly with the permission fixes.
