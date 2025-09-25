"use client"

import { usePathname } from "next/navigation"
import { useEffect, useState } from "react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { QuickCreateModal } from "@/components/quick-create-modal"
import { ThemeToggle } from "@/components/theme-toggle"
import { supabase } from "@/lib/supabase"

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
  const [bugData, setBugData] = useState<{ severity: string; status: string } | null>(null)
  
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
          <QuickCreateModal>
            <Button variant="ghost" size="sm" className="hidden sm:flex dark:text-foreground">
              Quick Action
            </Button>
          </QuickCreateModal>
          <ThemeToggle />
        </div>
      </div>
    </header>
  )
}
