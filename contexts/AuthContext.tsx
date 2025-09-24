'use client'

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { User } from '@supabase/supabase-js'
import { auth } from '@/lib/auth'
import { Project, supabase } from '@/lib/supabase'

export interface TeamInvitation {
  id: string
  email: string
  name: string | null
  role: string
  project_id: string
  invited_by: string
  status: string
  token: string
  expires_at: string
  created_at: string
  project_name: string
  inviter_name: string
}

interface AuthContextType {
  user: User | null
  loading: boolean
  projects: Project[]
  currentProject: Project | null
  invitations: TeamInvitation[]
  pendingInvitationsCount: number
  signIn: (email: string, password: string) => Promise<{ error: any }>
  signUp: (email: string, password: string, name?: string) => Promise<{ error: any; data: any }>
  signOut: () => Promise<{ error: any }>
  createProject: (name: string, description?: string) => Promise<{ error: any; data: any }>
  setCurrentProject: (project: Project | null) => void
  fetchProjects: () => Promise<void>
  fetchInvitations: () => Promise<void>
  acceptInvitation: (invitationId: string) => Promise<{ error: any }>
  declineInvitation: (invitationId: string) => Promise<{ error: any }>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [projects, setProjects] = useState<Project[]>([])
  const [currentProject, setCurrentProject] = useState<Project | null>(null)
  const [hasRestoredProject, setHasRestoredProject] = useState(false)
  const [invitations, setInvitations] = useState<TeamInvitation[]>([])
  const [pendingInvitationsCount, setPendingInvitationsCount] = useState(0)

  const fetchProjects = useCallback(async () => {
    if (!user || !supabase) return
    
    console.log('Fetching projects for user:', user.id)
    
    try {
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
    } catch (error) {
      console.error('Error fetching projects:', error)
    }
  }, [user, supabase])

