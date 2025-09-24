import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

// Check if environment variables are configured
if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase environment variables not configured. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in your .env.local file')
}

export const supabase = supabaseUrl && supabaseAnonKey 
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null

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
