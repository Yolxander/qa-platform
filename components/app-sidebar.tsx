"use client"

import * as React from "react"
import { usePathname } from "next/navigation"
import {
  IconChartBar,
  IconDashboard,
  IconInnerShadowTop,
  IconListDetails,
  IconUsers,
  IconChevronDown,
  IconBuilding,
} from "@tabler/icons-react"

import { NavMain } from "@/components/nav-main"
import { NavUser } from "@/components/nav-user"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"

const data = {
  user: {
    name: "shadcn",
    email: "m@example.com",
    avatar: "/avatars/shadcn.jpg",
  },
  navMain: [
    {
      title: "Dashboard",
      url: "/dashboard",
      icon: IconDashboard,
    },
    {
      title: "My Todos",
      url: "/my-todos",
      icon: IconListDetails,
    },
    {
      title: "Ready for QA",
      url: "/ready-for-qa",
      icon: IconChartBar,
    },
    {
      title: "Bugs",
      url: "/bugs",
      icon: IconUsers,
    },
  ],
  companies: [
    { id: "merjj", name: "Merjj CMS", icon: IconBuilding },
    { id: "acme", name: "Acme Inc.", icon: IconBuilding },
    { id: "techcorp", name: "TechCorp Solutions", icon: IconBuilding },
    { id: "innovate", name: "Innovate Labs", icon: IconBuilding },
  ],
}

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const pathname = usePathname()
  const [selectedCompany, setSelectedCompany] = React.useState("merjj")
  
  const currentCompany = data.companies.find(company => company.id === selectedCompany) || data.companies[0]
  
  return (
    <Sidebar collapsible="offcanvas" {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <SidebarMenuButton
                  className="data-[slot=sidebar-menu-button]:!p-1.5 w-full justify-between"
                >
                  <div className="flex items-center gap-2">
                    <IconInnerShadowTop className="!size-5" />
                    <span className="text-base font-semibold">{currentCompany.name}</span>
                  </div>
                  <IconChevronDown className="size-4" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" className="w-56">
                {data.companies.map((company) => (
                  <DropdownMenuItem
                    key={company.id}
                    onClick={() => setSelectedCompany(company.id)}
                    className={`flex items-center gap-2 ${
                      selectedCompany === company.id ? "bg-accent" : ""
                    }`}
                  >
                    <company.icon className="size-4" />
                    <span>{company.name}</span>
                  </DropdownMenuItem>
                ))}
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        <NavMain items={data.navMain} currentPath={pathname} />
      </SidebarContent>
      <SidebarFooter>
        <NavUser user={data.user} />
      </SidebarFooter>
    </Sidebar>
  )
}
