-- Create profiles table and related functions
-- This migration creates the missing profiles table that the application expects

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_name ON profiles(name);

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for profiles
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to view profiles in their project teams
CREATE POLICY "Users can view profiles in their project teams" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            JOIN teams t ON t.id = tm.team_id
            WHERE tm.user_id = auth.uid()
            AND t.project_id IN (
                SELECT p.id FROM projects p
                WHERE p.user_id = auth.uid()
            )
        )
    );

-- Create function to handle new user signup and create profile
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create profile when user signs up
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function to sync existing users to profiles table
CREATE OR REPLACE FUNCTION sync_existing_users_to_profiles()
RETURNS INTEGER AS $$
DECLARE
    user_count INTEGER;
BEGIN
    INSERT INTO public.profiles (id, name, email, avatar_url)
    SELECT 
        id,
        COALESCE(raw_user_meta_data->>'name', email),
        email,
        raw_user_meta_data->>'avatar_url'
    FROM auth.users
    WHERE id NOT IN (SELECT id FROM public.profiles)
    ON CONFLICT (id) DO NOTHING;
    
    GET DIAGNOSTICS user_count = ROW_COUNT;
    RETURN user_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sync existing users to profiles table
SELECT sync_existing_users_to_profiles();

-- Create function to create profile for team member
CREATE OR REPLACE FUNCTION create_profile_for_team_member(
    user_id_param UUID,
    name_param TEXT,
    email_param TEXT,
    avatar_url_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'User not authenticated');
    END IF;
    
    -- Insert or update profile
    INSERT INTO public.profiles (id, name, email, avatar_url)
    VALUES (user_id_param, name_param, email_param, avatar_url_param)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        avatar_url = EXCLUDED.avatar_url,
        updated_at = NOW();
    
    RETURN json_build_object('success', true, 'message', 'Profile created/updated successfully');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'message', 'Error creating profile: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_profile_for_team_member(UUID, TEXT, TEXT, TEXT) TO authenticated;
