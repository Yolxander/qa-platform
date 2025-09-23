"use client"

import { usePathname } from "next/navigation"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { QuickCreateModal } from "@/components/quick-create-modal"

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

  // Mock bug data - in a real app, this would be fetched based on the bug ID from the URL
  const getBugBadges = () => {
    if (pathname.startsWith("/bug/")) {
      // Extract bug ID from pathname
      const bugId = pathname.split("/bug/")[1]
      // Mock data - in real app, fetch based on bugId
      const mockBug = {
        severity: "CRITICAL",
        status: "Open"
      }
      
      return (
        <div className="flex items-center gap-2">
          <Badge variant={getSeverityBadgeVariant(mockBug.severity)}>
            {mockBug.severity}
          </Badge>
          <Badge variant={getStatusBadgeVariant(mockBug.status)}>
            {mockBug.status}
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
              Quick Create
            </Button>
          </QuickCreateModal>
        </div>
      </div>
    </header>
  )
}
