# Team Invitation System Setup

This document explains how to set up and use the new team invitation notification system.

## Features

- **Invitation Notifications**: Users receive notifications when invited to team projects
- **Real-time Count**: Notification badge shows pending invitation count in sidebar
- **Accept/Decline**: Users can accept or decline invitations from the notifications page
- **Automatic Team Joining**: Accepting an invitation automatically adds the user to the project team
- **Expiration Handling**: Invitations expire after 7 days with visual indicators

## Setup Instructions

### 1. Database Setup

Run the following SQL script in your Supabase SQL Editor:

```bash
# Copy and paste the contents of setup-team-invitations.sql into Supabase SQL Editor
cat setup-team-invitations.sql
```

This script creates:
- `team_invitations` table
- Required indexes and RLS policies
- Database functions for invitation management
- Proper permissions

### 2. Verify Installation

Run the test script to verify everything is set up correctly:

```bash
node test-invitations.js
```

### 3. Start the Application

```bash
npm run dev
```

## How It Works

### For Project Owners (Inviting Users)

1. Go to the Teams page
2. Click "Add Team Member"
3. Enter the user's email and role
4. The system creates an invitation that expires in 7 days

### For Invited Users

1. **Login**: When a user logs in, the system automatically fetches their pending invitations
2. **Notification Badge**: The sidebar shows a red badge with the count of pending invitations
3. **Notifications Page**: Click on "Notifications" in the user dropdown to view all invitations
4. **Accept/Decline**: Users can accept or decline invitations directly from the notifications page
5. **Auto-Join**: Accepting an invitation automatically adds the user to the project team

### Database Schema

#### team_invitations Table

```sql
CREATE TABLE team_invitations (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  role TEXT DEFAULT 'developer',
  project_id UUID REFERENCES projects(id),
  invited_by UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'pending',
  token TEXT UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
);
```

#### Key Functions

- `create_team_invitation()`: Creates new invitations
- `accept_team_invitation()`: Accepts invitations and adds user to team
- `get_user_invitations()`: Retrieves user's pending invitations

## API Endpoints

### GET /api/invitations
Returns all pending invitations for the authenticated user.

### POST /api/invitations
Creates a new team invitation.

**Body:**
```json
{
  "email": "user@example.com",
  "name": "User Name",
  "role": "developer",
  "projectId": "project-uuid"
}
```

### PUT /api/invitations/[id]
Accepts or declines an invitation.

**Body:**
```json
{
  "action": "accept" // or "decline"
}
```

## User Interface

### Sidebar Notification
- Shows red badge with invitation count
- Clicking navigates to notifications page

### Notifications Page (/notifications)
- Lists all pending invitations
- Shows expired invitations separately
- Accept/decline buttons for each invitation
- Project and inviter information

## Security Features

- **Row Level Security**: Users can only see invitations sent to their email
- **Project Ownership**: Only project owners can create invitations
- **Token-based**: Each invitation has a unique token for security
- **Expiration**: Invitations automatically expire after 7 days
- **Authentication**: All endpoints require valid authentication

## Testing

### Manual Testing

1. Create two user accounts
2. Create a project with one user
3. Invite the second user to the project
4. Log in as the second user
5. Check notification badge appears
6. Go to notifications page
7. Accept the invitation
8. Verify user is added to the project team

### Automated Testing

Run the test script:
```bash
node test-invitations.js
```

## Troubleshooting

### Common Issues

1. **"team_invitations table does not exist"**
   - Run the setup-team-invitations.sql script in Supabase

2. **"Permission denied" errors**
   - Check RLS policies are properly set up
   - Verify user authentication

3. **401 Unauthorized errors**
   - This is expected when not logged in
   - Make sure you are logged in to the application
   - Check that the authorization header is being sent properly
   - Verify your session is valid

4. **Invitations not appearing**
   - Check user email matches invitation email exactly
   - Verify invitation hasn't expired
   - Check browser console for API errors
   - Ensure you are logged in

5. **Notification badge not updating**
   - Refresh the page
   - Check AuthContext is properly fetching invitations
   - Verify you are logged in

### Debug Steps

1. Check browser console for errors
2. Verify Supabase connection
3. Check database permissions
4. Test API endpoints directly
5. Verify user authentication state

## Future Enhancements

- Email notifications for new invitations
- Bulk invitation management
- Invitation templates
- Advanced role management
- Invitation analytics
