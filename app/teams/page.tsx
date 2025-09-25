"use client"

import { useState, useEffect } from "react"
import { AppSidebar } from "@/components/app-sidebar"
import { TeamsTable } from "@/components/teams-table"
import { SiteHeader } from "@/components/site-header"
import { ProtectedRoute } from "@/components/protected-route"
import { AddTeamMemberForm } from "@/components/add-team-member-form"
import { NewTeamForm } from "@/components/new-team-form"
import { Button } from "@/components/ui/button"
import { IconPlus } from "@tabler/icons-react"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"
import { supabase } from "@/lib/supabase"
import { useAuth } from "@/contexts/AuthContext"

interface TeamMember {
  id: string
  name: string
  email: string
  role: string
  joined_at: string
  avatar_url?: string
}

interface Team {
  id: string
  name: string
  description?: string
  project_id: string
  created_at: string
  members: TeamMember[]
  project_name?: string
  project_description?: string
  isOwner?: boolean
  userRole?: string
}

export default function Page() {
  const [teams, setTeams] = useState<Team[]>([])
  const [loading, setLoading] = useState(true)
  const { user, currentProject } = useAuth()

  // Load teams and members from Supabase
  const loadTeams = async () => {
    try {
      setLoading(true)
      
      if (!supabase) {
        console.warn("Supabase not configured")
        setTeams([])
        return
      }

      if (!user) {
        console.warn("No user authenticated")
        setTeams([])
        return
      }

      if (!currentProject) {
        setTeams([])
        return
      }

      // Load teams where user is owner (current project teams)
      const ownedTeams = currentProject ? await loadOwnedTeams() : []
      
      // Load teams where user is member but not owner
      const memberTeams = await loadMemberTeams()

      // Filter member teams to only show those connected to the current project
      const filteredMemberTeams = memberTeams.filter(team => 
        team.project_id === currentProject.id
      )

      // Combine both types of teams
      const allTeams = [...ownedTeams, ...filteredMemberTeams]
      
      setTeams(allTeams)
    } catch (error) {
      console.error("Error loading teams:", error)
      setTeams([])
    } finally {
      setLoading(false)
    }
  }

  // Load teams where user is the owner (current project teams)
  const loadOwnedTeams = async () => {
    if (!currentProject) return []

    try {
      // Get teams for the current project
      const { data: teamsData, error: teamsError } = await supabase
        .from('teams')
        .select(`
          *,
          projects!inner(
            id,
            name,
            description
          )
        `)
        .eq('project_id', currentProject.id)
        .order('created_at', { ascending: false })

      if (teamsError) {
        console.error('Error fetching owned teams:', teamsError)
        return []
      }

      if (!teamsData || teamsData.length === 0) {
        return []
      }

      // Load team members for each team using the database function
      const teamsWithMembers = await Promise.all(
        teamsData.map(async (team) => {
          const { data: membersData, error: membersError } = await supabase
            .rpc('get_team_members', { team_uuid: team.id })

          if (membersError) {
            console.error('Error fetching team members:', membersError)
            return null
          }

          const members = (membersData || []).map(member => ({
            id: member.member_id,
            name: member.member_name || 'Unknown',
            email: member.member_email,
            role: member.role,
            joined_at: member.joined_at,
            avatar_url: member.member_avatar_url
          }))

          return {
            ...team,
            members,
            project_name: team.projects.name,
            project_description: team.projects.description,
            isOwner: true
          }
        })
      )

      // Filter out any null results
      return teamsWithMembers.filter(team => team !== null)
    } catch (error) {
      console.error('Error in loadOwnedTeams:', error)
      return []
    }
  }

  // Load teams where user is a member but not owner using database function
  const loadMemberTeams = async () => {
    if (!user) return []

    try {
      // Use the database function to get member teams
      const { data: memberTeamsData, error: memberTeamsError } = await supabase
        .rpc('get_member_teams', { user_profile_id: user.id })

      if (memberTeamsError) {
        console.error('Error fetching member teams:', memberTeamsError)
        return []
      }

      if (!memberTeamsData || memberTeamsData.length === 0) {
        return []
      }

      // Load team members for each member team
      const teamsWithMembers = await Promise.all(
        memberTeamsData.map(async (teamData) => {
          const { data: membersData, error: membersError } = await supabase
            .rpc('get_team_members', { team_uuid: teamData.team_id })

          if (membersError) {
            console.error('Error fetching team members:', membersError)
            return null
          }

          const members = (membersData || []).map(member => ({
            id: member.member_id,
            name: member.member_name || 'Unknown',
            email: member.member_email,
            role: member.role,
            joined_at: member.joined_at,
            avatar_url: member.member_avatar_url
          }))

          return {
            id: teamData.team_id,
            name: teamData.team_name,
            description: teamData.team_description,
            project_id: teamData.project_id,
            created_at: teamData.team_created_at,
            members,
            project_name: teamData.project_name,
            project_description: teamData.project_description,
            isOwner: false,
            userRole: teamData.user_role
          }
        })
      )

      // Filter out any null results
      return teamsWithMembers.filter(team => team !== null)
    } catch (error) {
      console.error('Error in loadMemberTeams:', error)
      return []
    }
  }

  useEffect(() => {
    if (user) {
      loadTeams()
    }
  }, [user, currentProject])

  const handleTeamUpdated = () => {
    loadTeams()
  }

  return (
    <ProtectedRoute>
      <SidebarProvider
        style={
          {
            "--sidebar-width": "calc(var(--spacing) * 72)",
            "--header-height": "calc(var(--spacing) * 12)",
          } as React.CSSProperties
        }
      >
        <AppSidebar variant="inset" />
        <SidebarInset>
          <SiteHeader />
          <div className="flex flex-1 flex-col">
            <div className="@container/main flex flex-1 flex-col gap-2">
              <div className="flex flex-1 flex-col gap-4 py-4 md:gap-6 md:py-6">
                <div className="flex items-center justify-between px-4 lg:px-6">
                  <div>
                    <h1 className="text-2xl font-bold tracking-tight">Teams</h1>
                    <p className="text-muted-foreground">
                      {currentProject ? 
                        (currentProject.isInvited ? 
                          `Teams you're a member of in ${currentProject.name}` : 
                          `Teams for ${currentProject.name}`
                        ) : 
                        'Your teams and teams you\'re a member of'
                      }
                    </p>
                  </div>
                  {currentProject && !currentProject.isInvited && (
                    <div className="flex items-center gap-2">
                      <NewTeamForm onTeamCreated={handleTeamUpdated}>
                        <Button variant="outline">
                          <IconPlus className="size-4 mr-2" />
                          Create Team
                        </Button>
                      </NewTeamForm>
                      <AddTeamMemberForm onTeamUpdated={handleTeamUpdated}>
                        <Button>
                          <IconPlus className="size-4 mr-2" />
                          Add Member
                        </Button>
                      </AddTeamMemberForm>
                    </div>
                  )}
                </div>

                {!currentProject ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-center">
                      <div className="text-muted-foreground mb-4">No project selected</div>
                      <p className="text-sm text-muted-foreground">
                        Please select a project from the sidebar to view its teams.
                      </p>
                    </div>
                  </div>
                ) : loading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-muted-foreground">Loading teams...</div>
                  </div>
                ) : (
                  <TeamsTable data={teams} onTeamUpdated={handleTeamUpdated} />
                )}
              </div>
            </div>
          </div>
        </SidebarInset>
      </SidebarProvider>
    </ProtectedRoute>
  )
}
