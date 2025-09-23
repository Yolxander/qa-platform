"use client";

import { useState } from "react";
import { AppSidebar } from "@/components/app-sidebar"
import { TodoTable } from "@/components/todo-table"
import { TodoKanban } from "@/components/todo-kanban"
import { ViewToggle } from "@/components/view-toggle"
import { SiteHeader } from "@/components/site-header"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"

import todoData from "./data.json"

export default function Page() {
  const [currentView, setCurrentView] = useState<"table" | "kanban">("table");

  return (
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
                    Manage your assigned tasks and track progress
                  </p>
                </div>
                <ViewToggle 
                  currentView={currentView} 
                  onViewChange={setCurrentView} 
                />
              </div>
              {currentView === "table" ? (
                <TodoTable data={todoData} />
              ) : (
                <TodoKanban data={todoData} />
              )}
            </div>
          </div>
        </div>
      </SidebarInset>
    </SidebarProvider>
  )
}
