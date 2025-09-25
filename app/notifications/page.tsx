'use client'

import React, { useEffect, useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { ProtectedRoute } from '@/components/protected-route'
import { AppSidebar } from "@/components/app-sidebar"
import { SiteHeader } from "@/components/site-header"
import { InvitationsTable } from '@/components/invitations-table'
import { Button } from '@/components/ui/button'
import { IconUser, IconRefresh } from '@tabler/icons-react'
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"


function NotificationsPage() {
  const { user, invitations, acceptInvitation, declineInvitation, fetchInvitations, refreshData } = useAuth()

  useEffect(() => {
    if (user) {
      fetchInvitations()
    }
  }, [user, fetchInvitations])

  if (!user) {
    return null
  }

  return (
    <>
      <div className="flex items-center justify-between px-4 lg:px-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="text-muted-foreground">
          Manage your team invitations and notifications
        </p>
        </div>
        <Button 
          variant="outline" 
          onClick={refreshData}
          className="flex items-center gap-2"
        >
          <IconRefresh className="size-4" />
          Refresh
        </Button>
      </div>

      <div className="px-4 lg:px-6">
        <InvitationsTable 
          invitations={invitations}
                    onAccept={acceptInvitation}
                    onDecline={declineInvitation}
                  />
              </div>
    </>
  )
}

export default function Page() {
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
      <NotificationsPage />
              </div>
            </div>
          </div>
        </SidebarInset>
      </SidebarProvider>
    </ProtectedRoute>
  )
}
