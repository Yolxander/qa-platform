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

interface QuickActionOption {
  title: string
  description: string
  icon: React.ComponentType<{ className?: string }>
  action: () => void
}

const getPageActions = (pathname: string): QuickActionOption[] => {
  switch (pathname) {
    case "/dashboard":
      return [
        {
          title: "Create QA",
          description: "Add a new QA item to the queue",
          icon: IconFileText,
          action: () => console.log("Create QA clicked"),
        },
        {
          title: "Add Project",
          description: "Create a new project",
          icon: IconFolder,
          action: () => console.log("Add Project clicked"),
        },
        {
          title: "Report Bug",
          description: "Submit a bug report",
          icon: IconBug,
          action: () => console.log("Report Bug clicked"),
        },
        {
          title: "Add Team Member",
          description: "Invite a new team member",
          icon: IconUser,
          action: () => console.log("Add Team Member clicked"),
        },
      ]
    
    case "/bugs":
      return [
        {
          title: "New Bug",
          description: "Shortcut to report form",
          icon: IconBug,
          action: () => console.log("New Bug clicked"),
        },
        {
          title: "Export CSV",
          description: "Export current filtered view to CSV",
          icon: IconFileExport,
          action: () => console.log("Export CSV clicked"),
        },
        {
          title: "Export PDF",
          description: "Export current filtered view to PDF",
          icon: IconDownload,
          action: () => console.log("Export PDF clicked"),
        },
        {
          title: "Bulk Actions",
          description: "Assign, change status, add label",
          icon: IconSettings,
          action: () => console.log("Bulk Actions clicked"),
        },
      ]
    
    case "/my-todos":
      return [
        {
          title: "New Todo",
          description: "Create a new task",
          icon: IconClipboardList,
          action: () => console.log("New Todo clicked"),
        },
        {
          title: "Quick Add",
          description: "Add multiple tasks quickly",
          icon: IconAdd,
          action: () => console.log("Quick Add clicked"),
        },
        {
          title: "Import Tasks",
          description: "Import tasks from file",
          icon: IconDownload,
          action: () => console.log("Import Tasks clicked"),
        },
        {
          title: "Assign Tasks",
          description: "Assign tasks to team members",
          icon: IconUsers,
          action: () => console.log("Assign Tasks clicked"),
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
}

export function QuickCreateModal({ children }: QuickCreateModalProps) {
  const [open, setOpen] = React.useState(false)
  const pathname = usePathname()
  const quickActionOptions = getPageActions(pathname)

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
