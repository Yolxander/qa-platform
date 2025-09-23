import { AppSidebar } from "@/components/app-sidebar"
import { BugDetailsContent } from "@/components/bug-details-content"
import { SiteHeader } from "@/components/site-header"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"

interface BugDetailsPageProps {
  params: {
    id: string
  }
}

export default function BugDetailsPage({ params }: BugDetailsPageProps) {
  const bugId = parseInt(params.id)
  
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
            <div className="flex flex-1 flex-col gap-4 py-4 md:gap-6 md:py-6">
              <BugDetailsContent bugId={bugId} />
            </div>
          </div>
        </div>
      </SidebarInset>
    </SidebarProvider>
  )
}
