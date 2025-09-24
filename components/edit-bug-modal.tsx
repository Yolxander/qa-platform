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
import { IconBug, IconLoader2 } from "@tabler/icons-react"
import { toast } from "sonner"

interface EditBugModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  bug: {
    id: number
    title: string
    description: string
    severity: string
    status: string
    environment: string
    assignee: string
    reporter: string
    url?: string
    steps_to_reproduce?: string
  }
  onBugUpdated?: () => void
}

interface TeamMember {
  id: string
  name: string
  email: string
  role: string
}

export function EditBugModal({ open, onOpenChange, bug, onBugUpdated }: EditBugModalProps) {
  const [loading, setLoading] = useState(false)
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([])
  const [teamMembersLoading, setTeamMembersLoading] = useState(false)
  const { currentProject } = useAuth()

  const [formData, setFormData] = useState({
    title: "",
    description: "",
    severity: "MEDIUM" as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
    status: "Open" as "Open" | "In Progress" | "Closed",
    environment: "Dev" as "Prod" | "Stage" | "Dev",
    assignee: "",
    url: "",
    stepsToReproduce: ""
  })

  // Load data when modal opens
  useEffect(() => {
    if (open && currentProject) {
      loadTeamMembers()
      // Populate form with current bug data
      setFormData({
        title: bug.title,
        description: bug.description || "",
        severity: bug.severity as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
        status: bug.status as "Open" | "In Progress" | "Closed",
        environment: bug.environment as "Prod" | "Stage" | "Dev",
        assignee: bug.assignee || "unassigned",
        url: bug.url || "",
        stepsToReproduce: bug.steps_to_reproduce || ""
      })
    }
  }, [open, currentProject, bug])

  const loadTeamMembers = async () => {
    try {
      setTeamMembersLoading(true)
      
      if (!supabase || !currentProject) {
        setTeamMembers([])
        return
      }

      // First get teams for the project
      const { data: teams, error: teamsError } = await supabase
        .from('teams')
        .select('id')
        .eq('project_id', currentProject.id)

      if (teamsError) throw teamsError

      if (!teams || teams.length === 0) {
        setTeamMembers([])
        return
      }

      // Then get team members for those teams
      const { data, error } = await supabase
        .from('team_members')
        .select(`
          profiles!inner(
            id,
            name,
            email
          )
        `)
        .in('team_id', teams.map(t => t.id))
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
      const { error } = await supabase
        .from('bugs')
        .update({
          title: formData.title,
          description: formData.description,
          severity: formData.severity,
          status: formData.status,
          environment: formData.environment,
          assignee: formData.assignee === "unassigned" ? "" : formData.assignee
        })
        .eq('id', bug.id)

      if (error) {
        throw error
      }

      toast.success("Bug updated successfully!")
      onOpenChange(false)
      
      if (onBugUpdated) {
        onBugUpdated()
      }
    } catch (error) {
      console.error("Error updating bug:", error)
      toast.error("Failed to update bug. Please check your Supabase configuration.")
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
            <IconBug className="size-5" />
            Edit Bug #{bug.id}
          </DialogTitle>
          <DialogDescription>
            Update the details of this bug report.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              placeholder="Enter bug title"
              value={formData.title}
              onChange={(e) => handleInputChange("title", e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              placeholder="Describe the bug in detail..."
              value={formData.description}
              onChange={(e) => handleInputChange("description", e.target.value)}
              rows={3}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="url">URL of Occurrence</Label>
            <Input
              id="url"
              placeholder="https://example.com/page-where-bug-occurs"
              value={formData.url}
              onChange={(e) => handleInputChange("url", e.target.value)}
              type="url"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="stepsToReproduce">Steps to Reproduce</Label>
            <Textarea
              id="stepsToReproduce"
              placeholder="1. Go to the page&#10;2. Click on the button&#10;3. Observe the error"
              value={formData.stepsToReproduce}
              onChange={(e) => handleInputChange("stepsToReproduce", e.target.value)}
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
              <Label htmlFor="status">Status *</Label>
              <Select
                value={formData.status}
                onValueChange={(value) => handleInputChange("status", value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Open">Open</SelectItem>
                  <SelectItem value="In Progress">In Progress</SelectItem>
                  <SelectItem value="Closed">Closed</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
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

            <div className="space-y-2">
              <Label htmlFor="assignee">Assignee</Label>
              <Select
                value={formData.assignee}
                onValueChange={(value) => handleInputChange("assignee", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select assignee" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="unassigned">Unassigned</SelectItem>
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
              Update Bug
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
