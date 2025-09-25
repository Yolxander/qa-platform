"use client";

import { useState, useEffect } from "react";
import { AppSidebar } from "@/components/app-sidebar"
import { TodoTable } from "@/components/todo-table"
import { TodoKanban } from "@/components/todo-kanban"
import { ViewToggle } from "@/components/view-toggle"
import { SiteHeader } from "@/components/site-header"
import { ProtectedRoute } from "@/components/protected-route"
import { QuickCreateModal } from "@/components/quick-create-modal"
import { NewTodoForm } from "@/components/new-todo-form"
import { QuickAddForm } from "@/components/quick-add-form"
import { AssignTasksForm } from "@/components/assign-tasks-form"
import { Button } from "@/components/ui/button"
import { IconPlus } from "@tabler/icons-react"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"
import { supabase } from "@/lib/supabase"
import { Todo } from "@/lib/supabase"
import { useAuth } from "@/contexts/AuthContext"


export default function Page() {
  const [currentView, setCurrentView] = useState<"table" | "kanban">("table");
  const [todos, setTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(true);
  const { currentProject, user } = useAuth();

  // Load todos from Supabase
  const loadTodos = async () => {
    try {
      setLoading(true);
      
      if (!supabase) {
        console.warn("Supabase not configured");
        setTodos([]);
        return;
      }

      if (!currentProject) {
        console.warn("No current project selected");
        setTodos([]);
        return;
      }

      // If it's an invited project, only show todos assigned to the current user
      let query = supabase
        .from('todos')
        .select('*')
        .eq('project_id', currentProject.id);

      if (currentProject.isInvited && user?.email) {
        // For invited projects, only show todos assigned to the current user
        query = query.eq('assignee', user.email);
      }

      const { data, error } = await query.order('created_at', { ascending: false });

      if (error) throw error;
      setTodos(data || []);
    } catch (error) {
      console.error("Error loading todos:", error);
      setTodos([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTodos();
  }, [currentProject]);

  // Listen for custom events to refresh todos
  useEffect(() => {
    const handleTodoCreated = () => {
      loadTodos();
    };

    const handleTasksAssigned = () => {
      loadTodos();
    };

    // Listen for custom events
    window.addEventListener('todoCreated', handleTodoCreated);
    window.addEventListener('tasksAssigned', handleTasksAssigned);

    return () => {
      window.removeEventListener('todoCreated', handleTodoCreated);
      window.removeEventListener('tasksAssigned', handleTasksAssigned);
    };
  }, []);

  const handleTodoCreated = () => {
    loadTodos();
  };

  const handleTasksAssigned = () => {
    loadTodos();
  };

  // Convert Supabase todos to the format expected by components
  const formattedTodos = todos.map(todo => ({
    id: todo.id,
    title: todo.title,
    issueLink: todo.issue_link || "",
    status: todo.status,
    severity: todo.severity,
    dueDate: todo.due_date,
    environment: todo.environment,
    assignee: todo.assignee,
    quickAction: todo.quick_action
  }));

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
                <div className="flex items-center justify-between px-4 lg:px-6">
                  <div>
                    <h1 className="text-2xl font-bold tracking-tight">My Todos</h1>
                    <p className="text-muted-foreground">
                      {currentProject?.isInvited 
                        ? `Tasks assigned to you in ${currentProject.name}`
                        : "Manage your assigned tasks and track progress"
                      }
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <ViewToggle 
                      currentView={currentView} 
                      onViewChange={setCurrentView} 
                    />
                  </div>
                </div>


                {loading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="text-muted-foreground">Loading todos...</div>
                  </div>
                ) : currentView === "table" ? (
                  <TodoTable data={formattedTodos} />
                ) : (
                  <TodoKanban data={formattedTodos} />
                )}
              </div>
            </div>
          </div>
        </SidebarInset>
      </SidebarProvider>
    </ProtectedRoute>
  )
}
