'use client'

import React, { createContext, useContext, useEffect, useState } from 'react'
import { User } from '@supabase/supabase-js'
import { auth } from '@/lib/auth'
import { Project, supabase } from '@/lib/supabase'

interface AuthContextType {
  user: User | null
  loading: boolean
  projects: Project[]
  currentProject: Project | null
  signIn: (email: string, password: string) => Promise<{ error: any }>
  signUp: (email: string, password: string, name?: string) => Promise<{ error: any; data: any }>
  signOut: () => Promise<{ error: any }>
  createProject: (name: string, description?: string) => Promise<{ error: any; data: any }>
  setCurrentProject: (project: Project | null) => void
  fetchProjects: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [projects, setProjects] = useState<Project[]>([])
  const [currentProject, setCurrentProject] = useState<Project | null>(null)

  const fetchProjects = async () => {
    if (!user) return
    
    try {
      if (!supabase) {
        console.warn('Supabase not configured')
        return
      }

      const { data, error } = await supabase
        .from('projects')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching projects:', error)
        return
      }

      setProjects(data || [])
      if (data && data.length > 0 && !currentProject) {
        setCurrentProject(data[0])
      }
    } catch (error) {
      console.error('Error fetching projects:', error)
    }
  }

  useEffect(() => {
    // Get initial session
    const getInitialSession = async () => {
      const { session } = await auth.getCurrentSession()
      setUser(session?.user ?? null)
      setLoading(false)
    }

    getInitialSession()

    // Listen for auth changes
    const { data: { subscription } } = auth.onAuthStateChange((event, session) => {
      setUser(session?.user ?? null)
      setLoading(false)
    })

    return () => subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (user) {
      fetchProjects()
    } else {
      setProjects([])
      setCurrentProject(null)
    }
  }, [user])

  const signIn = async (email: string, password: string) => {
    const { error } = await auth.signIn(email, password)
    return { error }
  }

  const signUp = async (email: string, password: string, name?: string) => {
    const { data, error } = await auth.signUp(email, password, name)
    return { data, error }
  }

  const signOut = async () => {
    const { error } = await auth.signOut()
    return { error }
  }

  const createProject = async (name: string, description?: string) => {
    try {
      console.log('Creating project:', { name, description, user: user?.id })
      
      if (!supabase) {
        console.error('Supabase not configured')
        return { error: { message: 'Database not configured' }, data: null }
      }

      if (!user) {
        console.error('User not authenticated')
        return { error: { message: 'User not authenticated' }, data: null }
      }

      const { data, error } = await supabase
        .from('projects')
        .insert({
          name: name.trim(),
          description: description?.trim() || null,
          user_id: user.id
        })
        .select()
        .single()

      if (error) {
        console.error('Error creating project:', error)
        return { error: { message: error.message }, data: null }
      }

      console.log('Project created successfully:', data)
      setProjects(prev => [...prev, data])
      if (!currentProject) {
        setCurrentProject(data)
      }
      return { error: null, data }
    } catch (error) {
      console.error('Error in createProject:', error)
      return { error: { message: 'Network error' }, data: null }
    }
  }

  const value = {
    user,
    loading,
    projects,
    currentProject,
    signIn,
    signUp,
    signOut,
    createProject,
    setCurrentProject,
    fetchProjects
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
