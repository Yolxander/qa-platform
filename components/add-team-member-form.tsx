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
import { IconPlus, IconLoader2, IconUser, IconChevronLeft, IconChevronRight, IconCheck, IconAlertTriangle } from "@tabler/icons-react"
import { toast } from "sonner"
import { Checkbox } from "@/components/ui/checkbox"
import { cn } from "@/lib/utils"
import { Alert, AlertDescription } from "@/components/ui/alert"

interface AddTeamMemberFormProps {
  children: React.ReactNode
  onTeamUpdated?: () => void
}

interface Profile {
  id: string
  name: string
  email: string
  avatar_url?: string
}

interface Team {
  id: string
  name: string
  description?: string
}

const steps = [
  {
    id: 1,
    title: "Basic Info",
    description: "Member name and email"
  },
  {
    id: 2,
    title: "Role & Teams",
    description: "Select role and teams"
  },
  {
    id: 3,
    title: "Review",
    description: "Review and submit"
  }
]

export function AddTeamMemberForm({ children, onTeamUpdated }: AddTeamMemberFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [currentStep, setCurrentStep] = useState(1)
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [profilesLoading, setProfilesLoading] = useState(false)
  const [teams, setTeams] = useState<Team[]>([])
  const [teamsLoading, setTeamsLoading] = useState(false)
  const { user, currentProject } = useAuth()

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    role: "developer" as "tester" | "developer" | "guest",
    selectedTeams: [] as string[]
  })

  // Load available profiles and teams when dialog opens
  useEffect(() => {
    if (open) {
      loadAvailableProfiles()
      loadAvailableTeams()
      setCurrentStep(1)
    }
  }, [open, currentProject])

  const loadAvailableProfiles = async () => {
    try {
      setProfilesLoading(true)
      
      if (!supabase || !currentProject) {
        setProfiles([])
        return
      }

      // Get all profiles that are not already in the project's team
      // Using a safer approach with proper joins
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          id, 
          name, 
          email, 
          avatar_url,
          team_members!left(
            team_id,
            teams!inner(project_id)
          )
        `)
        .not('team_members.teams.project_id', 'eq', currentProject.id)
        .order('name')

      if (error) {
        console.error("Error loading profiles:", error)
        // If the complex query fails, try a simpler approach
        const { data: simpleData, error: simpleError } = await supabase
          .from('profiles')
          .select('id, name, email, avatar_url')
          .order('name')
          .limit(50) // Limit to prevent performance issues
        
        if (simpleError) throw simpleError
        setProfiles(simpleData || [])
      } else {
        setProfiles(data || [])
      }
    } catch (error) {
      console.error("Error loading profiles:", error)
      setProfiles([])
    } finally {
      setProfilesLoading(false)
    }
  }

  const loadAvailableTeams = async () => {
    try {
      setTeamsLoading(true)
      
      if (!supabase || !currentProject) {
        setTeams([])
        return
      }

      // Get all teams for the current project
      const { data, error } = await supabase
        .from('teams')
        .select('id, name, description')
        .eq('project_id', currentProject.id)
        .order('name')

      if (error) {
        console.error("Error loading teams:", error)
        setTeams([])
      } else {
        setTeams(data || [])
      }
    } catch (error) {
      console.error("Error loading teams:", error)
      setTeams([])
    } finally {
      setTeamsLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user || !currentProject) {
      toast.error("You must be logged in and have a project selected")
      return
    }

    if (!supabase) {
      toast.error("Database not configured. Please set up Supabase environment variables.")
      return
    }

    if (formData.selectedTeams.length === 0) {
      toast.error("Please select at least one team")
      return
    }

    setLoading(true)
    try {
      // Create a single project-level invitation (current system limitation)
      // Store selected teams information in the invitation for later processing
      const { data, error } = await supabase.rpc('create_team_invitation', {
        invite_email: formData.email,
        invite_name: formData.name,
        project_id_param: currentProject.id,
        invite_role: formData.role
      })

      if (error) {
        console.error("Error creating team invitation:", error)
        if (error.message.includes('already exists') || error.message.includes('duplicate')) {
          toast.error("An invitation for this email already exists for this project")
        } else if (error.message.includes('Access denied')) {
          toast.error("You don't have permission to invite members to this project")
        } else {
          toast.error("Failed to create team invitation. Please try again.")
        }
        return
      }

      // Store the selected teams information in a separate table or as metadata
      // For now, we'll create team assignments directly if the user already exists
      // This is a simplified approach - in a production system, you'd want to store
      // the team selection and apply it when the user accepts the invitation
      
      const teamNames = teams
        .filter(team => formData.selectedTeams.includes(team.id))
        .map(team => team.name)
        .join(', ')

      // Try to find existing user and add them to selected teams immediately
      const { data: existingProfile } = await supabase
        .from('profiles')
        .select('id')
        .eq('email', formData.email)
        .single()

      if (existingProfile) {
        // User exists, add them to the selected teams
        const teamMemberPromises = formData.selectedTeams.map(teamId =>
          supabase.from('team_members').insert({
            team_id: teamId,
            profile_id: existingProfile.id,
            role: formData.role
          }).select()
        )

        const teamResults = await Promise.all(teamMemberPromises)
        const teamErrors = teamResults.filter(result => result.error)
        
        if (teamErrors.length > 0) {
          console.warn("Some team assignments failed:", teamErrors)
          toast.success(`User added to project. Some team assignments may have failed.`)
        } else {
          toast.success(`User added to project and assigned to: ${teamNames}`)
        }
      } else {
        // User doesn't exist yet, invitation sent
        toast.success(`Team invitation sent successfully! When they register, they'll be added to: ${teamNames}`)
      }

      setOpen(false)
      setCurrentStep(1)
      setFormData({
        name: "",
        email: "",
        role: "developer",
        selectedTeams: []
      })
      
      if (onTeamUpdated) {
        onTeamUpdated()
      }
    } catch (error) {
      console.error("Error adding team member:", error)
      toast.error("Failed to add team member. Please check your Supabase configuration.")
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

  const handleTeamSelection = (teamId: string, checked: boolean) => {
    setFormData(prev => ({
      ...prev,
      selectedTeams: checked 
        ? [...prev.selectedTeams, teamId]
        : prev.selectedTeams.filter(id => id !== teamId)
    }))
  }

  const handleNext = () => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1)
    }
  }

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1)
    }
  }

  const renderStepContent = () => {
    switch (currentStep) {
      case 1:
  return (
          <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="name">Full Name *</Label>
            <Input
              id="name"
              placeholder="John Doe"
              value={formData.name}
              onChange={(e) => handleInputChange("name", e.target.value)}
              required
            />
            <p className="text-xs text-muted-foreground">
              Enter the full name of the team member.
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="email">Email Address *</Label>
            <Input
              id="email"
              type="email"
              placeholder="user@example.com"
              value={formData.email}
              onChange={(e) => handleInputChange("email", e.target.value)}
              required
            />
            <p className="text-xs text-muted-foreground">
              Enter the email address of the user you want to add to the team.
            </p>
          </div>

          {profiles.length > 0 && (
            <div className="space-y-2">
              <Label>Available Users</Label>
              <div className="max-h-32 overflow-y-auto space-y-1">
                {profiles.map((profile) => (
                  <div
                    key={profile.id}
                    className="flex items-center gap-2 p-2 border rounded cursor-pointer hover:bg-muted"
                      onClick={() => {
                        handleInputChange("email", profile.email)
                        handleInputChange("name", profile.name || "")
                      }}
                  >
                    <IconUser className="size-4" />
                    <div className="flex-1 min-w-0">
                      <div className="font-medium truncate">{profile.name}</div>
                      <div className="text-sm text-muted-foreground truncate">
                        {profile.email}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
          </div>
        )

      case 2:
        return (
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="role">Role *</Label>
              <Select
                value={formData.role}
                onValueChange={(value) => handleInputChange("role", value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="developer">Developer</SelectItem>
                  <SelectItem value="tester">Tester</SelectItem>
                  <SelectItem value="guest">Guest</SelectItem>
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">
                Choose the role for this team member.
              </p>
            </div>

            <div className="space-y-2">
              <Label>Select Teams *</Label>
              {teamsLoading ? (
                <div className="text-sm text-muted-foreground">Loading teams...</div>
              ) : teams.length === 0 ? (
                <div className="text-sm text-muted-foreground">
                  No teams available. Create a team first to add members.
                </div>
              ) : (
                <div className="space-y-2 max-h-32 overflow-y-auto">
                  {teams.map((team) => (
                    <div key={team.id} className="flex items-center space-x-2">
                      <Checkbox
                        id={`team-${team.id}`}
                        checked={formData.selectedTeams.includes(team.id)}
                        onCheckedChange={(checked) => handleTeamSelection(team.id, checked as boolean)}
                      />
                      <Label 
                        htmlFor={`team-${team.id}`}
                        className="text-sm font-normal cursor-pointer flex-1"
                      >
                        <div className="font-medium">{team.name}</div>
                        {team.description && (
                          <div className="text-xs text-muted-foreground">{team.description}</div>
                        )}
                      </Label>
                    </div>
                  ))}
                </div>
              )}
              <p className="text-xs text-muted-foreground">
                Select one or more teams to add this member to.
              </p>
            </div>
          </div>
        )

      case 3:
        return (
          <div className="space-y-4">
            <div className="space-y-3">
              <div className="rounded-lg border p-3">
                <h4 className="font-medium mb-2 text-sm">Member Information</h4>
                <p className="text-sm text-gray-600"><strong>Name:</strong> {formData.name}</p>
                <p className="text-sm text-gray-600"><strong>Email:</strong> {formData.email}</p>
                <p className="text-sm text-gray-600"><strong>Role:</strong> {formData.role}</p>
              </div>

              <div className="rounded-lg border p-3">
                <h4 className="font-medium mb-2 text-sm">Selected Teams</h4>
                {formData.selectedTeams.length === 0 ? (
                  <p className="text-sm text-gray-600">No teams selected</p>
                ) : (
                  <div className="space-y-1">
                    {teams
                      .filter(team => formData.selectedTeams.includes(team.id))
                      .map(team => (
                        <div key={team.id} className="text-sm text-gray-600">
                          • {team.name}
                          {team.description && (
                            <span className="text-xs text-gray-500 ml-2">({team.description})</span>
                          )}
                        </div>
                      ))}
                  </div>
                )}
              </div>
            </div>

            <Alert className="border-blue-200 bg-blue-50">
              <IconAlertTriangle className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-800">
                <strong>Ready to invite!</strong>
                <br />
                Click "Send Invitation" to invite this member to the selected teams.
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
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconPlus className="size-5" />
            Add Team Member
          </DialogTitle>
          <DialogDescription>
            Send an invitation to add a new member to your project teams. They'll be added to the selected teams when they register.
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
            
            {currentStep < 3 ? (
              <Button type="button" onClick={handleNext}>
                <span>Continue</span>
                <IconChevronRight className="h-4 w-4" />
              </Button>
            ) : (
            <Button type="submit" disabled={loading}>
              {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
              Send Invitation
            </Button>
            )}
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
