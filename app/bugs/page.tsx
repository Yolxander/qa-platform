"use client"

import { useState, useEffect } from "react"
import { AppSidebar } from "@/components/app-sidebar"
import { BugsTable } from "@/components/bugs-table"
import { SiteHeader } from "@/components/site-header"
import { ProtectedRoute } from "@/components/protected-route"
import { NewBugForm } from "@/components/new-bug-form"
import { Button } from "@/components/ui/button"
import { IconPlus } from "@tabler/icons-react"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"
import { supabase } from "@/lib/supabase"
import { Bug } from "@/lib/supabase"
import { useAuth } from "@/contexts/AuthContext"


export default function Page() {
  const [bugs, setBugs] = useState<Bug[]>([])
  const [loading, setLoading] = useState(true)
  const { currentProject, user } = useAuth()

  // Load bugs from Supabase
  const loadBugs = async () => {
    try {
      setLoading(true)
      
      if (!supabase) {
        console.warn("Supabase not configured")
        setBugs([])
        return
      }

      if (!currentProject) {
        console.warn("No current project selected")
        setBugs([])
        return
      }

      // Show bugs where user is either the creator (user_id) or assignee
      let query = supabase
        .from('bugs')
        .select('*')
        .eq('project_id', currentProject.id)

      if (user?.id) {
        // Show bugs where user is either the creator or the assignee
        query = query.or(`user_id.eq.${user.id},assignee.eq.${user.id}`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })

      if (error) throw error
      setBugs(data || [])
    } catch (error) {
      console.error("Error loading bugs:", error)
      setBugs([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadBugs()
  }, [currentProject])

  const handleBugCreated = () => {
    loadBugs()
  }

  // Convert Supabase bugs to the format expected by BugsTable
  const formattedBugs = bugs.map(bug => ({
    id: bug.id,
    title: bug.title,
    severity: bug.severity,
    status: bug.status,
    environment: bug.environment,
    reporter: bug.reporter,
    assignee: bug.assignee,
    updatedAt: new Date(bug.updated_at).toLocaleDateString()
  }))

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
                    <h1 className="text-2xl font-bold tracking-tight">Bugs</h1>
                    <p className="text-muted-foreground">
                      Bugs you created or are assigned to in {currentProject?.name}
                    </p>
                  </div>
                  {!currentProject?.isInvited && (
                    <div className="flex items-center gap-2">
                      <NewBugForm onBugCreated={handleBugCreated}>
                        <Button>
                          <IconPlus className="size-4 mr-2" />
                          New Bug
                        </Button>
                      </NewBugForm>
                    </div>
                  )}
                </div>

                {loading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-muted-foreground">Loading bugs...</div>
                  </div>
                ) : (
                  <BugsTable data={formattedBugs} />
                )}
              </div>
            </div>
          </div>
        </SidebarInset>
      </SidebarProvider>
    </ProtectedRoute>
  )
}
