# Bugs Filtering Fix

## Problem
The bugs page was not showing bugs where the logged-in user was the creator (`user_id` field), only showing bugs where they were the assignee (`assignee` field).

## Solution Implemented

### Updated Logic
**Before**: Only showed bugs where `assignee = user.email` for invited projects  
**After**: Shows bugs where user is either:
- The creator (`user_id = user.id`) 
- The assignee (`assignee = user.email`)

### Components Updated

1. **Bugs Page** (`app/bugs/page.tsx`)
   - Updated query to use `or()` condition
   - Updated page description
   - Now shows: "Bugs you created or are assigned to in {project_name}"

2. **Bulk Bug Actions Form** (`components/bulk-bug-actions-form.tsx`)
   - Updated to use same filtering logic
   - Ensures consistency across all bug-related components

3. **New Todo Form** (`components/new-todo-form.tsx`)
   - Updated bug selection to use same filtering logic
   - Only shows relevant bugs when creating todos

### Database Query
```typescript
// New query logic
query = query.or(`user_id.eq.${user.id},assignee.eq.${user.email}`)
```

This translates to SQL:
```sql
WHERE (user_id = 'user-uuid' OR assignee = 'user@email.com')
```

## Expected Behavior

### For All Users (Project Owners & Invited Users):
✅ **Bugs Created**: Shows bugs where `user_id = current_user.id`  
✅ **Bugs Assigned**: Shows bugs where `assignee = current_user.email`  
✅ **Project Filtered**: Only shows bugs from the currently selected project  
✅ **Consistent**: Same filtering logic across all components  

### Benefits:
- **Complete View**: Users see all bugs they're involved with
- **No Duplicates**: OR condition prevents duplicate bugs
- **Project Scoped**: Only shows bugs from selected project
- **Consistent UX**: Same behavior across all bug-related features

## Testing
1. Create a bug as a user - should appear in bugs list
2. Get assigned to a bug - should appear in bugs list  
3. Switch projects - should only see bugs from selected project
4. Check bulk actions - should only show relevant bugs
5. Create todo - should only show relevant bugs for linking
