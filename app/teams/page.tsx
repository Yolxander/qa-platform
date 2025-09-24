"use client"

import { useState, useEffect } from "react"
import { AppSidebar } from "@/components/app-sidebar"
import { TeamsTable } from "@/components/teams-table"
import { SiteHeader } from "@/components/site-header"
import { ProtectedRoute } from "@/components/protected-route"
import { AddTeamMemberForm } from "@/components/add-team-member-form"
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
}

export default function Page() {
  const [teams, setTeams] = useState<Team[]>([])
  const [loading, setLoading] = useState(true)
  const { currentProject } = useAuth()

  // Load teams and members from Supabase
  const loadTeams = async () => {
    try {
      setLoading(true)
      
      if (!supabase) {
        console.warn("Supabase not configured")
        setTeams([])
        return
      }

      if (!currentProject) {
        console.warn("No current project selected")
        setTeams([])
        return
      }

      // Load teams for the current project
      const { data: teamsData, error: teamsError } = await supabase
        .from('teams')
        .select('*')
        .eq('project_id', currentProject.id)
        .order('created_at', { ascending: false })

      if (teamsError) throw teamsError

      // Load team members for each team
      const teamsWithMembers = await Promise.all(
        (teamsData || []).map(async (team) => {
          const { data: membersData, error: membersError } = await supabase
            .from('team_members')
            .select(`
              id,
              role,
              joined_at,
              profiles!inner(
                id,
                name,
                email,
                avatar_url
              )
            `)
            .eq('team_id', team.id)
            .order('joined_at', { ascending: false })

          if (membersError) throw membersError

          const members = (membersData || []).map(member => ({
            id: member.profiles.id,
            name: member.profiles.name || 'Unknown',
            email: member.profiles.email,
            role: member.role,
            joined_at: member.joined_at,
            avatar_url: member.profiles.avatar_url
          }))

          return {
            ...team,
            members
          }
        })
      )

      setTeams(teamsWithMembers)
    } catch (error) {
      console.error("Error loading teams:", error)
      setTeams([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadTeams()
  }, [currentProject])

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
                    <h1 className="text-2xl font-bold tracking-tight">Team</h1>
                    <p className="text-muted-foreground">
                      Manage your project team members
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <AddTeamMemberForm onTeamUpdated={handleTeamUpdated}>
                      <Button>
                        <IconPlus className="size-4 mr-2" />
                        Add Member
                      </Button>
                    </AddTeamMemberForm>
                  </div>
                </div>

                {loading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-muted-foreground">Loading team...</div>
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
