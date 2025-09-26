"use client"

import { AppSidebar } from "@/components/app-sidebar"
import { ChartAreaInteractive } from "@/components/chart-area-interactive"
import { DataTable } from "@/components/data-table"
import { SectionCards } from "@/components/section-cards"
import { SiteHeader } from "@/components/site-header"
import { ProtectedRoute } from "@/components/protected-route"
import { NoProjectsMessage } from "@/components/no-projects-message"
import { useAuth } from "@/contexts/AuthContext"
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
  }>
  totalBugs: number
  totalTodos: number
}

export default function Page() {
  const { projects, loading, user } = useAuth()
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(null)
  const [dashboardLoading, setDashboardLoading] = useState(true)
  const [dashboardError, setDashboardError] = useState<string | null>(null)

  // Fetch dashboard data
  useEffect(() => {
    const fetchDashboardData = async () => {
      if (!user) return

      try {
        setDashboardLoading(true)
        setDashboardError(null)

        const { data: { session } } = await supabase.auth.getSession()
        
        if (!session?.access_token) {
          throw new Error('No access token')
        }

        const response = await fetch('/api/dashboard', {
          headers: {
            'Authorization': `Bearer ${session.access_token}`,
            'Content-Type': 'application/json',
          },
        })

        if (!response.ok) {
          throw new Error(`Failed to fetch dashboard data: ${response.statusText}`)
        }

        const data = await response.json()
        setDashboardData(data)
      } catch (error) {
        console.error('Error fetching dashboard data:', error)
        setDashboardError(error instanceof Error ? error.message : 'Failed to fetch dashboard data')
      } finally {
        setDashboardLoading(false)
      }
    }

    fetchDashboardData()
  }, [user])

  // Show loading state
  if (loading || dashboardLoading) {
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