  const fetchInvitations = useCallback(async () => {
    if (!user || !supabase) return
    
    console.log('Fetching invitations for user:', user.email)
    
    try {
      const { data: invitations, error } = await supabase
        .from('team_invitations')
        .select('*')
        .eq('email', user.email)
        .eq('status', 'pending')
        .gt('expires_at', new Date().toISOString())
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching invitations:', error)
        return
      }
      
      setInvitations(invitations || [])
      setPendingInvitationsCount(invitations?.length || 0)
      
      console.log('Fetched invitations:', invitations?.length || 0)
    } catch (error) {
      console.error('Error fetching invitations:', error)
    }
  }, [user, supabase])

  useEffect(() => {
    // Check localStorage on component mount
    try {
      const savedProjectId = localStorage.getItem('selectedProjectId')
      console.log('On component mount - localStorage value:', savedProjectId)
    } catch (error) {
      console.warn('Could not access localStorage on mount:', error)
    }

    // Get initial session
    const getInitialSession = async () => {
      const { session } = await auth.getCurrentSession()
      setUser(session?.user ?? null)
      setLoading(false)
    }

    getInitialSession()

    // Listen for auth changes
    const { data: { subscription } } = auth.onAuthStateChange((event, session) => {
      console.log('Auth state change:', event, session?.user?.id)
      setUser(session?.user ?? null)
      setLoading(false)
    })

    return () => subscription.unsubscribe()
  }, [])

  useEffect(() => {
    console.log('User effect triggered - user:', user?.id, 'loading:', loading)
    if (user) {
      setHasRestoredProject(false) // Reset the flag when user changes
      fetchProjects()
      fetchInvitations()
    } else if (user === null && !loading) {
      // Only clear localStorage when user is explicitly null (not undefined) and not loading
      console.log('User is null and not loading, clearing localStorage')
      setProjects([])
      setCurrentProject(null)
      setHasRestoredProject(false)
      setInvitations([])
      setPendingInvitationsCount(0)
      // Clear saved project when user logs out
      try {
        localStorage.removeItem('selectedProjectId')
      } catch (error) {
        console.warn('Could not clear localStorage:', error)
      }
    }
  }, [user, loading])

  // Handle localStorage restoration when projects are loaded
  useEffect(() => {
    if (projects.length > 0 && !hasRestoredProject) {
      console.log('Projects loaded, checking localStorage for saved project')
      console.log('Current project state:', currentProject)
      console.log('Has restored project:', hasRestoredProject)
      try {
        const savedProjectId = localStorage.getItem('selectedProjectId')
        console.log('Saved project ID from localStorage:', savedProjectId)
        console.log('Available projects:', projects.map(p => ({ id: p.id, name: p.name })))
        
        if (savedProjectId) {
          console.log('Looking for project with ID:', savedProjectId)
          console.log('Project IDs in array:', projects.map(p => p.id))
          const savedProject = projects.find(project => project.id === savedProjectId)
          console.log('Found saved project:', savedProject)
          if (savedProject) {
            console.log('Setting current project to saved project:', savedProject.name)
            setCurrentProject(savedProject)
            setHasRestoredProject(true)
            return
          } else {
            console.log('Saved project ID not found in available projects')
            console.log('Expected ID:', savedProjectId)
            console.log('Available IDs:', projects.map(p => p.id))
          }
        } else {
          console.log('No saved project ID in localStorage')
        }
      } catch (error) {
        console.warn('Could not access localStorage:', error)
      }
      
      // If no saved project or saved project not found, set the first project
      console.log('No saved project found, setting to first project:', projects[0].name)
      setCurrentProject(projects[0])
      setHasRestoredProject(true)
    }
  }, [projects, hasRestoredProject])

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
        return { error: { message: 'Database not configured. Please check your environment variables.' }, data: null }
      }

      if (!user) {
        console.error('User not authenticated')
        return { error: { message: 'User not authenticated' }, data: null }
      }

      console.log('Attempting to insert project into database...')
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
        console.error('Supabase error creating project:', error)
        console.error('Error details:', {
          code: error.code,
          message: error.message,
          details: error.details,
          hint: error.hint
        })
        
        // Provide more specific error messages
        let errorMessage = error.message
        if (error.code === 'PGRST116') {
          errorMessage = 'Projects table does not exist. Please run the database schema setup.'
        } else if (error.code === '42501') {
          errorMessage = 'Permission denied. Please check your database permissions.'
        } else if (error.message.includes('relation "projects" does not exist')) {
          errorMessage = 'Projects table not found. Please run the complete database schema.'
        }
        
        return { error: { message: errorMessage }, data: null }
      }

      console.log('Project created successfully:', data)
      setProjects(prev => [...prev, data])
      if (!currentProject) {
        handleSetCurrentProject(data)
      }
      return { error: null, data }
    } catch (error) {
      console.error('Network error in createProject:', error)
      return { error: { message: 'Network error. Please check your connection and try again.' }, data: null }
    }
  }

  const acceptInvitation = async (invitationId: string) => {
    try {
      if (!supabase) {
        return { error: { message: 'Database not configured' } }
      }

      // Update invitation status to accepted
      const { error: updateError } = await supabase
        .from('team_invitations')
        .update({ 
          status: 'accepted',
          updated_at: new Date().toISOString()
        })
        .eq('id', invitationId)
        .eq('email', user?.email)

      if (updateError) {
        console.error('Error accepting invitation:', updateError)
        return { error: { message: 'Failed to accept invitation' } }
      }

      // Refresh invitations and projects after accepting
      await fetchInvitations()
      await fetchProjects()
      
      return { error: null }
    } catch (error) {
      console.error('Error accepting invitation:', error)
      return { error: { message: 'Failed to accept invitation' } }
    }
  }

  const declineInvitation = async (invitationId: string) => {
    try {
      if (!supabase) {
        return { error: { message: 'Database not configured' } }
      }

      // Update invitation status to declined
      const { error: updateError } = await supabase
        .from('team_invitations')
        .update({ 
          status: 'declined',
          updated_at: new Date().toISOString()
        })
        .eq('id', invitationId)
        .eq('email', user?.email)

      if (updateError) {
        console.error('Error declining invitation:', updateError)
        return { error: { message: 'Failed to decline invitation' } }
      }

      // Refresh invitations after declining
      await fetchInvitations()
      
      return { error: null }
    } catch (error) {
      console.error('Error declining invitation:', error)
      return { error: { message: 'Failed to decline invitation' } }
    }
  }

  const handleSetCurrentProject = (project: Project | null) => {
    console.log('Setting current project to:', project?.name || 'null')
    setCurrentProject(project)
    // Save the selected project to localStorage
    try {
      if (project) {
        console.log('Saving project ID to localStorage:', project.id)
        localStorage.setItem('selectedProjectId', project.id)
        // Verify the save worked
        const saved = localStorage.getItem('selectedProjectId')
        console.log('Verification - saved value:', saved)
        console.log('Verification - matches expected:', saved === project.id)
      } else {
        console.log('Removing project ID from localStorage')
        localStorage.removeItem('selectedProjectId')
        // Verify the removal worked
        const saved = localStorage.getItem('selectedProjectId')
        console.log('Verification - saved value after removal:', saved)
      }
    } catch (error) {
      console.warn('Could not save to localStorage:', error)
    }
  }

  const value = {
    user,
    loading,
    projects,
    currentProject,
    invitations,
    pendingInvitationsCount,
    signIn,
    signUp,
    signOut,
    createProject,
    setCurrentProject: handleSetCurrentProject,
    fetchProjects,
    fetchInvitations,
    acceptInvitation,
    declineInvitation
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
