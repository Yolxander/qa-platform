# Database Schemas

This folder contains all the database schema files for the Smasher Light application.

## Schema Files

### `complete-schema.sql`
**Main schema file** - Contains the complete database structure including:
- All tables (profiles, projects, bugs, todos)
- Indexes for performance
- Row Level Security (RLS) policies
- Functions and triggers
- Permissions

**Usage**: Run this file to set up the complete database structure.

### `supabase-schema.sql`
**Original schema** - The initial database schema with basic tables and policies.

### `projects-schema.sql`
**Projects schema** - Contains the projects table and related policies.

### `add-project-id-to-todos.sql`
**Todos project integration** - Adds project_id column to todos table with:
- Foreign key constraint to projects table
- RLS policies for project-based access
- Automatic project assignment for new todos
- Performance indexes

### `add-project-id-to-bugs.sql`
**Bugs project integration** - Adds project_id column to bugs table with:
- Foreign key constraint to projects table
- RLS policies for project-based access
- Automatic project assignment for new bugs
- Performance indexes

## Database Structure

### Tables

1. **profiles** - User profiles extending auth.users
2. **projects** - Project management and organization
3. **bugs** - Bug reports and issue tracking
4. **todos** - Task management and todo items

### Key Features

- **Project-based organization**: All bugs and todos are linked to projects
- **Row Level Security**: Users can only access their own data and project data
- **Automatic project assignment**: New items get assigned to user's default project
- **Performance optimized**: Includes proper indexing
- **Audit trails**: Created/updated timestamps on all tables

## Setup Instructions

1. **For new installations**: Run `complete-schema.sql`
2. **For existing installations**: Run the individual schema files as needed
3. **For project integration**: Run `add-project-id-to-todos.sql` and `add-project-id-to-bugs.sql`

## Security

All tables use Row Level Security (RLS) with policies that ensure:
- Users can only access their own data
- Project-based access control
- Secure data isolation between users
- Proper authentication requirements

## Performance

The schema includes optimized indexes for:
- Project-based queries
- User-based filtering
- Common search patterns
- Foreign key relationships
