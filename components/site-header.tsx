"use client"

import { usePathname } from "next/navigation"
import { useEffect, useState } from "react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { QuickCreateModal } from "@/components/quick-create-modal"
import { ThemeToggle } from "@/components/theme-toggle"
import { useAuth } from "@/contexts/AuthContext"
import { supabase } from "@/lib/supabase"
import { IconPlus } from "@tabler/icons-react"

const getSeverityBadgeVariant = (severity: string) => {
  switch (severity) {
    case "CRITICAL":
      return "destructive"
    case "HIGH":
      return "default"
    case "MEDIUM":
      return "secondary"
    case "LOW":
      return "outline"
    default:
      return "secondary"
  }
}

const getStatusBadgeVariant = (status: string) => {
  switch (status) {
    case "Open":
      return "default"
    case "Closed":
      return "outline"
    default:
      return "secondary"
  }
}

export function SiteHeader() {
  const pathname = usePathname()
  const { user, currentProject } = useAuth()
  const [bugData, setBugData] = useState<{ severity: string; status: string } | null>(null)
  const [userRole, setUserRole] = useState<string>('guest')
  const [roleLoading, setRoleLoading] = useState(true)
  
  const getPageTitle = () => {
    switch (pathname) {
      case "/dashboard":
        return "Dashboard"
      case "/my-todos":
        return "My Todos"
      case "/ready-for-qa":
        return "Ready for QA"
      case "/bugs":
        return "Bugs"
      default:
        if (pathname.startsWith("/bug/")) {
          return "Bug Details"
        }
        return "Documents"
    }
  }

  // Fetch bug data when on bug details page
  useEffect(() => {
    const fetchBugData = async () => {
      if (pathname.startsWith("/bug/")) {
        const bugId = pathname.split("/bug/")[1]
        if (bugId && supabase) {
          try {
            const { data, error } = await supabase
              .from('bugs')
              .select('severity, status')
              .eq('id', parseInt(bugId))
              .single()

            if (error) {
              console.error('Error fetching bug data:', error)
              return
            }

            if (data) {
              setBugData({
                severity: data.severity,
                status: data.status
              })
            }
          } catch (error) {
            console.error('Error fetching bug data:', error)
          }
        }
      } else {
        setBugData(null)
      }
    }

    fetchBugData()
  }, [pathname])

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
          console.log('SiteHeader: User is project owner, setting role to owner')
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
        
        console.log('SiteHeader role detection:', {
          currentProjectId: currentProject.id,
          memberTeams,
          currentProjectTeam,
          detectedRole: currentProjectTeam?.role || 'guest'
        })
        
        if (currentProjectTeam) {
          console.log('SiteHeader: Found team role:', currentProjectTeam.role)
          setUserRole(currentProjectTeam.role || 'guest')
        } else {
          // If no team found for this project, default to guest
          console.log('SiteHeader: No team found, defaulting to guest')
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

  // Display bug badges with real data
  const getBugBadges = () => {
    if (pathname.startsWith("/bug/") && bugData) {
      return (
        <div className="flex items-center gap-2">
          <Badge variant={getSeverityBadgeVariant(bugData.severity)}>
            {bugData.severity}
          </Badge>
          <Badge variant={getStatusBadgeVariant(bugData.status)}>
            {bugData.status}
          </Badge>
        </div>
      )
    }
    return null
  }
  return (
    <header className="flex h-(--header-height) shrink-0 items-center gap-2 border-b transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-(--header-height)">
      <div className="flex w-full items-center gap-1 px-4 lg:gap-2 lg:px-6">
        <SidebarTrigger className="-ml-1" />
        <Separator
          orientation="vertical"
          className="mx-2 data-[orientation=vertical]:h-4"
        />
        <div className="flex items-center gap-2">
          <h1 className="text-base font-medium">{getPageTitle()}</h1>
          {getBugBadges()}
        </div>
        <div className="ml-auto flex items-center gap-2">
          <QuickCreateModal userRole={userRole}>
            <Button className="hidden sm:flex" onClick={() => console.log('SiteHeader: Button clicked, userRole:', userRole)}>
              <IconPlus className="size-4 mr-2" />
              Quick Actions ({userRole})
            </Button>
          </QuickCreateModal>
          <ThemeToggle />
        </div>
      </div>
    </header>
  )
}
