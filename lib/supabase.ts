import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'

// Check if environment variables are configured
if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
  console.warn('Supabase environment variables not configured. Using local development defaults.')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Database types
export interface User {
  id: string
  email: string
  name?: string
  avatar_url?: string
  created_at: string
  updated_at: string
}

export interface Bug {
  id: number
  title: string
  description: string
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  status: 'Open' | 'In Progress' | 'Closed' | 'Ready for QA'
  environment: 'Prod' | 'Stage' | 'Dev'
  reporter: string
  assignee: string
  created_at: string
  updated_at: string
  user_id: string
  project_id?: string
}

export interface Project {
  id: string
  name: string
  description?: string
  user_id: string
  created_at: string
  updated_at: string
  isInvited?: boolean
}

export interface Todo {
  id: number
  title: string
  issue_link?: string
  status: 'OPEN' | 'IN_PROGRESS' | 'DONE' | 'READY_FOR_QA'
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  due_date: string
  environment: 'Prod' | 'Stage' | 'Dev'
  assignee: string
  quick_action: string
  created_at: string
  updated_at: string
  user_id: string
  project_id?: string
}
