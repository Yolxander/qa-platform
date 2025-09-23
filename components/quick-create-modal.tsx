"use client"

import * as React from "react"
import { IconPlus, IconFileText, IconFolder, IconBug, IconUser } from "@tabler/icons-react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"

const quickCreateOptions = [
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

interface QuickCreateModalProps {
  children: React.ReactNode
}

export function QuickCreateModal({ children }: QuickCreateModalProps) {
  const [open, setOpen] = React.useState(false)

  const handleOptionClick = (action: () => void) => {
    action()
    setOpen(false)
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
            Quick Create
          </DialogTitle>
          <DialogDescription>
            Choose what you'd like to create or add to your workspace.
          </DialogDescription>
        </DialogHeader>
        <div className="grid grid-cols-1 gap-3 py-4">
          {quickCreateOptions.map((option) => {
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
