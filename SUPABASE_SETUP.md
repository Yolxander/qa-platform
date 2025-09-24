# Supabase Setup Guide

## 🚀 Quick Setup Instructions

### 1. Database Schema Setup

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Navigate to your project: `noiegksrvddmkbabkrux`
3. Go to **SQL Editor** in the left sidebar
4. Copy and paste the contents of `supabase-schema.sql` into the SQL editor
5. Click **Run** to execute the schema

### 2. Authentication Setup

1. In your Supabase dashboard, go to **Authentication** > **Settings**
2. Configure the following:
   - **Site URL**: `http://localhost:3000` (for development)
   - **Redirect URLs**: Add `http://localhost:3000/dashboard`
3. Enable **Email confirmations** if you want email verification
4. Configure **Password requirements** as needed

### 3. Row Level Security (RLS)

The schema includes RLS policies that:
- Users can only see their own data
- Users can create, read, update, and delete their own bugs and todos
- All users can view all bugs and todos (for collaboration)

### 4. Test the Setup

1. Start your development server:
   ```bash
   npm run dev
   ```

2. Navigate to `http://localhost:3000/register`
3. Create a new account
4. You should be redirected to the dashboard
5. Try creating a bug or todo to test CRUD operations

## 🔧 API Endpoints

Your app now has the following API endpoints:

### Bugs
- `GET /api/bugs` - Get all bugs
- `POST /api/bugs` - Create a new bug
- `GET /api/bugs/[id]` - Get a specific bug
- `PUT /api/bugs/[id]` - Update a bug
- `DELETE /api/bugs/[id]` - Delete a bug

### Todos
- `GET /api/todos` - Get all todos
- `POST /api/todos` - Create a new todo
- `GET /api/todos/[id]` - Get a specific todo
- `PUT /api/todos/[id]` - Update a todo
- `DELETE /api/todos/[id]` - Delete a todo

## 🛡️ Security Features

- **Row Level Security (RLS)** enabled on all tables
- **Authentication required** for all protected routes
- **User-specific data access** - users can only modify their own data
- **Automatic user profile creation** when users sign up

## 🚀 Next Steps

1. **Run the SQL schema** in your Supabase dashboard
2. **Test authentication** by registering and logging in
3. **Test CRUD operations** by creating bugs and todos
4. **Customize the UI** to match your needs

## 📝 Notes

- The app uses static data files for now, but you can easily switch to Supabase data by updating the components
- All authentication is handled by Supabase
- The database schema supports the existing data structure
- RLS policies ensure data security

## 🔍 Troubleshooting

If you encounter issues:

1. **Check environment variables** in `.env.local`
2. **Verify Supabase project settings**
3. **Check browser console** for errors
4. **Ensure RLS policies are properly set up**

Your Supabase integration is now complete! 🎉
