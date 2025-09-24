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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { IconBug, IconLoader2 } from "@tabler/icons-react"
import { toast } from "sonner"

interface NewBugFormProps {
  children: React.ReactNode
  onBugCreated?: () => void
}

export function NewBugForm({ children, onBugCreated }: NewBugFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const { user, currentProject } = useAuth()

  const [formData, setFormData] = useState({
    title: "",
    description: "",
    severity: "MEDIUM" as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
    environment: "Dev" as "Prod" | "Stage" | "Dev",
    reporter: "",
    assignee: ""
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) {
      toast.error("You must be logged in to report a bug")
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

    setLoading(true)
    try {
      const { data: insertedBug, error } = await supabase
        .from('bugs')
        .insert({
          title: formData.title,
          description: formData.description,
          severity: formData.severity,
          environment: formData.environment,
          reporter: formData.reporter,
          assignee: formData.assignee || "Unassigned",
          user_id: user.id,
          project_id: currentProject.id
        })
        .select()
        .single()

      if (error) {
        throw error
      }

      toast.success("Bug reported successfully!")
      setOpen(false)
      setFormData({
        title: "",
        description: "",
        severity: "MEDIUM",
        environment: "Dev",
        reporter: "",
        assignee: ""
      })
      
      if (onBugCreated) {
        onBugCreated()
      }
    } catch (error) {
      console.error("Error reporting bug:", error)
      toast.error("Failed to report bug. Please check your Supabase configuration.")
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
            <IconBug className="size-5" />
            Report New Bug
          </DialogTitle>
          <DialogDescription>
            Report a bug or issue for the current project.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              placeholder="Brief description of the bug"
              value={formData.title}
              onChange={(e) => handleInputChange("title", e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              placeholder="Detailed description of the bug, steps to reproduce, expected vs actual behavior"
              value={formData.description}
              onChange={(e) => handleInputChange("description", e.target.value)}
              rows={4}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="severity">Severity *</Label>
              <Select
                value={formData.severity}
                onValueChange={(value) => handleInputChange("severity", value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="CRITICAL">Critical</SelectItem>
                  <SelectItem value="HIGH">High</SelectItem>
                  <SelectItem value="MEDIUM">Medium</SelectItem>
                  <SelectItem value="LOW">Low</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="environment">Environment *</Label>
              <Select
                value={formData.environment}
                onValueChange={(value) => handleInputChange("environment", value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Prod">Production</SelectItem>
                  <SelectItem value="Stage">Staging</SelectItem>
                  <SelectItem value="Dev">Development</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="reporter">Reporter *</Label>
              <Input
                id="reporter"
                placeholder="Your name"
                value={formData.reporter}
                onChange={(e) => handleInputChange("reporter", e.target.value)}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="assignee">Assignee</Label>
              <Input
                id="assignee"
                placeholder="Team member name (optional)"
                value={formData.assignee}
                onChange={(e) => handleInputChange("assignee", e.target.value)}
              />
            </div>
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
              Report Bug
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
