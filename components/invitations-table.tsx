'use client'

import React from 'react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { IconCheck, IconX, IconClock, IconUser, IconBuilding } from '@tabler/icons-react'
import { toast } from 'sonner'

interface TeamInvitation {
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
  project_name: string
  inviter_name: string
}

interface InvitationsTableProps {
  invitations: TeamInvitation[]
  onAccept: (id: string) => Promise<{ error: any }>
  onDecline: (id: string) => Promise<{ error: any }>
}

export function InvitationsTable({ invitations, onAccept, onDecline }: InvitationsTableProps) {
  const handleAccept = async (invitationId: string) => {
    const { error } = await onAccept(invitationId)
    if (error) {
      toast.error(error.message || 'Failed to accept invitation')
    } else {
      toast.success('Invitation accepted successfully!')
    }
  }

  const handleDecline = async (invitationId: string) => {
    const { error } = await onDecline(invitationId)
    if (error) {
      toast.error(error.message || 'Failed to decline invitation')
    } else {
      toast.success('Invitation declined')
    }
  }

  const isExpired = (expiresAt: string) => new Date(expiresAt) < new Date()

  if (invitations.length === 0) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-12">
          <IconUser className="h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-semibold mb-2">No pending invitations</h3>
          <p className="text-muted-foreground text-center">
            You don't have any pending team invitations at the moment.
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <IconClock className="h-5 w-5" />
          Pending Invitations ({invitations.length})
        </CardTitle>
        <CardDescription>
          Manage your team invitations and notifications
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Project</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Invited By</TableHead>
              <TableHead>Expires</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {invitations.map((invitation) => {
              const expired = isExpired(invitation.expires_at)
              return (
                <TableRow key={invitation.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <IconBuilding className="h-4 w-4 text-blue-500" />
                      <span className="font-medium">{invitation.project_name}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{invitation.role}</Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <IconUser className="h-4 w-4 text-muted-foreground" />
                      <span>{invitation.inviter_name}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm text-muted-foreground">
                      {new Date(invitation.expires_at).toLocaleDateString()}
                    </span>
                  </TableCell>
                  <TableCell>
                    {expired ? (
                      <Badge variant="destructive">Expired</Badge>
                    ) : (
                      <Badge variant="secondary">Pending</Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-right">
                    {!expired ? (
                      <div className="flex gap-2 justify-end">
                        <Button 
                          onClick={() => handleAccept(invitation.id)}
                          size="sm"
                          className="flex items-center gap-2"
                        >
                          <IconCheck className="h-4 w-4" />
                          Accept
                        </Button>
                        <Button 
                          onClick={() => handleDecline(invitation.id)}
                          variant="outline"
                          size="sm"
                          className="flex items-center gap-2"
                        >
                          <IconX className="h-4 w-4" />
                          Decline
                        </Button>
                      </div>
                    ) : (
                      <span className="text-sm text-muted-foreground">
                        Expired
                      </span>
                    )}
                  </TableCell>
                </TableRow>
              )
            })}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  )
}
