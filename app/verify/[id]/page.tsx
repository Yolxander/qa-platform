import { AppSidebar } from "@/components/app-sidebar"
import { SiteHeader } from "@/components/site-header"
import { VerifyPageContent } from "@/components/verify-page-content"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"

interface VerifyPageProps {
  params: {
    id: string
  }
}

export default function VerifyPage({ params }: VerifyPageProps) {
  const issueId = parseInt(params.id)
  
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
              <VerifyPageContent issueId={issueId} />
            </div>
          </div>
        </div>
      </SidebarInset>
    </SidebarProvider>
  )
}
