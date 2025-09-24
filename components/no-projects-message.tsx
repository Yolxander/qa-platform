"use client"

import * as React from "react"
import { IconBuilding, IconPlus } from "@tabler/icons-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
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
import { useAuth } from "@/contexts/AuthContext"

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

export function NoProjectsMessage() {
  const { createProject, setCurrentProject } = useAuth()
  const [addProjectModalOpen, setAddProjectModalOpen] = React.useState(false)
  
  const handleAddProject = async (projectName: string, description?: string) => {
    const { error, data } = await createProject(projectName, description)
    if (error) {
      console.error('Error creating project:', error)
      alert(`Error creating project: ${error.message || 'Unknown error'}. Please check the console for more details.`)
    } else if (data) {
      setCurrentProject(data)
    }
  }

  return (
    <div className="flex items-center justify-center min-h-[400px] p-8">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10">
            <IconBuilding className="h-6 w-6 text-primary" />
          </div>
          <CardTitle>Add New Project</CardTitle>
          <CardDescription>
            Create a new project to organize your work and team collaboration.
          </CardDescription>
        </CardHeader>
        <CardContent className="text-center">
          <Dialog open={addProjectModalOpen} onOpenChange={setAddProjectModalOpen}>
            <DialogTrigger asChild>
              <Button className="w-full">
                <IconPlus className="mr-2 h-4 w-4" />
                Create Your First Project
              </Button>
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
        </CardContent>
      </Card>
    </div>
  )
}
