"use client"

import * as React from "react"
import { useState, useEffect } from "react"
import { useAuth } from "@/contexts/AuthContext"
import { supabase } from "@/lib/supabase"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
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
import { IconEdit, IconLoader2 } from "@tabler/icons-react"
import { toast } from "sonner"

interface EditTodoModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  todo: {
    id: number
    title: string
    issue_link: string
    severity: string
    environment: string
    assignee: string
    due_date: string
    status: string
  }
  onTodoUpdated?: () => void
}

interface BugItem {
  id: number
  title: string
  severity: string
  status: string
}

interface TeamMember {
  id: string
  name: string
  email: string
  role: string
}

export function EditTodoModal({ open, onOpenChange, todo, onTodoUpdated }: EditTodoModalProps) {
  const [loading, setLoading] = useState(false)
  const [bugs, setBugs] = useState<BugItem[]>([])
  const [bugsLoading, setBugsLoading] = useState(false)
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([])
  const [teamMembersLoading, setTeamMembersLoading] = useState(false)
  const { currentProject } = useAuth()

  const [formData, setFormData] = useState({
    title: "",
    issue_link: "",
    severity: "MEDIUM" as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
    environment: "Dev" as "Prod" | "Stage" | "Dev",
    assignee: "",
    due_date: "Today",
    status: "OPEN" as "OPEN" | "IN_PROGRESS" | "READY_FOR_QA" | "DONE"
  })

  // Load data when modal opens
  useEffect(() => {
    if (open && currentProject) {
      loadOpenBugs()
      loadTeamMembers()
      // Populate form with current todo data
      setFormData({
        title: todo.title,
        issue_link: todo.issue_link || "",
        severity: todo.severity as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
        environment: todo.environment as "Prod" | "Stage" | "Dev",
        assignee: todo.assignee,
        due_date: todo.due_date,
        status: todo.status as "OPEN" | "IN_PROGRESS" | "READY_FOR_QA" | "DONE"
      })
    }
  }, [open, currentProject, todo])

  const loadOpenBugs = async () => {
    try {
      setBugsLoading(true)
      
      if (!supabase || !currentProject) {
        setBugs([])
        return
      }

      const { data, error } = await supabase
        .from('bugs')
        .select('id, title, severity, status')
        .eq('project_id', currentProject.id)
        .in('status', ['Open', 'In Progress'])
        .order('created_at', { ascending: false })

      if (error) throw error
      setBugs(data || [])
    } catch (error) {
      console.error("Error loading bugs:", error)
      setBugs([])
    } finally {
      setBugsLoading(false)
    }
  }

  const loadTeamMembers = async () => {
    try {
      setTeamMembersLoading(true)
      
      if (!supabase || !currentProject) {
        setTeamMembers([])
        return
      }

      const { data, error } = await supabase
        .from('team_members')
        .select(`
          profiles!inner(
            id,
            name,
            email
          )
        `)
        .eq('teams.project_id', currentProject.id)
        .order('profiles.name')

      if (error) throw error

      const members = (data || []).map(member => ({
        id: member.profiles.id,
        name: member.profiles.name || 'Unknown',
        email: member.profiles.email,
        role: 'member'
      }))

      setTeamMembers(members)
    } catch (error) {
      console.error("Error loading team members:", error)
      setTeamMembers([])
    } finally {
      setTeamMembersLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!supabase) {
      toast.error("Database not configured. Please set up Supabase environment variables.")
      return
    }

    setLoading(true)
    try {
      // Process issue link
      let issueLink = null
      if (formData.issue_link && formData.issue_link.startsWith('bug-')) {
        const bugId = formData.issue_link.replace('bug-', '')
        issueLink = `bug-${bugId}`
      }

      const { error } = await supabase
        .from('todos')
        .update({
          title: formData.title,
          issue_link: issueLink,
          severity: formData.severity,
          environment: formData.environment,
          assignee: formData.assignee,
          due_date: formData.due_date,
          status: formData.status
        })
        .eq('id', todo.id)

      if (error) {
        throw error
      }

      toast.success("Todo updated successfully!")
      onOpenChange(false)
      
      if (onTodoUpdated) {
        onTodoUpdated()
      }
    } catch (error) {
      console.error("Error updating todo:", error)
      toast.error("Failed to update todo. Please check your Supabase configuration.")
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
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconEdit className="size-5" />
            Edit Todo
          </DialogTitle>
          <DialogDescription>
            Update the details of this task.
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
            <Label htmlFor="issue_link">Link to Bug (Optional)</Label>
            <Select
              value={formData.issue_link || "none"}
              onValueChange={(value) => handleInputChange("issue_link", value === "none" ? "" : value)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select a bug to link to" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="none">No bug linked</SelectItem>
                {bugsLoading ? (
                  <SelectItem value="loading" disabled>Loading bugs...</SelectItem>
                ) : bugs.length === 0 ? (
                  <SelectItem value="no-bugs" disabled>No open bugs found</SelectItem>
                ) : (
                  bugs.map((bug) => (
                    <SelectItem key={bug.id} value={`bug-${bug.id}`}>
                      <div className="flex flex-col">
                        <span className="font-medium">{bug.title}</span>
                        <span className="text-xs text-muted-foreground">
                          #{bug.id} • {bug.severity} • {bug.status}
                        </span>
                      </div>
                    </SelectItem>
                  ))
                )}
              </SelectContent>
            </Select>
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
              <Select
                value={formData.assignee}
                onValueChange={(value) => handleInputChange("assignee", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select team member" />
                </SelectTrigger>
                <SelectContent>
                  {teamMembersLoading ? (
                    <SelectItem value="loading" disabled>Loading team members...</SelectItem>
                  ) : teamMembers.length === 0 ? (
                    <SelectItem value="no-members" disabled>No team members found</SelectItem>
                  ) : (
                    teamMembers.map((member) => (
                      <SelectItem key={member.id} value={member.name}>
                        <div className="flex flex-col">
                          <span className="font-medium">{member.name}</span>
                          <span className="text-xs text-muted-foreground">
                            {member.email}
                          </span>
                        </div>
                      </SelectItem>
                    ))
                  )}
                </SelectContent>
              </Select>
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

          <div className="space-y-2">
            <Label htmlFor="status">Status *</Label>
            <Select
              value={formData.status}
              onValueChange={(value) => handleInputChange("status", value)}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="OPEN">Open</SelectItem>
                <SelectItem value="IN_PROGRESS">In Progress</SelectItem>
                <SelectItem value="READY_FOR_QA">Ready for QA</SelectItem>
                <SelectItem value="DONE">Done</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="flex justify-end space-x-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
              Update Todo
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}

