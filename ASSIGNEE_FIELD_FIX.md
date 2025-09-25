# Assignee Field Fix

## Problem
The `assignee` field in the bugs table stores UUIDs (user IDs), but the query was comparing it with email addresses, causing bugs assigned to users to not appear in their bugs list.

## Root Cause
- **Database Schema**: `assignee` field is `character varying` but stores UUIDs
- **Query Issue**: Comparing `assignee` with `user.email` instead of `user.id`
- **Result**: Assigned bugs were not showing up for invited users

## Solution Implemented

### Fixed Query Logic
**Before**: `assignee.eq.${user.email}` (comparing UUID with email)  
**After**: `assignee.eq.${user.id}` (comparing UUID with UUID)

### Components Updated
1. **Bugs Page** (`app/bugs/page.tsx`)
2. **Bulk Bug Actions** (`components/bulk-bug-actions-form.tsx`)  
3. **New Todo Form** (`components/new-todo-form.tsx`)

### Database Query
```typescript
// Correct query logic
query = query.or(`user_id.eq.${user.id},assignee.eq.${user.id}`)
```

This translates to SQL:
```sql
WHERE (user_id = 'user-uuid' OR assignee = 'user-uuid')
```

## Expected Behavior Now

### For Invited Users:
✅ **Bugs Created**: Shows bugs where `user_id = user.id`  
✅ **Bugs Assigned**: Shows bugs where `assignee = user.id`  
✅ **Project Filtered**: Only shows bugs from selected project  

### For Project Owners:
✅ **All Bugs**: Shows all bugs in the project (no filtering)  
✅ **Full Access**: Can see and manage all bugs  

## Testing
1. **Create Bug**: Should appear in creator's bugs list
2. **Assign Bug**: Should appear in assignee's bugs list  
3. **Switch Projects**: Should only show bugs from selected project
4. **Invited User**: Should see bugs they created or are assigned to

## Database Schema Confirmed
- `user_id`: UUID (references auth.users.id)
- `assignee`: VARCHAR (stores UUID of assigned user)
- Both fields now correctly compared with `user.id`
