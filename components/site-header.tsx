"use client"

import { usePathname } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { QuickCreateModal } from "@/components/quick-create-modal"

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
      case "/recently-fixed":
        return "Recently Fixed"
      default:
        return "Documents"
    }
  }
  return (
    <header className="flex h-(--header-height) shrink-0 items-center gap-2 border-b transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-(--header-height)">
      <div className="flex w-full items-center gap-1 px-4 lg:gap-2 lg:px-6">
        <SidebarTrigger className="-ml-1" />
        <Separator
          orientation="vertical"
          className="mx-2 data-[orientation=vertical]:h-4"
        />
        <h1 className="text-base font-medium">{getPageTitle()}</h1>
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
