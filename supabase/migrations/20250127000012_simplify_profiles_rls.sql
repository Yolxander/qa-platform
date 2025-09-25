-- Simplify profiles RLS policies to fix 406 errors
-- This migration simplifies the complex RLS policies that are causing 406 errors

-- Drop all existing profiles policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in their project teams" ON profiles;

-- Create simplified policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow authenticated users to view all profiles (for team member selection)
CREATE POLICY "Authenticated users can view all profiles" ON profiles
    FOR SELECT USING (auth.uid() IS NOT NULL);
