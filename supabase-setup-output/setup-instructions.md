# Smasher Light - Supabase Setup Instructions

## Prerequisites

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**
   ```bash
   supabase login
   ```

## Setup Steps

### Step 1: Create New Supabase Project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Choose your organization
4. Enter project name: "smasher-light" (or your preferred name)
5. Set a strong database password
6. Choose a region close to your users
7. Click "Create new project"

### Step 2: Get Project Credentials

1. In your new project dashboard, go to Settings > API
2. Copy the following values:
   - Project URL
   - Anon public key
   - Service role key (optional, for server-side operations)

### Step 3: Apply Database Migrations

**Option A: Using Supabase Dashboard (Recommended)**
1. Go to your project dashboard
2. Navigate to SQL Editor
3. Copy the contents of `consolidated-migration.sql`
4. Paste and run the SQL

**Option B: Using Supabase CLI**
```bash
# Link to your project
supabase link --project-ref your-project-ref

# Apply migrations
supabase db push
```

### Step 4: Set Up Storage

1. In your Supabase dashboard, go to Storage
2. Create a new bucket named "bug-images"
3. Set it as public
4. Run the `storage-setup.sql` script in the SQL Editor

### Step 5: Configure Environment Variables

1. Copy `.env.template` to `.env.local` in your project root
2. Update the values with your Supabase project credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```

### Step 6: Verify Setup

1. Run the `verification.sql` script in your Supabase SQL Editor
2. All checks should return "PASS"

### Step 7: Test the Application

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the development server:
   ```bash
   npm run dev
   ```

3. Open http://localhost:3000 in your browser
4. Try creating an account and creating a project

## Troubleshooting

### Common Issues

1. **RLS Policies Not Working**
   - Ensure all tables have RLS enabled
   - Check that policies are created correctly
   - Verify user authentication is working

2. **Storage Upload Issues**
   - Check bucket permissions
   - Verify storage policies are set up
   - Ensure bucket is public if needed

3. **Authentication Issues**
   - Check that auth is enabled in Supabase
   - Verify email settings in Auth configuration
   - Check redirect URLs

### Getting Help

- Check the Supabase documentation: https://supabase.com/docs
- Review the migration files for specific table structures
- Check the verification script output for any failed checks

## Files Generated

- `consolidated-migration.sql` - All database migrations in one file
- `storage-setup.sql` - Storage bucket and policies setup
- `verification.sql` - Script to verify setup is correct
- `.env.template` - Environment variables template
- `setup-instructions.md` - This file

## Next Steps

After successful setup:

1. Update your application's environment variables
2. Test all functionality (user registration, project creation, team management)
3. Set up any additional configurations (email templates, etc.)
4. Deploy your application

Happy coding! 🚀
