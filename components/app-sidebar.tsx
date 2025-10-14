"use client"

import * as React from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  IconChartBar,
  IconDashboard,
  IconInnerShadowTop,
  IconListDetails,
  IconUsers,
  IconChevronDown,
  IconBuilding,
  IconUsersGroup,
  IconLock,
  IconRobot,
  IconMessageCircle,
  IconActivity,
  IconTools,
  IconUserPlus,
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
  SidebarGroup,
  SidebarGroupContent,
} from "@/components/ui/sidebar"
import { useAuth, ALL_PROJECTS_MARKER } from "@/contexts/AuthContext"

const data = {
  navMain: [
    {
      title: "Dashboard",
      url: "/dashboard",
      icon: IconDashboard,
    },
  ],
  navWorkflow: [
    {
      title: "Bugs",
      url: "/bugs",
      icon: IconUsers,
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
      title: "Teams",
      url: "/teams",
      icon: IconUsersGroup,
    },
  ],
  navPro: [
    {
      title: "QA Automation",
      icon: IconRobot,
      isPro: true,
    },
    {
      title: "Chat Mode",
      icon: IconMessageCircle,
      isPro: true,
    },
    {
      title: "Monitoring",
      icon: IconActivity,
      isPro: true,
    },
  ],
  projects: [
    { id: "merjj", name: "Merjj CMS", icon: IconBuilding },
    { id: "acme", name: "Acme Inc.", icon: IconBuilding },
    { id: "techcorp", name: "TechCorp Solutions", icon: IconBuilding },
    { id: "innovate", name: "Innovate Labs", icon: IconBuilding },
  ],
}

