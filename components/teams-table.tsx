"use client"

import * as React from "react"
import { useState } from "react"
import { useAuth } from "@/contexts/AuthContext"
import { supabase } from "@/lib/supabase"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { IconDots, IconUser, IconCrown, IconShield, IconUserCheck } from "@tabler/icons-react"
import { toast } from "sonner"

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
  project_name?: string
  project_description?: string
}

interface TeamsTableProps {
  data: Team[]
  onTeamUpdated?: () => void
}

const getRoleIcon = (role: string) => {
  switch (role) {
    case 'developer':
      return <IconUser className="size-4" />
    case 'tester':
      return <IconShield className="size-4" />
    case 'guest':
      return <IconUserCheck className="size-4" />
    default:
      return <IconUser className="size-4" />
  }
}

const getRoleBadgeVariant = (role: string) => {
  switch (role) {
    case 'developer':
      return "default" as const
    case 'tester':
      return "secondary" as const
    case 'guest':
      return "outline" as const
    default:
      return "outline" as const
  }
}

const getInitials = (name: string) => {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

export function TeamsTable({ data, onTeamUpdated }: TeamsTableProps) {
  const { user } = useAuth()
  const [loading, setLoading] = useState<string | null>(null)

  const handleRemoveMember = async (teamId: string, memberId: string) => {
    try {
      setLoading(memberId)
      
      const { error } = await supabase
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('profile_id', memberId)

      if (error) throw error

      toast.success("Team member removed successfully!")
      if (onTeamUpdated) {
        onTeamUpdated()
      }
    } catch (error) {
      console.error("Error removing team member:", error)
      toast.error("Failed to remove team member")
    } finally {
      setLoading(null)
    }
  }

  const handleChangeRole = async (teamId: string, memberId: string, newRole: string) => {
    try {
      setLoading(memberId)
      
      const { error } = await supabase
        .from('team_members')
        .update({ role: newRole })
        .eq('team_id', teamId)
        .eq('profile_id', memberId)

      if (error) throw error

      toast.success("Role updated successfully!")
      if (onTeamUpdated) {
        onTeamUpdated()
      }
    } catch (error) {
      console.error("Error updating role:", error)
      toast.error("Failed to update role")
    } finally {
      setLoading(null)
    }
  }

  if (data.length === 0) {
    return (
      <div className="w-full space-y-4 px-4 lg:px-6">
        <div className="flex items-center justify-center py-8">
          <div className="text-center">
            <IconUserCheck className="size-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-medium">No team members</h3>
            <p className="text-muted-foreground">
              Add team members to start collaborating on your project.
            </p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full space-y-4 px-4 lg:px-6">
      {data.map((team) => (
        <div key={team.id} className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold">{team.name}</h2>
              {team.description && (
                <p className="text-sm text-muted-foreground">{team.description}</p>
              )}
            </div>
            <Badge variant="outline">
              {team.members.length} member{team.members.length !== 1 ? 's' : ''}
            </Badge>
          </div>

          <div className="border rounded-lg">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Member</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead className="w-[50px]"></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {team.members.map((member) => (
                  <TableRow key={member.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <Avatar className="size-8">
                          <AvatarImage src={member.avatar_url} />
                          <AvatarFallback>
                            {getInitials(member.name)}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="font-medium">{member.name}</div>
                          <div className="text-sm text-muted-foreground">
                            {member.email}
                          </div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant={getRoleBadgeVariant(member.role)} className="gap-1">
                        {getRoleIcon(member.role)}
                        {member.role.charAt(0).toUpperCase() + member.role.slice(1)}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <span className="text-sm text-muted-foreground">
                        {new Date(member.joined_at).toLocaleDateString()}
                      </span>
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button
                            variant="ghost"
                            size="sm"
                            disabled={loading === member.id}
                          >
                            <IconDots className="size-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuLabel>Actions</DropdownMenuLabel>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem
                            onClick={() => handleChangeRole(team.id, member.id, 'developer')}
                            disabled={loading === member.id}
                          >
                            <IconUser className="size-4 mr-2" />
                            Make Developer
                          </DropdownMenuItem>
                          <DropdownMenuItem
                            onClick={() => handleChangeRole(team.id, member.id, 'tester')}
                            disabled={loading === member.id}
                          >
                            <IconShield className="size-4 mr-2" />
                            Make Tester
                          </DropdownMenuItem>
                          <DropdownMenuItem
                            onClick={() => handleChangeRole(team.id, member.id, 'guest')}
                            disabled={loading === member.id}
                          >
                            <IconUserCheck className="size-4 mr-2" />
                            Make Guest
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem
                            onClick={() => handleRemoveMember(team.id, member.id)}
                            disabled={loading === member.id}
                            className="text-destructive"
                          >
                            Remove from Team
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </div>
      ))}
    </div>
  )
}
