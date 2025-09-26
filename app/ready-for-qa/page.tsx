"use client"

import { useState, useEffect } from "react"
import { AppSidebar } from "@/components/app-sidebar"
import { QATable } from "@/components/qa-table"
import { SiteHeader } from "@/components/site-header"
import { ProtectedRoute } from "@/components/protected-route"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"
import { supabase } from "@/lib/supabase"
import { Todo } from "@/lib/supabase"
import { useAuth } from "@/contexts/AuthContext"

export default function Page() {
  const [todos, setTodos] = useState<Todo[]>([])
  const [loading, setLoading] = useState(true)
  const { currentProject, user } = useAuth()

  // Load todos with READY_FOR_QA status from Supabase
  const loadQATodos = async () => {
    try {
      setLoading(true)
      
      if (!supabase) {
        console.warn("Supabase not configured")
        setTodos([])
        return
      }

      if (!currentProject) {
        console.warn("No current project selected")
        setTodos([])
        return
      }

      // Show todos with READY_FOR_QA status where user is either the creator or assignee
      let query = supabase
        .from('todos_with_assignee_names')
        .select('*')
        .eq('project_id', currentProject.id)
        .eq('status', 'READY_FOR_QA')

      if (user?.id) {
        // Show todos where user is either the creator or the assignee
        query = query.or(`user_id.eq.${user.id},assignee.eq.${user.id}`)
      }

      const { data, error } = await query.order('created_at', { ascending: false })

      if (error) throw error
      setTodos(data || [])
    } catch (error) {
      console.error("Error loading QA todos:", error)
      setTodos([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadQATodos()
  }, [currentProject])

  // Convert Supabase todos to the format expected by QATable
  const formattedTodos = todos.map(todo => ({
    id: todo.id,
    title: todo.title,
    severity: todo.severity,
    environment: todo.environment,
    issueLink: todo.issue_link || "",
    updatedAt: new Date(todo.updated_at).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    }),
    assignee_name: todo.assignee_name,
    dueDate: todo.due_date ? new Date(todo.due_date).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    }) : 'No due date'
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
              <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
                <div className="px-4 lg:px-6">
                  <h1 className="text-2xl font-bold tracking-tight">Ready for QA</h1>
                  <p className="text-muted-foreground">
                    Tasks ready for verification and testing in {currentProject?.name}
                  </p>
                </div>
                
                {loading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-muted-foreground">Loading QA tasks...</div>
                  </div>
                ) : (
                  <QATable data={formattedTodos} />
                )}
              </div>
            </div>
          </div>
        </SidebarInset>
      </SidebarProvider>
    </ProtectedRoute>
  )
}
