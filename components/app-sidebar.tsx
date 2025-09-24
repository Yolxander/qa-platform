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
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
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
  projects: [
    { id: "merjj", name: "Merjj CMS", icon: IconBuilding },
    { id: "acme", name: "Acme Inc.", icon: IconBuilding },
    { id: "techcorp", name: "TechCorp Solutions", icon: IconBuilding },
    { id: "innovate", name: "Innovate Labs", icon: IconBuilding },
  ],
}

function AddProjectForm({ onSubmit }: { onSubmit: (projectName: string) => void }) {
  const [projectName, setProjectName] = React.useState("")

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (projectName.trim()) {
      onSubmit(projectName.trim())
      setProjectName("")
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="project-name">Project Name</Label>
        <Input
          id="project-name"
          placeholder="Enter project name..."
          value={projectName}
          onChange={(e) => setProjectName(e.target.value)}
          required
        />
      </div>
      <div className="flex justify-end gap-2">
        <Button
          type="button"
          variant="outline"
          onClick={() => setProjectName("")}
        >
          Cancel
        </Button>
        <Button type="submit" disabled={!projectName.trim()}>
          Create Project
        </Button>
      </div>
    </form>
  )
}

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const pathname = usePathname()
  const [selectedProject, setSelectedProject] = React.useState("merjj")
  const [projects, setProjects] = React.useState(data.projects)
  const [addProjectModalOpen, setAddProjectModalOpen] = React.useState(false)
  
  const currentProject = projects.find(project => project.id === selectedProject) || projects[0]
  
  const handleAddProject = (projectName: string) => {
    const newProject = {
      id: projectName.toLowerCase().replace(/\s+/g, '-'),
      name: projectName,
      icon: IconBuilding
    }
    setProjects(prev => [...prev, newProject])
    setSelectedProject(newProject.id)
    setAddProjectModalOpen(false)
  }
  
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
                    <span className="text-base font-semibold">{currentProject.name}</span>
                  </div>
                  <IconChevronDown className="size-4" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" className="w-56">
                {projects.map((project) => (
                  <DropdownMenuItem
                    key={project.id}
                    onClick={() => setSelectedProject(project.id)}
                    className={`flex items-center gap-2 ${
                      selectedProject === project.id ? "bg-accent" : ""
                    }`}
                  >
                    <project.icon className="size-4" />
                    <span>{project.name}</span>
                  </DropdownMenuItem>
                ))}
                <DropdownMenuSeparator />
                <Dialog open={addProjectModalOpen} onOpenChange={setAddProjectModalOpen}>
                  <DialogTrigger asChild>
                    <DropdownMenuItem onSelect={(e) => e.preventDefault()}>
                      <div className="flex items-center gap-2">
                        <IconBuilding className="size-4" />
                        <span>Add Project</span>
                      </div>
                    </DropdownMenuItem>
                  </DialogTrigger>
                  <DialogContent className="sm:max-w-[425px]">
                    <DialogHeader>
                      <DialogTitle>Add New Project</DialogTitle>
                      <DialogDescription>
                        Create a new project to organize your work and team collaboration.
                      </DialogDescription>
                    </DialogHeader>
                    <AddProjectForm onSubmit={handleAddProject} />
                  </DialogContent>
                </Dialog>
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
