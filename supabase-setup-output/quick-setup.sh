#!/bin/bash

# Quick Setup Script for Smasher Light Supabase Instance
# This script helps you set up a new Supabase instance quickly

echo "🚀 Smasher Light - Supabase Quick Setup"
echo "========================================"

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed. Please install it first:"
    echo "   npm install -g supabase"
    exit 1
fi

# Check if user is logged in
if ! supabase projects list &> /dev/null; then
    echo "❌ Not logged in to Supabase. Please login first:"
    echo "   supabase login"
    exit 1
fi

echo "✅ Supabase CLI is ready"

# Get project reference
echo ""
echo "Please enter your Supabase project reference:"
read -p "Project Ref: " PROJECT_REF

if [ -z "$PROJECT_REF" ]; then
    echo "❌ Project reference is required"
    exit 1
fi

# Link to project
echo "🔗 Linking to project..."
supabase link --project-ref $PROJECT_REF

if [ $? -eq 0 ]; then
    echo "✅ Successfully linked to project"
else
    echo "❌ Failed to link to project"
    exit 1
fi

# Apply migrations
echo "📦 Applying migrations..."
supabase db push

if [ $? -eq 0 ]; then
    echo "✅ Migrations applied successfully"
else
    echo "❌ Failed to apply migrations"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Set up storage bucket in Supabase dashboard"
echo "2. Update your .env.local with project credentials"
echo "3. Run the verification script to test setup"
echo ""
echo "For detailed instructions, see: setup-instructions.md"
