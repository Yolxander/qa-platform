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
import { IconEdit, IconLoader2, IconUsers } from "@tabler/icons-react"
import { toast } from "sonner"

interface EditTeamFormProps {
  children: React.ReactNode
  onTeamUpdated?: () => void
}

interface Team {
  id: string
  name: string
  description?: string
}

export function EditTeamForm({ children, onTeamUpdated }: EditTeamFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [team, setTeam] = useState<Team | null>(null)
  const [teamLoading, setTeamLoading] = useState(false)
  const { user, currentProject } = useAuth()

  const [formData, setFormData] = useState({
    name: "",
    description: ""
  })

  // Load team data when dialog opens
  useEffect(() => {
    if (open && currentProject) {
      loadTeam()
    }
  }, [open, currentProject])

  const loadTeam = async () => {
    try {
      setTeamLoading(true)
      
      if (!supabase || !currentProject) {
        setTeam(null)
        return
      }

      const { data, error } = await supabase
        .from('teams')
        .select('id, name, description')
        .eq('project_id', currentProject.id)
        .single()

      if (error) {
        if (error.code === 'PGRST116') {
          // No team found, create default values
          setTeam({
            id: '',
            name: currentProject.name + ' Team',
            description: 'Default team for ' + currentProject.name
          })
          setFormData({
            name: currentProject.name + ' Team',
            description: 'Default team for ' + currentProject.name
          })
        } else {
          throw error
        }
      } else {
        setTeam(data)
        setFormData({
          name: data.name,
          description: data.description || ''
        })
      }
    } catch (error) {
      console.error("Error loading team:", error)
      setTeam(null)
    } finally {
      setTeamLoading(false)
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
      if (team?.id) {
        // Update existing team
        const { error } = await supabase
          .from('teams')
          .update({
            name: formData.name,
            description: formData.description || null
          })
          .eq('id', team.id)

        if (error) throw error
      } else {
        // Create new team using the database function
        const { data: result, error } = await supabase
          .rpc('create_team_with_owner', {
            team_name: formData.name,
            team_description: formData.description || null,
            project_id_param: currentProject.id
          })

        if (error) throw error

        if (!result?.success) {
          throw new Error(result?.message || 'Failed to create team')
        }
      }

      toast.success("Team updated successfully!")
      setOpen(false)
      
      if (onTeamUpdated) {
        onTeamUpdated()
      }
    } catch (error) {
      console.error("Error updating team:", error)
      toast.error("Failed to update team. Please check your Supabase configuration.")
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
            <IconEdit className="size-5" />
            Edit Team
          </DialogTitle>
          <DialogDescription>
            Update your team information and settings.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          {teamLoading ? (
            <div className="flex items-center justify-center py-8">
              <div className="text-muted-foreground">Loading team...</div>
            </div>
          ) : (
            <>
              <div className="space-y-2">
                <Label htmlFor="name">Team Name *</Label>
                <Input
                  id="name"
                  placeholder="Enter team name"
                  value={formData.name}
                  onChange={(e) => handleInputChange("name", e.target.value)}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  placeholder="Enter team description (optional)"
                  value={formData.description}
                  onChange={(e) => handleInputChange("description", e.target.value)}
                  rows={3}
                />
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
                  {team?.id ? 'Update Team' : 'Create Team'}
                </Button>
              </div>
            </>
          )}
        </form>
      </DialogContent>
    </Dialog>
  )
}
