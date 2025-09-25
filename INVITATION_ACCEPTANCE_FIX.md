# Invitation Acceptance Fix

## Problem
Users were getting "Invitation accepted successfully!" message but the invitation was not being marked as accepted in the database.

## Root Causes Identified

### 1. Database Function Issue
- **Problem**: The `accept_team_invitation` function had an ambiguous column reference error
- **Error**: `column reference "user_id" is ambiguous`
- **Cause**: Variable name `user_id` conflicted with column name in `team_members` table

### 2. Frontend Timing Issue
- **Problem**: UI was refreshing data too quickly after database update
- **Cause**: Race condition where frontend refreshed before database completed the update

## Fixes Applied

### Database Fix (Migration: 20250127000002)
```sql
-- Fixed the accept_team_invitation function
-- Changed variable name from 'user_id' to 'current_user_id' to avoid ambiguity
CREATE OR REPLACE FUNCTION accept_team_invitation(invitation_token TEXT)
-- ... (see migration file for full implementation)
```

### Frontend Fix (AuthContext.tsx)
```typescript
// Added 500ms delay before refreshing data
await new Promise(resolve => setTimeout(resolve, 500))
await fetchInvitations()
await fetchProjects()
```

## Expected Behavior After Fix

1. ✅ User clicks "Accept" on invitation
2. ✅ Database function runs successfully (no ambiguous column error)
3. ✅ Invitation status changes from 'pending' to 'accepted'
4. ✅ User is added to the team
5. ✅ UI refreshes after delay (prevents race condition)
6. ✅ Accepted invitation disappears from pending list (correct behavior!)

## Migration Files Created

1. **20250127000001** - Add token column to team_invitations
2. **20250127000002** - Fix accept_team_invitation function
3. **20250127000003** - Document timing fix

## Testing

To verify the fix works:
1. Create a team invitation
2. Accept the invitation as the invited user
3. Check that:
   - Success message appears
   - Invitation disappears from pending list
   - User can access the project
   - Database shows status as 'accepted'

## Notes

- The invitation disappearing from the list is **correct behavior**
- Only pending invitations are shown in the UI
- Accepted invitations should not appear in the pending list
- The 500ms delay is necessary to prevent race conditions
