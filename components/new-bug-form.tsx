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
import { IconBug, IconLoader2, IconChevronLeft, IconChevronRight, IconCheck, IconAlertTriangle } from "@tabler/icons-react"
import { toast } from "sonner"
import { cn } from "@/lib/utils"
import { Alert, AlertDescription } from "@/components/ui/alert"

interface NewBugFormProps {
  children: React.ReactNode
  onBugCreated?: () => void
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
    description: "Assignee information"
  },
  {
    id: 5,
    title: "Review",
    description: "Review and submit"
  }
]

interface TeamMember {
  id: string
  name: string
  email: string
  role: string
}

export function NewBugForm({ children, onBugCreated }: NewBugFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [currentStep, setCurrentStep] = useState(1)
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([])
  const [teamMembersLoading, setTeamMembersLoading] = useState(false)
  const { user, currentProject } = useAuth()

  const [formData, setFormData] = useState({
    title: "",
    description: "",
    severity: "MEDIUM" as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
    environment: "Dev" as "Prod" | "Stage" | "Dev",
    url: "",
    stepsToReproduce: "",
    assignee: null as string | null
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
          status: 'Open', // Set default status for new bugs
          environment: formData.environment,
          url: formData.url,
          steps_to_reproduce: formData.stepsToReproduce,
          reporter: user.email || user.user_metadata?.name || "Unknown",
          assignee: formData.assignee,
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
        url: "",
        stepsToReproduce: "",
        assignee: null
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

  const handleInputChange = (field: string, value: string | null) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
  }

  const getAssigneeName = () => {
    if (!formData.assignee) return "Unassigned"
    const member = teamMembers.find(m => m.id === formData.assignee)
    return member ? `${member.name} (${member.email})` : "Unknown"
  }

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
      
      if (!supabase || !currentProject || !user) {
        setTeamMembers([])
        return
      }

      let allMembers: TeamMember[] = []

      // For owned projects: get teams directly from the project
      if (!currentProject.isInvited) {
        const { data: teams, error: teamsError } = await supabase
          .from('teams')
          .select('id')
          .eq('project_id', currentProject.id)

        if (teamsError) throw teamsError

        if (teams && teams.length > 0) {
          // Get team members for each team using the database function
          const teamsWithMembers = await Promise.all(
            teams.map(async (team) => {
              const { data: membersData, error: membersError } = await supabase
                .rpc('get_team_members', { team_uuid: team.id })

              if (membersError) {
                console.error('Error fetching team members:', membersError)
                return []
              }

              return (membersData || []).map(member => ({
                id: member.member_id,
                name: member.member_name || 'Unknown',
                email: member.member_email,
                role: member.role
              }))
            })
          )

          allMembers = teamsWithMembers.flat()
        }
      } else {
        // For invited projects: use the get_member_teams function
        const { data: memberTeamsData, error: memberTeamsError } = await supabase
          .rpc('get_member_teams', { user_profile_id: user.id })

        if (memberTeamsError) {
          console.error('Error fetching member teams:', memberTeamsError)
          setTeamMembers([])
          return
        }

        if (memberTeamsData && memberTeamsData.length > 0) {
          // Filter teams for the current project
          const projectTeams = memberTeamsData.filter(team => 
            team.project_id === currentProject.id
          )

          // Get team members for each team in the current project
          const teamsWithMembers = await Promise.all(
            projectTeams.map(async (teamData) => {
              const { data: membersData, error: membersError } = await supabase
                .rpc('get_team_members', { team_uuid: teamData.team_id })

              if (membersError) {
                console.error('Error fetching team members:', membersError)
                return []
              }

              return (membersData || []).map(member => ({
                id: member.member_id,
                name: member.member_name || 'Unknown',
                email: member.member_email,
                role: member.role
              }))
            })
          )

          allMembers = teamsWithMembers.flat()
        }
      }

      // Deduplicate members by ID to avoid showing the same person multiple times
      const uniqueMembers = allMembers.reduce((acc, member) => {
        const existingMember = acc.find(m => m.id === member.id)
        if (!existingMember) {
          acc.push(member)
        }
        return acc
      }, [] as TeamMember[])

      setTeamMembers(uniqueMembers)
    } catch (error) {
      console.error("Error loading team members:", error)
      setTeamMembers([])
    } finally {
      setTeamMembersLoading(false)
    }
  }

  // Reset step when modal opens and load team members
  React.useEffect(() => {
    if (open) {
      setCurrentStep(1)
      setFormData({
        title: "",
        description: "",
        severity: "MEDIUM",
        environment: "Dev",
        url: "",
        stepsToReproduce: "",
        assignee: null
      })
      loadTeamMembers()
    }
  }, [open, currentProject])

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
            <div className="space-y-2">
              <Label htmlFor="assignee">Assignee (Optional)</Label>
              <Select
                value={formData.assignee || ""}
                onValueChange={(value) => handleInputChange("assignee", value === "unassigned" ? null : value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a team member or leave unassigned" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="unassigned">Unassigned</SelectItem>
                  {teamMembersLoading ? (
                    <SelectItem value="loading" disabled>
                      Loading team members...
                    </SelectItem>
                  ) : teamMembers.length > 0 ? (
                    teamMembers.map((member) => (
                      <SelectItem key={member.id} value={member.id}>
                        {member.name} ({member.email})
                      </SelectItem>
                    ))
                  ) : (
                    <SelectItem value="no-members" disabled>
                      No team members found
                    </SelectItem>
                  )}
                </SelectContent>
              </Select>
              {teamMembers.length > 0 && (
                <p className="text-sm text-muted-foreground">
                  {teamMembers.length} team member{teamMembers.length !== 1 ? 's' : ''} available
                </p>
              )}
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
                <p className="text-sm text-gray-600"><strong>Assignee:</strong> {getAssigneeName()}</p>
              </div>
            </div>

            <Alert className="border-blue-200 bg-blue-50">
              <IconAlertTriangle className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-800">
                <strong>Ready to submit!</strong>
                <br />
                Click "Report Bug" to submit your bug report.
              </AlertDescription>
            </Alert>
          </div>
        )

      default:
        return null
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <div onClick={() => setOpen(true)}>
          {children}
        </div>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconBug className="size-5" />
            Report New Bug
          </DialogTitle>
          <DialogDescription>
            Report a bug or issue for the current project.
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
              onClick={() => setOpen(false)}
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
                Report Bug
              </Button>
            )}
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
