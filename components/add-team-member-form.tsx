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
import { IconPlus, IconLoader2, IconUser } from "@tabler/icons-react"
import { toast } from "sonner"

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

export function AddTeamMemberForm({ children, onTeamUpdated }: AddTeamMemberFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [profilesLoading, setProfilesLoading] = useState(false)
  const { user, currentProject } = useAuth()

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    role: "developer" as "tester" | "developer" | "guest"
  })

  // Load available profiles when dialog opens
  useEffect(() => {
    if (open) {
      loadAvailableProfiles()
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

    setLoading(true)
    try {
      // Use the invitation function to create team invitation
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

      toast.success("Team invitation sent successfully! The user will be added to the team when they register.")
      setOpen(false)
      setFormData({
        name: "",
        email: "",
        role: "developer"
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

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconPlus className="size-5" />
            Add Team Member
          </DialogTitle>
          <DialogDescription>
            Send an invitation to add a new member to your project team. They'll be added when they register.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
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

          {profiles.length > 0 && (
            <div className="space-y-2">
              <Label>Available Users</Label>
              <div className="max-h-32 overflow-y-auto space-y-1">
                {profiles.map((profile) => (
                  <div
                    key={profile.id}
                    className="flex items-center gap-2 p-2 border rounded cursor-pointer hover:bg-muted"
                    onClick={() => handleInputChange("email", profile.email)}
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
              Send Invitation
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
