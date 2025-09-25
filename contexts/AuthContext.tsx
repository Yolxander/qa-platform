'use client'

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { User } from '@supabase/supabase-js'
import { auth } from '@/lib/auth'
import { Project, supabase } from '@/lib/supabase'
import { toast } from 'sonner'

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
    
    try {
      // Get user's own projects
      const { data: ownedProjects, error: ownedError } = await supabase
        .from('projects')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })

      if (ownedError) {
        console.error('Error fetching owned projects:', ownedError)
        return
      }

      // Get invited projects using a completely separate approach
      const invitedProjects = await fetchInvitedProjects()

      // Combine and mark projects
      const allProjects = [
        ...(ownedProjects || []).map(p => ({ ...p, isInvited: false })),
        ...(invitedProjects.map(p => ({ ...p, isInvited: true })))
      ]

      // Final deduplication to ensure no project appears twice (should be rare but safety check)
      const uniqueAllProjects = allProjects.reduce((acc, project) => {
        const existingProject = acc.find(p => p.id === project.id)
        if (!existingProject) {
          acc.push(project)
        } else {
          // If project exists, prioritize owned over invited
          if (!existingProject.isInvited && project.isInvited) {
            // Keep the owned version, skip the invited version
            return acc
          } else if (existingProject.isInvited && !project.isInvited) {
            // Replace invited with owned version
            const index = acc.findIndex(p => p.id === project.id)
            acc[index] = project
          }
        }
        return acc
      }, [] as typeof allProjects)

      // Sort by creation date
      const sortedProjects = uniqueAllProjects.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())

      setProjects(sortedProjects)
    } catch (error) {
      console.error('Error fetching projects:', error)
    }
  }, [user, supabase])

  // Separate function to get invited projects using database function
  const fetchInvitedProjects = useCallback(async () => {
    if (!user || !supabase) return []

    console.log('Fetching invited projects for user:', user.id)

    try {
      // Use the database function to get member projects
      const { data: memberProjects, error: memberProjectsError } = await supabase
        .rpc('get_member_projects', { user_profile_id: user.id })

      if (memberProjectsError) {
        console.error('Error fetching member projects:', memberProjectsError)
        return []
      }

      console.log('Member projects found:', memberProjects?.length || 0)

      if (!memberProjects || memberProjects.length === 0) {
        console.log('No member projects found')
        return []
      }

      // Transform the data to match the expected format
      const transformedProjects = memberProjects.map(project => ({
        id: project.project_id,
        name: project.project_name,
        description: project.project_description,
        user_id: project.project_owner_id,
        created_at: project.project_created_at,
        updated_at: project.project_created_at // Use created_at as updated_at fallback
      }))

      // Deduplicate projects by project ID to avoid showing the same project multiple times
      // This can happen if a user is a member of multiple teams within the same project
      const uniqueProjects = transformedProjects.reduce((acc, project) => {
        const existingProject = acc.find(p => p.id === project.id)
        if (!existingProject) {
          acc.push(project)
        }
        return acc
      }, [] as typeof transformedProjects)

      console.log('Invited projects after transformation:', transformedProjects.length)
      console.log('Unique invited projects after deduplication:', uniqueProjects.length)
      console.log('Invited projects data:', uniqueProjects)

      return uniqueProjects
    } catch (error) {
      console.error('Error fetching invited projects:', error)
      return []
    }
  }, [user, supabase])

  const fetchInvitations = useCallback(async () => {
    if (!user || !supabase) return
    
    try {
      // First, get the basic invitations
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

      if (!invitations || invitations.length === 0) {
        setInvitations([])
        setPendingInvitationsCount(0)
        return
      }
      
      // Enrich each invitation with project and inviter names
      const enrichedInvitations = await Promise.all(
        invitations.map(async (invitation) => {
          let projectName = 'Unknown Project'
          let inviterName = 'Unknown User'

          try {
            // Get project name only if project_id exists
            if (invitation.project_id) {
              const { data: projectData } = await supabase
                .from('projects')
                .select('name')
                .eq('id', invitation.project_id)
                .single()
              projectName = projectData?.name || 'Unknown Project'
            } else {
              projectName = 'Unknown Project'
            }
          } catch (projectError) {
            console.warn('Could not fetch project name:', projectError)
          }

          try {
            // Get inviter name
            const { data: profileData } = await supabase
              .from('profiles')
              .select('name')
              .eq('id', invitation.invited_by)
              .single()
            inviterName = profileData?.name || 'Unknown User'
          } catch (profileError) {
            console.warn('Could not fetch inviter name:', profileError)
          }

          return {
            ...invitation,
            project_name: projectName,
            inviter_name: inviterName
          }
        })
      )
      
      setInvitations(enrichedInvitations)
      setPendingInvitationsCount(enrichedInvitations.length)
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

  // Real-time listener for new invitations
  useEffect(() => {
    if (!user || !supabase) return

    const channel = supabase
      .channel('team_invitations_changes')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'team_invitations',
          filter: `email=eq.${user.email}`
        },
        async (payload) => {
          console.log('New invitation received:', payload)
          
          // Fetch the full invitation details with project and inviter names
          try {
            const { data: invitation, error } = await supabase
              .from('team_invitations')
              .select('*')
              .eq('id', payload.new.id)
              .single()

            if (!error && invitation) {
              let projectName = 'Unknown Project'
              let inviterName = 'Unknown User'

              try {
                // Get project name only if project_id exists
                if (invitation.project_id) {
                  const { data: projectData } = await supabase
                    .from('projects')
                    .select('name')
                    .eq('id', invitation.project_id)
                    .single()
                  projectName = projectData?.name || 'Unknown Project'
                } else {
                  projectName = 'Unknown Project'
                }
              } catch (projectError) {
                console.warn('Could not fetch project name:', projectError)
              }

              try {
                // Get inviter name
                const { data: profileData } = await supabase
                  .from('profiles')
                  .select('name')
                  .eq('id', invitation.invited_by)
                  .single()
                inviterName = profileData?.name || 'Unknown User'
              } catch (profileError) {
                console.warn('Could not fetch inviter name:', profileError)
              }

              // Show toast notification
              toast.success(
                `You've been invited by ${inviterName} to join ${projectName}!`,
                {
                  description: `Check your notifications to accept or decline.`,
                  action: {
                    label: "View Invitations",
                    onClick: () => {
                      // Navigate to notifications page
                      window.location.href = '/notifications'
                    }
                  }
                }
              )
              
              // Refresh the invitations list
              await fetchInvitations()
            }
          } catch (error) {
            console.error('Error fetching new invitation details:', error)
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [user, supabase, fetchInvitations])

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

      // First, get the invitation details to get the token
      const { data: invitation, error: fetchError } = await supabase
        .from('team_invitations')
        .select('token, project_id, role')
        .eq('id', invitationId)
        .eq('email', user?.email)
        .eq('status', 'pending')
        .single()

      if (fetchError || !invitation) {
        console.error('Error fetching invitation:', fetchError)
        return { error: { message: 'Invitation not found or already processed' } }
      }

      // Use the database function to properly accept the invitation and add user to team
      const { error: acceptError } = await supabase.rpc('accept_team_invitation', {
        invitation_token: invitation.token
      })

      if (acceptError) {
        console.error('Error accepting invitation:', acceptError)
        return { error: { message: 'Failed to accept invitation: ' + acceptError.message } }
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
