"use client"

import { AppSidebar } from "@/components/app-sidebar"
import { ChartAreaInteractive } from "@/components/chart-area-interactive"
import { DataTable } from "@/components/data-table"
import { SectionCards } from "@/components/section-cards"
import { SiteHeader } from "@/components/site-header"
import { ProtectedRoute } from "@/components/protected-route"
import { NoProjectsMessage } from "@/components/no-projects-message"
import { useAuth, ALL_PROJECTS_MARKER } from "@/contexts/AuthContext"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"
import { useEffect, useState } from "react"
import { supabase } from "@/lib/supabase"


interface DashboardData {
  metrics: {
    openIssues: number
    readyForQA: number
    mttr: string
    criticalOpen: number
    totalBugs: number
    totalTodos: number
    openTodos: number
    inProgressTodos: number
    doneTodos: number
  }
  chartData: Array<{
    date: string
    opened: number
    closed: number
  }>
  tableData: Array<{
    id: number
    header: string
    type: string
    status: string
    target: string
    limit: string
    reviewer: string
    source: string
    project?: string
  }>
  totalBugs: number
  totalTodos: number
  isAllProjects: boolean
  accessibleProjectCount: number
}

export default function Page() {
  const { projects, loading, user, currentProject } = useAuth()
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(null)
  const [dashboardLoading, setDashboardLoading] = useState(true)
  const [dashboardError, setDashboardError] = useState<string | null>(null)
  const [userRole, setUserRole] = useState<string>('guest')
  const [roleLoading, setRoleLoading] = useState(true)

  // Fetch dashboard data
  useEffect(() => {
    const fetchDashboardData = async () => {
      if (!user || currentProject === undefined) return

      try {
        setDashboardLoading(true)
        setDashboardError(null)

        const { data: { session } } = await supabase.auth.getSession()
        
        if (!session?.access_token) {
          throw new Error('No access token')
        }

        // Determine the projectId parameter based on currentProject
        const projectId = currentProject === ALL_PROJECTS_MARKER ? null : currentProject?.id
        const url = projectId ? `/api/dashboard?projectId=${projectId}` : '/api/dashboard'
        
        console.log('Dashboard - Fetching data:', { currentProject, projectId, url })
        
        const response = await fetch(url, {
          headers: {
            'Authorization': `Bearer ${session.access_token}`,
            'Content-Type': 'application/json',
          },
        })

        if (!response.ok) {
          throw new Error(`Failed to fetch dashboard data: ${response.statusText}`)
        }

        const data = await response.json()
        console.log('Dashboard - Received data:', data)
        setDashboardData(data)
      } catch (error) {
        console.error('Error fetching dashboard data:', error)
        setDashboardError(error instanceof Error ? error.message : 'Failed to fetch dashboard data')
      } finally {
        setDashboardLoading(false)
      }
    }

    fetchDashboardData()
  }, [user, currentProject])

  // Fetch user role for current project
  useEffect(() => {
    const fetchUserRole = async () => {
      if (!user) {
        setUserRole('guest')
        setRoleLoading(false)
        return
      }

      // If All Projects is selected, set role to owner (can view all their projects)
      if (currentProject === ALL_PROJECTS_MARKER) {
        setUserRole('owner')
        setRoleLoading(false)
        return
      }

      if (!currentProject) {
        setUserRole('guest')
        setRoleLoading(false)
        return
      }

      try {
        setRoleLoading(true)
        
        // Check if user is the project owner
        if (currentProject.user_id === user.id) {
          console.log('Dashboard: User is project owner, setting role to owner')
          setUserRole('owner')
          setRoleLoading(false)
          return
        }

        // Get user's role from team_members table for current project
        const { data: memberTeams, error } = await supabase
          .rpc('get_member_teams', { user_profile_id: user.id })

        if (error) {
          console.error('Error fetching user role:', error)
          setUserRole('guest')
          return
        }

        // Find the team for the current project
        const currentProjectTeam = memberTeams?.find(team => team.project_id === currentProject.id)
        
        console.log('Dashboard role detection:', {
          currentProjectId: currentProject.id,
          memberTeams,
          currentProjectTeam,
          detectedRole: currentProjectTeam?.role || 'guest'
        })
        
        if (currentProjectTeam) {
          console.log('Dashboard: Found team role:', currentProjectTeam.role)
          setUserRole(currentProjectTeam.role || 'guest')
        } else {
          // If no team found for this project, default to guest
          console.log('Dashboard: No team found, defaulting to guest')
          setUserRole('guest')
        }
      } catch (error) {
        console.error('Error fetching user role:', error)
        setUserRole('guest')
      } finally {
        setRoleLoading(false)
      }
    }

    fetchUserRole()
  }, [user, currentProject])

  // Show loading state
  if (loading || dashboardLoading || roleLoading) {
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
                <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
                  <div className="flex items-center justify-center min-h-[400px]">
                    <div className="text-center">Loading...</div>
                  </div>
                </div>
              </div>
            </div>
          </SidebarInset>
        </SidebarProvider>
      </ProtectedRoute>
    )
  }

  // Show error state
  if (dashboardError) {
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
                <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
                  <div className="flex items-center justify-center min-h-[400px]">
                    <div className="text-center text-red-500">
                      Error: {dashboardError}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </SidebarInset>
        </SidebarProvider>
      </ProtectedRoute>
    )
  }

  // Show "Add New Project" message if no projects
  if (projects.length === 0) {
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
                <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
                  <NoProjectsMessage />
                </div>
              </div>
            </div>
          </SidebarInset>
        </SidebarProvider>
      </ProtectedRoute>
    )
  }

  // Show normal dashboard with projects
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
              <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
                <div className="px-4 lg:px-6">
                  <div>
                    <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
                    <p className="text-muted-foreground">
                      {currentProject === ALL_PROJECTS_MARKER 
                        ? `Overview for All Projects (${dashboardData?.accessibleProjectCount || 0} projects)` 
                        : currentProject && typeof currentProject === 'object' 
                          ? `Overview for ${currentProject.name}` 
                          : 'Your project overview'
                      }
                    </p>
                  </div>
                </div>
                <SectionCards data={dashboardData?.metrics} />
                <div className="px-4 lg:px-6">
                  <ChartAreaInteractive data={dashboardData?.chartData} />
                </div>
                <DataTable data={dashboardData?.tableData || []} />
              </div>
            </div>
          </div>
        </SidebarInset>
      </SidebarProvider>
    </ProtectedRoute>
  )
}