function ProSubscriptionModal({ isOpen, onClose, featureName }: { isOpen: boolean; onClose: () => void; featureName: string }) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconLock className="size-5 text-amber-500" />
            Pro Subscription Required
          </DialogTitle>
          <DialogDescription>
            {featureName} is a premium feature available with our Pro subscription.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="text-center">
            <p className="text-sm text-muted-foreground mb-4">
              Unlock advanced features and take your productivity to the next level.
            </p>
            <div className="bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4">
              <p className="text-sm font-medium text-amber-800 dark:text-amber-200">
                Contact us if you're interested in upgrading to Pro!
              </p>
            </div>
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose}>
              Close
            </Button>
            <Button onClick={() => {
              // You can add contact functionality here
              window.open('mailto:support@example.com?subject=Pro Subscription Inquiry', '_blank')
              onClose()
            }}>
              Contact Us
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function MaintenanceModal({ isOpen, onClose, featureName }: { isOpen: boolean; onClose: () => void; featureName: string }) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconTools className="size-5 text-orange-500" />
            Under Maintenance
          </DialogTitle>
          <DialogDescription>
            {featureName} is currently under maintenance.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="text-center">
            <p className="text-sm text-muted-foreground mb-4">
              This page is currently under maintenance. It will be available in a few hours, thank you for your patience.
            </p>
            <div className="bg-orange-50 dark:bg-orange-950/20 border border-orange-200 dark:border-orange-800 rounded-lg p-4">
              <p className="text-sm font-medium text-orange-800 dark:text-orange-200">
                We're working hard to improve your experience!
              </p>
            </div>
          </div>
          <div className="flex justify-end">
            <Button onClick={onClose}>
              Got it
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function AddProjectForm({ onSubmit, onClose }: { onSubmit: (projectName: string, description?: string) => void; onClose: () => void }) {
  const [projectName, setProjectName] = React.useState("")
  const [description, setDescription] = React.useState("")
  const [loading, setLoading] = React.useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (projectName.trim()) {
      setLoading(true)
      try {
        await onSubmit(projectName.trim(), description.trim() || undefined)
        setProjectName("")
        setDescription("")
        onClose()
      } catch (error) {
        console.error('Error creating project:', error)
      } finally {
        setLoading(false)
      }
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
      <div className="space-y-2">
        <Label htmlFor="project-description">Description (Optional)</Label>
        <Input
          id="project-description"
          placeholder="Enter project description..."
          value={description}
          onChange={(e) => setDescription(e.target.value)}
        />
      </div>
      <div className="flex justify-end gap-2">
        <Button
          type="button"
          variant="outline"
          onClick={() => {
            setProjectName("")
            setDescription("")
            onClose()
          }}
          disabled={loading}
        >
          Cancel
        </Button>
        <Button type="submit" disabled={!projectName.trim() || loading}>
          {loading ? "Creating..." : "Create Project"}
        </Button>
      </div>
    </form>
  )
}

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const pathname = usePathname()
  const { projects, currentProject, createProject, setCurrentProject } = useAuth()
  const [addProjectModalOpen, setAddProjectModalOpen] = React.useState(false)
  const [proModalOpen, setProModalOpen] = React.useState(false)
  const [proFeatureName, setProFeatureName] = React.useState("")
  const [maintenanceModalOpen, setMaintenanceModalOpen] = React.useState(false)
  const [maintenanceFeatureName, setMaintenanceFeatureName] = React.useState("")
  
  const handleAddProject = async (projectName: string, description?: string) => {
    try {
      const { error, data } = await createProject(projectName, description)
      if (error) {
        console.error('Error creating project:', error)
        
        // Show more user-friendly error messages
        let userMessage = error.message || 'Unknown error occurred'
        
        // Provide specific guidance based on error type
        if (userMessage.includes('Supabase not configured')) {
          userMessage = 'Database not configured. Please contact your administrator to set up Supabase.'
        } else if (userMessage.includes('User not authenticated')) {
          userMessage = 'Please log in to create a project.'
        } else if (userMessage.includes('Projects table does not exist')) {
          userMessage = 'Database setup incomplete. Please contact your administrator.'
        } else if (userMessage.includes('Network error') || userMessage.includes('Failed to fetch')) {
          userMessage = 'Connection error. Please check your internet connection and try again.'
        }
        
        alert(`Error creating project: ${userMessage}`)
      } else if (data) {
        setCurrentProject(data)
      }
    } catch (error) {
      console.error('Unexpected error in handleAddProject:', error)
      alert('An unexpected error occurred. Please try again.')
    }
  }

  const handleProFeatureClick = (featureName: string) => {
    setProFeatureName(featureName)
    setProModalOpen(true)
  }

  const handleMaintenanceFeatureClick = (featureName: string) => {
    setMaintenanceFeatureName(featureName)
    setMaintenanceModalOpen(true)
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
                    <span className="text-base font-semibold">
                      {currentProject === ALL_PROJECTS_MARKER 
                        ? "All Projects" 
                        : currentProject?.name || "No Project"
                      }
                    </span>
                  </div>
                  <IconChevronDown className="size-4" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" className="w-56">
                <DropdownMenuItem
                  onClick={() => setCurrentProject(ALL_PROJECTS_MARKER)}
                  className={`flex items-center gap-2 ${
                    currentProject === ALL_PROJECTS_MARKER ? "bg-accent" : ""
                  }`}
                >
                  <IconChartBar className="size-4 text-purple-500" />
                  <span className="flex-1 font-medium">All Projects</span>
                  <span className="text-xs bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded-full">
                    Aggregated
                  </span>
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                {projects.map((project) => (
                  <DropdownMenuItem
                    key={project.id}
                    onClick={() => setCurrentProject(project)}
                    className={`flex items-center gap-2 ${
                      currentProject && typeof currentProject === 'object' && currentProject.id === project.id ? "bg-accent" : ""
                    }`}
                  >
                    {project.isInvited ? (
                      <IconUserPlus className="size-4 text-blue-500" />
                    ) : (
                      <IconBuilding className="size-4" />
                    )}
                    <span className="flex-1">{project.name}</span>
                    {project.isInvited && (
                      <span className="text-xs bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded-full">
                        Invited
                      </span>
                    )}
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
                    <AddProjectForm 
                      onSubmit={handleAddProject} 
                      onClose={() => setAddProjectModalOpen(false)}
                    />
                  </DialogContent>
                </Dialog>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        <NavMain items={data.navMain} currentPath={pathname} />
        
        <SidebarGroup>
          <SidebarGroupContent className="flex flex-col gap-2">
            <SidebarMenu>
              {data.navWorkflow.map((item) => {
                const isActive = pathname === item.url
                const isUnderMaintenance = item.underMaintenance
                const isInvitedProject = currentProject?.isInvited
                
                // Hide "Ready for QA" for invited projects, but allow "Teams"
                if (isInvitedProject && item.title === "Ready for QA") {
                  return null
                }
                
                return (
                  <SidebarMenuItem key={item.title}>
                    {isUnderMaintenance ? (
                      <SidebarMenuButton 
                        tooltip={item.title}
                        onClick={() => handleMaintenanceFeatureClick(item.title)}
                        className="cursor-pointer hover:bg-accent/50"
                      >
                        {item.icon && <item.icon />}
                        <span>{item.title}</span>
                        <IconTools className="ml-auto size-4 text-orange-500" />
                      </SidebarMenuButton>
                    ) : (
                      <SidebarMenuButton 
                        tooltip={item.title}
                        isActive={isActive}
                        className={isActive ? "bg-accent text-accent-foreground" : ""}
                        asChild
                      >
                        <Link href={item.url}>
                          {item.icon && <item.icon />}
                          <span>{item.title}</span>
                        </Link>
                      </SidebarMenuButton>
                    )}
                  </SidebarMenuItem>
                )
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        <SidebarGroup>
          <SidebarGroupContent className="flex flex-col gap-2">
            <SidebarMenu>
              {data.navPro.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton 
                    tooltip={item.title}
                    onClick={() => handleProFeatureClick(item.title)}
                    className="cursor-pointer hover:bg-accent/50"
                  >
                    {item.icon && <item.icon />}
                    <span>{item.title}</span>
                    <IconLock className="ml-auto size-4 text-amber-500" />
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter>
        <NavUser />
      </SidebarFooter>
      
      <ProSubscriptionModal 
        isOpen={proModalOpen} 
        onClose={() => setProModalOpen(false)} 
        featureName={proFeatureName} 
      />
      
      <MaintenanceModal 
        isOpen={maintenanceModalOpen} 
        onClose={() => setMaintenanceModalOpen(false)} 
        featureName={maintenanceFeatureName} 
      />
    </Sidebar>
  )
}
