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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { IconPlus, IconLoader2 } from "@tabler/icons-react"
import { toast } from "sonner"

interface NewTodoFormProps {
  children: React.ReactNode
  onTodoCreated?: () => void
}

export function NewTodoForm({ children, onTodoCreated }: NewTodoFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const { user } = useAuth()

  const [formData, setFormData] = useState({
    title: "",
    issue_link: "",
    severity: "MEDIUM" as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
    environment: "Dev" as "Prod" | "Stage" | "Dev",
    assignee: "",
    due_date: "Today"
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) {
      toast.error("You must be logged in to create a todo")
      return
    }

    if (!supabase) {
      toast.error("Database not configured. Please set up Supabase environment variables.")
      return
    }

    setLoading(true)
    try {
      const { error } = await supabase
        .from('todos')
        .insert({
          title: formData.title,
          issue_link: formData.issue_link || null,
          severity: formData.severity,
          environment: formData.environment,
          assignee: formData.assignee,
          due_date: formData.due_date,
          quick_action: "Start",
          user_id: user.id
        })

      if (error) {
        throw error
      }

      toast.success("Todo created successfully!")
      setOpen(false)
      setFormData({
        title: "",
        issue_link: "",
        severity: "MEDIUM",
        environment: "Dev",
        assignee: "",
        due_date: "Today"
      })
      
      if (onTodoCreated) {
        onTodoCreated()
      }
    } catch (error) {
      console.error("Error creating todo:", error)
      toast.error("Failed to create todo. Please check your Supabase configuration.")
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
            <IconPlus className="size-5" />
            New Todo
          </DialogTitle>
          <DialogDescription>
            Create a new task to track and manage.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              placeholder="Enter todo title"
              value={formData.title}
              onChange={(e) => handleInputChange("title", e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="issue_link">Issue Link</Label>
            <Input
              id="issue_link"
              placeholder="#1234 or URL"
              value={formData.issue_link}
              onChange={(e) => handleInputChange("issue_link", e.target.value)}
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
              <Label htmlFor="assignee">Assignee *</Label>
              <Input
                id="assignee"
                placeholder="Team member name"
                value={formData.assignee}
                onChange={(e) => handleInputChange("assignee", e.target.value)}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="due_date">Due Date *</Label>
              <Select
                value={formData.due_date}
                onValueChange={(value) => handleInputChange("due_date", value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Today">Today</SelectItem>
                  <SelectItem value="Tomorrow">Tomorrow</SelectItem>
                  <SelectItem value="3d left">3 days left</SelectItem>
                  <SelectItem value="1w left">1 week left</SelectItem>
                </SelectContent>
              </Select>
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
              Create Todo
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
