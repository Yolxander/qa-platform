"use client"

import * as React from "react"
import { usePathname } from "next/navigation"
import { 
  IconPlus, 
  IconFileText, 
  IconFolder, 
  IconBug, 
  IconUser,
  IconDownload,
  IconSettings,
  IconCheck,
  IconClipboardList,
  IconPlus as IconAdd,
  IconUsers,
  IconFileExport
} from "@tabler/icons-react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { NewTodoForm } from "@/components/new-todo-form"
import { QuickAddForm } from "@/components/quick-add-form"
import { AssignTasksForm } from "@/components/assign-tasks-form"
import { NewBugForm } from "@/components/new-bug-form"
import { NewTeamForm } from "@/components/new-team-form"
import { NewProjectForm } from "@/components/new-project-form"
import { AddTeamMemberForm } from "@/components/add-team-member-form"

interface QuickActionOption {
  title: string
  description: string
  icon: React.ComponentType<{ className?: string }>
  action: () => void
  component?: React.ComponentType<any>
}

const getPageActions = (pathname: string, userRole?: string): QuickActionOption[] => {
  console.log('QuickCreateModal getPageActions called with:', { pathname, userRole })
  
  switch (pathname) {
    case "/dashboard":
      const actions: QuickActionOption[] = []
      
      // Role-based action filtering
      console.log('QuickCreateModal: Filtering actions for role:', userRole)
      if (userRole === 'owner') {
        console.log('QuickCreateModal: Adding owner actions')
        // Owner: Create project, report bug, create QA, add team member
        actions.push(
          {
            title: "Add Project",
            description: "Create a new project",
            icon: IconFolder,
            action: () => console.log("Add Project clicked"),
            component: NewProjectForm,
          },
          {
            title: "Create QA",
            description: "Add a new QA item to the queue",
            icon: IconFileText,
            action: () => console.log("Create QA clicked"),
            component: NewTodoForm,
          },
          {
            title: "Report Bug",
            description: "Submit a bug report",
            icon: IconBug,
            action: () => console.log("Report Bug clicked"),
            component: NewBugForm,
          },
          {
            title: "Add Team Member",
            description: "Invite a new team member",
            icon: IconUser,
            action: () => console.log("Add Team Member clicked"),
            component: AddTeamMemberForm,
          }
        )
      } else if (userRole === 'developer' || userRole === 'tester') {
        console.log('QuickCreateModal: Adding developer/tester actions')
        // Developer/Tester: Create QA, report bug, add team member
        actions.push(
          {
            title: "Create QA",
            description: "Add a new QA item to the queue",
            icon: IconFileText,
            action: () => console.log("Create QA clicked"),
            component: NewTodoForm,
          },
          {
            title: "Report Bug",
            description: "Submit a bug report",
            icon: IconBug,
            action: () => console.log("Report Bug clicked"),
            component: NewBugForm,
          },
          {
            title: "Add Team Member",
            description: "Invite a new team member",
            icon: IconUser,
            action: () => console.log("Add Team Member clicked"),
            component: AddTeamMemberForm,
          }
        )
      } else {
        console.log('QuickCreateModal: Adding guest actions (fallback)')
        // Guest: Only report bug
        actions.push(
          {
            title: "Report Bug",
            description: "Submit a bug report",
            icon: IconBug,
            action: () => console.log("Report Bug clicked"),
            component: NewBugForm,
          }
        )
      }
      
      console.log('QuickCreateModal: Returning actions:', actions.map(a => a.title))
      console.log('QuickCreateModal: Final role check - userRole:', userRole, 'typeof:', typeof userRole)
      return actions
    
    case "/bugs":
      return [
        {
          title: "New Bug",
          description: "Shortcut to report form",
          icon: IconBug,
          action: () => console.log("New Bug clicked"),
          component: NewBugForm,
        },
        {
          title: "Bulk Actions",
          description: "Assign, change status, add label",
          icon: IconSettings,
          action: () => console.log("Bulk Actions clicked"),
        },
      ]
    
    case "/teams":
      return [
        {
          title: "Create Team",
          description: "Create a new team for the project",
          icon: IconUsers,
          action: () => console.log("Create Team clicked"),
          component: NewTeamForm,
        },
        {
          title: "Add Member",
          description: "Add a new team member",
          icon: IconUser,
          action: () => console.log("Add Member clicked"),
        },
        {
          title: "Edit Team",
          description: "Update team information",
          icon: IconSettings,
          action: () => console.log("Edit Team clicked"),
        },
      ]
    
    case "/my-todos":
      return [
        {
          title: "New Todo",
          description: "Create a new task",
          icon: IconClipboardList,
          action: () => console.log("New Todo clicked"),
          component: NewTodoForm,
        },
        {
          title: "Quick Add",
          description: "Add multiple tasks quickly",
          icon: IconAdd,
          action: () => console.log("Quick Add clicked"),
          component: QuickAddForm,
        },
        {
          title: "Assign Tasks",
          description: "Assign tasks to team members",
          icon: IconUsers,
          action: () => console.log("Assign Tasks clicked"),
          component: AssignTasksForm,
        },
      ]
    
    case "/ready-for-qa":
      return [
        {
          title: "Start QA Review",
          description: "Begin reviewing items in queue",
          icon: IconCheck,
          action: () => console.log("Start QA Review clicked"),
        },
        {
          title: "Batch Approve",
          description: "Approve multiple items at once",
          icon: IconClipboardList,
          action: () => console.log("Batch Approve clicked"),
        },
        {
          title: "Export QA Report",
          description: "Generate QA summary report",
          icon: IconFileExport,
          action: () => console.log("Export QA Report clicked"),
        },
        {
          title: "QA Settings",
          description: "Configure QA workflow",
          icon: IconSettings,
          action: () => console.log("QA Settings clicked"),
        },
      ]
    
    default:
      if (pathname.startsWith("/bug/")) {
        return [
          {
            title: "Edit Bug",
            description: "Modify bug details",
            icon: IconBug,
            action: () => console.log("Edit Bug clicked"),
          },
          {
            title: "Add Comment",
            description: "Add update or comment",
            icon: IconFileText,
            action: () => console.log("Add Comment clicked"),
          },
          {
            title: "Assign Bug",
            description: "Assign to team member",
            icon: IconUser,
            action: () => console.log("Assign Bug clicked"),
          },
          {
            title: "Export Bug",
            description: "Export bug details",
            icon: IconDownload,
            action: () => console.log("Export Bug clicked"),
          },
        ]
      }
      
      if (pathname.startsWith("/verify/")) {
        return [
          {
            title: "Verify Item",
            description: "Mark item as verified",
            icon: IconCheck,
            action: () => console.log("Verify Item clicked"),
          },
          {
            title: "Request Changes",
            description: "Request modifications",
            icon: IconFileText,
            action: () => console.log("Request Changes clicked"),
          },
          {
            title: "Add Notes",
            description: "Add verification notes",
            icon: IconClipboardList,
            action: () => console.log("Add Notes clicked"),
          },
          {
            title: "Export Report",
            description: "Export verification report",
            icon: IconFileExport,
            action: () => console.log("Export Report clicked"),
          },
        ]
      }
      
      // Default fallback
      return [
        {
          title: "Create QA",
          description: "Add a new QA item to the queue",
          icon: IconFileText,
          action: () => console.log("Create QA clicked"),
        },
        {
          title: "Report Bug",
          description: "Submit a bug report",
          icon: IconBug,
          action: () => console.log("Report Bug clicked"),
        },
        {
          title: "Add Project",
          description: "Create a new project",
          icon: IconFolder,
          action: () => console.log("Add Project clicked"),
        },
        {
          title: "Add Team Member",
          description: "Invite a new team member",
          icon: IconUser,
          action: () => console.log("Add Team Member clicked"),
        },
      ]
  }
}

