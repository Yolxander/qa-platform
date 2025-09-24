'use client'

import React, { useEffect, useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { ProtectedRoute } from '@/components/protected-route'
import { AppSidebar } from "@/components/app-sidebar"
import { SiteHeader } from "@/components/site-header"
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { IconCheck, IconX, IconClock, IconUser, IconBuilding } from '@tabler/icons-react'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase'
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"

interface Invitation {
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
  project_name?: string
  inviter_name?: string
}

function InvitationCard({ invitation, onAccept, onDecline }: {
  invitation: Invitation
  onAccept: (id: string) => void
  onDecline: (id: string) => void
}) {
  const handleAccept = async () => {
    const { error } = await onAccept(invitation.id)
    if (error) {
      toast.error(error.message || 'Failed to accept invitation')
    } else {
      toast.success('Invitation accepted successfully!')
    }
  }

  const handleDecline = async () => {
    const { error } = await onDecline(invitation.id)
    if (error) {
      toast.error(error.message || 'Failed to decline invitation')
    } else {
      toast.success('Invitation declined')
    }
  }

  const isExpired = new Date(invitation.expires_at) < new Date()

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <IconBuilding className="h-5 w-5 text-blue-500" />
            <CardTitle className="text-lg">{invitation.project_name || 'Unknown Project'}</CardTitle>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="secondary">Invitation</Badge>
            <Badge variant="outline">{invitation.role}</Badge>
            {isExpired && <Badge variant="destructive">Expired</Badge>}
          </div>
        </div>
        <CardDescription>
          Invited by {invitation.inviter_name || 'Unknown User'}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex items-center gap-4 text-sm text-muted-foreground mb-4">
          <div className="flex items-center gap-1">
            <IconUser className="h-4 w-4" />
            <span>{invitation.name || invitation.email}</span>
          </div>
          <div className="flex items-center gap-1">
            <IconClock className="h-4 w-4" />
            <span>Expires {new Date(invitation.expires_at).toLocaleDateString()}</span>
          </div>
        </div>
        
        {!isExpired ? (
          <div className="flex gap-2">
            <Button 
              onClick={handleAccept}
              size="sm"
              className="flex items-center gap-2"
            >
              <IconCheck className="h-4 w-4" />
              Accept
            </Button>
            <Button 
              onClick={handleDecline}
              variant="outline"
              size="sm"
              className="flex items-center gap-2"
            >
              <IconX className="h-4 w-4" />
              Decline
            </Button>
          </div>
        ) : (
          <div className="text-sm text-muted-foreground">
            This invitation has expired and can no longer be accepted.
          </div>
        )}
      </CardContent>
    </Card>
  )
}

function NotificationsPage() {
  const { user, invitations, pendingInvitationsCount, acceptInvitation, declineInvitation, fetchInvitations } = useAuth()
  const [enrichedInvitations, setEnrichedInvitations] = useState<Invitation[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      fetchInvitations()
    }
  }, [user, fetchInvitations])

  // Enrich invitations with project and inviter names
  useEffect(() => {
    const enrichInvitations = async () => {
      if (!invitations || invitations.length === 0) {
        setEnrichedInvitations([])
        setLoading(false)
        return
      }

      setLoading(true)
      const enriched = await Promise.all(
        invitations.map(async (invitation) => {
          try {
            // Get project name - use a simpler approach to avoid 406 errors
            let projectName = 'Unknown Project'
            try {
              const { data: projectData } = await supabase
                .from('projects')
                .select('name')
                .eq('id', invitation.project_id)
                .single()
              projectName = projectData?.name || 'Unknown Project'
            } catch (projectError) {
              console.warn('Could not fetch project name:', projectError)
            }

            // Get inviter name - use a simpler approach
            let inviterName = 'Unknown User'
            try {
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
          } catch (error) {
            console.error('Error enriching invitation:', error)
            return {
              ...invitation,
              project_name: 'Unknown Project',
              inviter_name: 'Unknown User'
            }
          }
        })
      )

      setEnrichedInvitations(enriched)
      setLoading(false)
    }

    enrichInvitations()
  }, [invitations, supabase])

  if (!user) {
    return null
  }

  if (loading) {
    return (
      <div className="flex items-center justify-between px-4 lg:px-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="text-muted-foreground">
            Manage your team invitations and notifications
          </p>
        </div>
      </div>
    )
  }

  const validInvitations = enrichedInvitations.filter(inv => new Date(inv.expires_at) > new Date())
  const expiredInvitations = enrichedInvitations.filter(inv => new Date(inv.expires_at) <= new Date())

  return (
    <>
      <div className="flex items-center justify-between px-4 lg:px-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="text-muted-foreground">
            Manage your team invitations and notifications
          </p>
        </div>
      </div>

      {pendingInvitationsCount === 0 ? (
        <div className="px-4 lg:px-6">
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <IconUser className="h-12 w-12 text-muted-foreground mb-4" />
              <h3 className="text-lg font-semibold mb-2">No pending invitations</h3>
              <p className="text-muted-foreground text-center">
                You don't have any pending team invitations at the moment.
              </p>
            </CardContent>
          </Card>
        </div>
      ) : (
        <div className="px-4 lg:px-6 space-y-6">
          {validInvitations.length > 0 && (
            <div>
              <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
                <IconClock className="h-5 w-5" />
                Pending Invitations ({validInvitations.length})
              </h2>
              <div className="grid gap-4">
                {validInvitations.map((invitation) => (
                  <InvitationCard
                    key={invitation.id}
                    invitation={invitation}
                    onAccept={acceptInvitation}
                    onDecline={declineInvitation}
                  />
                ))}
              </div>
            </div>
          )}

          {expiredInvitations.length > 0 && (
            <div>
              <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
                <IconX className="h-5 w-5" />
                Expired Invitations ({expiredInvitations.length})
              </h2>
              <div className="grid gap-4">
                {expiredInvitations.map((invitation) => (
                  <InvitationCard
                    key={invitation.id}
                    invitation={invitation}
                    onAccept={acceptInvitation}
                    onDecline={declineInvitation}
                  />
                ))}
              </div>
            </div>
          )}
        </div>
      )}
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
