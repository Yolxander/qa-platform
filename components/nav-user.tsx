"use client"

import { useRouter } from "next/navigation"
import {
  IconCreditCard,
  IconDotsVertical,
  IconLogout,
  IconNotification,
  IconUserCircle,
} from "@tabler/icons-react"

import {
  Avatar,
  AvatarFallback,
  AvatarImage,
} from "@/components/ui/avatar"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar"
import { useAuth } from "@/contexts/AuthContext"
import { supabase } from "@/lib/supabase"
import { Badge } from "@/components/ui/badge"
import { useEffect, useState } from "react"

export function NavUser() {
  const { isMobile } = useSidebar()
  const router = useRouter()
  const { user, signOut, pendingInvitationsCount, currentProject } = useAuth()
  const [userRole, setUserRole] = useState<string>('guest')
  const [roleLoading, setRoleLoading] = useState(true)

  const handleLogout = async () => {
    await signOut()
    router.push('/login')
  }

  // Fetch user role for current project
  useEffect(() => {
    const fetchUserRole = async () => {
      if (!user || !currentProject) {
        setUserRole('guest')
        setRoleLoading(false)
        return
      }

      try {
        setRoleLoading(true)
        
        // Check if user is the project owner
        if (currentProject.user_id === user.id) {
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
        
        if (currentProjectTeam) {
          setUserRole(currentProjectTeam.role || 'guest')
        } else {
          // If no team found for this project, default to guest
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

  const getRoleBadgeVariant = (role: string) => {
    switch (role) {
      case 'owner':
        return "default" as const
      case 'developer':
        return "secondary" as const
      case 'tester':
        return "outline" as const
      case 'guest':
        return "outline" as const
      default:
        return "outline" as const
    }
  }

  const getRoleDisplayName = (role: string) => {
    switch (role) {
      case 'owner':
        return 'Owner'
      case 'developer':
        return 'Developer'
      case 'tester':
        return 'Tester'
      case 'guest':
        return 'Guest'
      default:
        return 'Guest'
    }
  }

  if (!user) {
    return null
  }

  const userDisplayName = user.user_metadata?.name || user.email?.split('@')[0] || 'User'
  const userEmail = user.email || ''
  const userInitials = userDisplayName.split(' ').map(n => n[0]).join('').toUpperCase() || 'U'

  return (
    <SidebarMenu>
      <SidebarMenuItem>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <SidebarMenuButton
              size="lg"
              className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
            >
              <Avatar className="h-8 w-8 rounded-lg">
                <AvatarImage src={user.user_metadata?.avatar_url} alt={userDisplayName} />
                <AvatarFallback className="rounded-lg">{userInitials}</AvatarFallback>
              </Avatar>
              <div className="grid flex-1 text-left text-sm leading-tight">
                <span className="truncate font-medium">{userDisplayName}</span>
                <div className="flex items-center gap-2">
                  <span className="text-muted-foreground truncate text-xs">
                    {userEmail}
                  </span>
                  {currentProject && !roleLoading && (
                    <Badge 
                      variant={getRoleBadgeVariant(userRole)} 
                      className="text-xs px-1.5 py-0.5 h-auto"
                    >
                      {getRoleDisplayName(userRole)}
                    </Badge>
                  )}
                </div>
              </div>
              <IconDotsVertical className="ml-auto size-4" />
            </SidebarMenuButton>
          </DropdownMenuTrigger>
          <DropdownMenuContent
            className="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
            side={isMobile ? "bottom" : "right"}
            align="end"
            sideOffset={4}
          >
            <DropdownMenuLabel className="p-0 font-normal">
              <div className="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
                <Avatar className="h-8 w-8 rounded-lg">
                  <AvatarImage src={user.user_metadata?.avatar_url} alt={userDisplayName} />
                  <AvatarFallback className="rounded-lg">{userInitials}</AvatarFallback>
                </Avatar>
                <div className="grid flex-1 text-left text-sm leading-tight">
                  <span className="truncate font-medium">{userDisplayName}</span>
                  <div className="flex items-center gap-2">
                    <span className="text-muted-foreground truncate text-xs">
                      {userEmail}
                    </span>
                    {currentProject && !roleLoading && (
                      <Badge 
                        variant={getRoleBadgeVariant(userRole)} 
                        className="text-xs px-1.5 py-0.5 h-auto"
                      >
                        {getRoleDisplayName(userRole)}
                      </Badge>
                    )}
                  </div>
                </div>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuGroup>
              <DropdownMenuItem>
                <IconUserCircle />
                Account
              </DropdownMenuItem>
              <DropdownMenuItem>
                <IconCreditCard />
                Billing
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => router.push('/notifications')}>
                <IconNotification />
                Notifications
                {pendingInvitationsCount > 0 && (
                  <span className="ml-auto flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-xs text-white">
                    {pendingInvitationsCount}
                  </span>
                )}
              </DropdownMenuItem>
            </DropdownMenuGroup>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleLogout}>
              <IconLogout />
              Log out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </SidebarMenuItem>
    </SidebarMenu>
  )
}