interface QuickCreateModalProps {
  children: React.ReactNode
  userRole?: string
  onTodoCreated?: () => void
  onTasksAssigned?: () => void
  onBugCreated?: () => void
  onTeamCreated?: () => void
  onProjectCreated?: () => void
}

export function QuickCreateModal({ children, userRole, onTodoCreated, onTasksAssigned, onBugCreated, onTeamCreated, onProjectCreated }: QuickCreateModalProps) {
  const [open, setOpen] = React.useState(false)
  const pathname = usePathname()
  const quickActionOptions = getPageActions(pathname, userRole)

  const handleOptionClick = (action: () => void) => {
    action()
    setOpen(false)
  }

  const getModalTitle = (pathname: string): string => {
    switch (pathname) {
      case "/dashboard":
        return "Dashboard Actions"
      case "/bugs":
        return "Bug Actions"
      case "/teams":
        return "Team Actions"
      case "/my-todos":
        return "Todo Actions"
      case "/ready-for-qa":
        return "QA Actions"
      default:
        if (pathname.startsWith("/bug/")) {
          return "Bug Actions"
        }
        if (pathname.startsWith("/verify/")) {
          return "Verification Actions"
        }
        return "Quick Actions"
    }
  }

  const getModalDescription = (pathname: string): string => {
    switch (pathname) {
      case "/dashboard":
        return "Choose an action to manage your dashboard and projects."
      case "/bugs":
        return "Select an action to work with bug reports and issues."
      case "/teams":
        return "Choose an action to manage your project team."
      case "/my-todos":
        return "Choose an action to manage your tasks and todos."
      case "/ready-for-qa":
        return "Select an action to work with items ready for QA review."
      default:
        if (pathname.startsWith("/bug/")) {
          return "Choose an action to work with this bug report."
        }
        if (pathname.startsWith("/verify/")) {
          return "Select an action for verification and review."
        }
        return "Choose what you'd like to do."
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconPlus className="size-5" />
            {getModalTitle(pathname)}
          </DialogTitle>
          <DialogDescription>
            {getModalDescription(pathname)}
          </DialogDescription>
        </DialogHeader>
        <div className="grid grid-cols-1 gap-3 py-4">
          {quickActionOptions.map((option) => {
            const IconComponent = option.icon
            const Component = option.component
            
            if (Component) {
              return (
                <Component
                  key={option.title}
                  onTodoCreated={onTodoCreated}
                  onTasksAssigned={onTasksAssigned}
                  onBugCreated={onBugCreated || (() => window.location.reload())}
                  onTeamCreated={onTeamCreated}
                  onProjectCreated={onProjectCreated}
                >
                  <Button
                    variant="outline"
                    className="h-auto p-4 justify-start text-left w-full"
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                        <IconComponent className="size-5 text-primary" />
                      </div>
                      <div className="flex flex-col items-start">
                        <span className="font-medium">{option.title}</span>
                        <span className="text-sm text-muted-foreground">
                          {option.description}
                        </span>
                      </div>
                    </div>
                  </Button>
                </Component>
              )
            }
            
            return (
              <Button
                key={option.title}
                variant="outline"
                className="h-auto p-4 justify-start text-left"
                onClick={() => handleOptionClick(option.action)}
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                    <IconComponent className="size-5 text-primary" />
                  </div>
                  <div className="flex flex-col items-start">
                    <span className="font-medium">{option.title}</span>
                    <span className="text-sm text-muted-foreground">
                      {option.description}
                    </span>
                  </div>
                </div>
              </Button>
            )
          })}
        </div>
      </DialogContent>
    </Dialog>
  )
}
