"use client"

import * as React from "react"
import { useState } from "react"
import { useAuth } from "@/contexts/AuthContext"
import { supabase } from "@/lib/supabase"
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
import { Textarea } from "@/components/ui/textarea"
import { IconUsers, IconLoader2, IconPlus } from "@tabler/icons-react"
import { toast } from "sonner"

interface NewTeamFormProps {
  children: React.ReactNode
  onTeamCreated?: () => void
}

export function NewTeamForm({ children, onTeamCreated }: NewTeamFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const { user, currentProject } = useAuth()

  const [formData, setFormData] = useState({
    name: "",
    description: ""
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) {
      toast.error("You must be logged in to create a team")
      return
    }

    if (!currentProject) {
      toast.error("Please select a project first")
      return
    }

    if (!supabase) {
      toast.error("Database not configured. Please set up Supabase environment variables.")
      return
    }

    if (!formData.name.trim()) {
      toast.error("Team name is required")
      return
    }

    setLoading(true)
    try {
      // Use the database function to create team and auto-add creator as owner
      const { data: result, error } = await supabase
        .rpc('create_team_with_owner', {
          team_name: formData.name.trim(),
          team_description: formData.description.trim() || null,
          project_id_param: currentProject.id
        })

      if (error) {
        throw error
      }

      if (!result?.success) {
        throw new Error(result?.message || 'Failed to create team')
      }

      toast.success("Team created successfully!")
      setOpen(false)
      setFormData({
        name: "",
        description: ""
      })
      
      if (onTeamCreated) {
        onTeamCreated()
      }
    } catch (error) {
      console.error("Error creating team:", error)
      if (error.message?.includes('duplicate') || error.message?.includes('unique')) {
        toast.error("A team with this name already exists in this project")
      } else {
        toast.error("Failed to create team. Please check your Supabase configuration.")
      }
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconUsers className="size-5" />
            Create New Team
          </DialogTitle>
          <DialogDescription>
            Create a new team for {currentProject?.name || 'your project'}. You can organize team members into different teams based on their roles or responsibilities.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="name">Team Name *</Label>
            <Input
              id="name"
              placeholder="e.g., Frontend Team, QA Team, DevOps"
              value={formData.name}
              onChange={(e) => handleInputChange("name", e.target.value)}
              required
            />
            <p className="text-xs text-muted-foreground">
              Choose a descriptive name for your team.
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              placeholder="Brief description of the team's purpose or responsibilities (optional)"
              value={formData.description}
              onChange={(e) => handleInputChange("description", e.target.value)}
              rows={3}
            />
            <p className="text-xs text-muted-foreground">
              Optional description to help team members understand the team's purpose.
            </p>
          </div>

          <div className="flex justify-end space-x-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={() => setOpen(false)}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
              <IconPlus className="mr-2 size-4" />
              Create Team
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
