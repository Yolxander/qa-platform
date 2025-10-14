"use client"

import * as React from "react"
import { useState } from "react"
import { useAuth } from "@/contexts/AuthContext"
import { Button } from "@/components/ui/button"
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
import { IconPlus, IconLoader2 } from "@tabler/icons-react"
import { toast } from "sonner"

interface NewProjectFormProps {
  children: React.ReactNode
  onProjectCreated?: () => void
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
          {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
          {loading ? "Creating..." : "Create Project"}
        </Button>
      </div>
    </form>
  )
}

export function NewProjectForm({ children, onProjectCreated }: NewProjectFormProps) {
  const [open, setOpen] = useState(false)
  const { createProject, setCurrentProject } = useAuth()
  
  const handleAddProject = async (projectName: string, description?: string) => {
    const { error, data } = await createProject(projectName, description)
    if (error) {
      console.error('Error creating project:', error)
      toast.error(`Error creating project: ${error.message || 'Unknown error'}`)
    } else if (data) {
      setCurrentProject(data)
      toast.success("Project created successfully!")
      setOpen(false)
      if (onProjectCreated) {
        onProjectCreated()
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconPlus className="size-5" />
            Create New Project
          </DialogTitle>
          <DialogDescription>
            Create a new project to organize your work and team collaboration.
          </DialogDescription>
        </DialogHeader>
        <AddProjectForm 
          onSubmit={handleAddProject} 
          onClose={() => setOpen(false)}
        />
      </DialogContent>
    </Dialog>
  )
}
