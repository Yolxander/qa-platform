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
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Switch } from "@/components/ui/switch"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { IconBug, IconLoader2, IconChevronLeft, IconChevronRight, IconCheck, IconAlertTriangle, IconUser, IconBriefcase, IconGlobe, IconBuildingFactory } from "@tabler/icons-react"
import { toast } from "sonner"
import { cn } from "@/lib/utils"

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

const steps = [
  {
    id: 1,
    title: "Basic Info",
    description: "Bug title and description"
  },
  {
    id: 2,
    title: "Details",
    description: "URL and reproduction steps"
  },
  {
    id: 3,
    title: "Classification",
    description: "Severity and environment"
  },
  {
    id: 4,
    title: "Assignment",
    description: "Status and assignee"
  },
  {
    id: 5,
    title: "Review",
    description: "Review and save changes"
  }
]

export function EditBugModal({ open, onOpenChange, bug, onBugUpdated }: EditBugModalProps) {
  const [loading, setLoading] = useState(false)
  const [currentStep, setCurrentStep] = useState(1)
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
      setCurrentStep(1) // Reset to first step
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

  const handleNext = () => {
    if (currentStep < 5) {
      setCurrentStep(currentStep + 1)
    }
  }

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1)
    }
  }

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

  const renderStepContent = () => {
    switch (currentStep) {
      case 1:
        return (
          <div className="space-y-4">
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
                placeholder="Detailed description of the bug, expected vs actual behavior"
                value={formData.description}
                onChange={(e) => handleInputChange("description", e.target.value)}
                rows={3}
              />
            </div>
          </div>
        )

      case 2:
        return (
          <div className="space-y-4">
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
          </div>
        )

      case 3:
        return (
          <div className="space-y-4">
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
          </div>
        )

      case 4:
        return (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="status">Status *</Label>
                <Select
                  value={formData.status}
                  onValueChange={(value) => handleInputChange("status", value)}>
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

              <div className="space-y-2">
                <Label htmlFor="assignee">Assignee</Label>
                <Select
                  value={formData.assignee}
                  onValueChange={(value) => handleInputChange("assignee", value)}>
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
          </div>
        )

      case 5:
        return (
          <div className="space-y-4">
            <div className="space-y-3">
              <div className="rounded-lg border p-3">
                <h4 className="font-medium mb-2 text-sm">Basic Information</h4>
                <p className="text-sm text-gray-600"><strong>Title:</strong> {formData.title}</p>
                <p className="text-sm text-gray-600"><strong>Description:</strong> {formData.description || "No description"}</p>
              </div>

              <div className="rounded-lg border p-3">
                <h4 className="font-medium mb-2 text-sm">Details</h4>
                <p className="text-sm text-gray-600"><strong>URL:</strong> {formData.url || "No URL provided"}</p>
                <p className="text-sm text-gray-600"><strong>Steps:</strong> {formData.stepsToReproduce || "No steps provided"}</p>
              </div>

              <div className="rounded-lg border p-3">
                <h4 className="font-medium mb-2 text-sm">Classification</h4>
                <p className="text-sm text-gray-600"><strong>Severity:</strong> {formData.severity}</p>
                <p className="text-sm text-gray-600"><strong>Environment:</strong> {formData.environment}</p>
              </div>

              <div className="rounded-lg border p-3">
                <h4 className="font-medium mb-2 text-sm">Assignment</h4>
                <p className="text-sm text-gray-600"><strong>Status:</strong> {formData.status}</p>
                <p className="text-sm text-gray-600"><strong>Assignee:</strong> {formData.assignee}</p>
              </div>
            </div>

            <Alert className="border-blue-200 bg-blue-50">
              <IconAlertTriangle className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-800">
                <strong>Ready to save!</strong>
                <br />
                Click "Save Changes" to update the bug report with your modifications.
              </AlertDescription>
            </Alert>
          </div>
        )

      default:
        return null
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconBug className="size-5" />
            Edit Bug #{bug.id}
          </DialogTitle>
          <DialogDescription>
            Update the details of this bug report.
          </DialogDescription>
        </DialogHeader>
        
        {/* Step Indicator */}
        <div className="mb-6 flex items-center justify-between">
          {steps.map((step) => (
            <div key={step.id} className="relative flex flex-1 flex-col items-center">
              <div
                className={cn(
                  "flex h-8 w-8 items-center justify-center rounded-full text-sm font-semibold transition-colors duration-300",
                  currentStep > step.id
                    ? "bg-primary text-primary-foreground"
                    : currentStep === step.id
                      ? "bg-primary/90 text-primary-foreground"
                      : "bg-gray-200 text-gray-600"
                )}>
                {currentStep > step.id ? <IconCheck className="h-4 w-4" /> : step.id}
              </div>
              <div
                className={cn(
                  "mt-1 text-center text-xs font-medium",
                  currentStep >= step.id ? "text-gray-800" : "text-gray-500"
                )}>
                {step.title}
              </div>
              {step.id < steps.length && (
                <div
                    className={cn(
                      "absolute top-4 left-[calc(50%+16px)] h-0.5 w-[calc(100%-32px)] -translate-y-1/2 bg-gray-200 transition-colors duration-300",
                      currentStep > step.id && "bg-primary/60"
                    )}
                />
              )}
            </div>
          ))}
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {renderStepContent()}

          {/* Navigation */}
          <div className="flex justify-end space-x-2 pt-4 border-t">
            <Button 
              type="button"
              variant="outline" 
              onClick={handlePrevious} 
              disabled={currentStep === 1}
            >
              <IconChevronLeft className="h-4 w-4" />
              <span>Previous</span>
            </Button>

            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={loading}
            >
              Cancel
            </Button>
            
            {currentStep < 5 ? (
              <Button type="button" onClick={handleNext}>
                <span>Continue</span>
                <IconChevronRight className="h-4 w-4" />
              </Button>
            ) : (
              <Button type="submit" disabled={loading}>
                {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
                Save Changes
              </Button>
            )}
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
