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
import { Checkbox } from "@/components/ui/checkbox"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { IconSettings, IconLoader2, IconSearch } from "@tabler/icons-react"
import { toast } from "sonner"

interface BugItem {
  id: number
  title: string
  severity: string
  status: string
  environment: string
  reporter: string
  assignee: string
  created_at: string
  updated_at: string
}

interface BulkBugActionsFormProps {
  children: React.ReactNode
  onBugsUpdated?: () => void
}

export function BulkBugActionsForm({ children, onBugsUpdated }: BulkBugActionsFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [bugs, setBugs] = useState<BugItem[]>([])
  const [selectedBugs, setSelectedBugs] = useState<number[]>([])
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [severityFilter, setSeverityFilter] = useState("all")
  const [bulkAssignee, setBulkAssignee] = useState("")
  const [bulkStatus, setBulkStatus] = useState("")
  const [bulkSeverity, setBulkSeverity] = useState("")
  const { user, currentProject } = useAuth()

  // Load bugs when dialog opens
  useEffect(() => {
    if (open) {
      loadBugs()
    }
  }, [open, currentProject])

  const loadBugs = async () => {
    try {
      if (!currentProject) {
        setBugs([])
        return
      }

      const { data, error } = await supabase
        .from('bugs')
        .select('*')
        .eq('project_id', currentProject.id)
        .order('created_at', { ascending: false })

      if (error) throw error
      setBugs(data || [])
    } catch (error) {
      console.error("Error loading bugs:", error)
      toast.error("Failed to load bugs")
    }
  }

  const filteredBugs = bugs.filter(bug => {
    const matchesSearch = bug.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          bug.reporter.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          bug.assignee.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === "all" || bug.status === statusFilter
    const matchesSeverity = severityFilter === "all" || bug.severity === severityFilter
    return matchesSearch && matchesStatus && matchesSeverity
  })

  const handleBugSelect = (bugId: number, checked: boolean) => {
    if (checked) {
      setSelectedBugs(prev => [...prev, bugId])
    } else {
      setSelectedBugs(prev => prev.filter(id => id !== bugId))
    }
  }

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedBugs(filteredBugs.map(bug => bug.id))
    } else {
      setSelectedBugs([])
    }
  }

  const handleBulkUpdate = async () => {
    if (selectedBugs.length === 0) {
      toast.error("Please select at least one bug")
      return
    }

    if (!bulkAssignee && !bulkStatus && !bulkSeverity) {
      toast.error("Please specify at least one field to update")
      return
    }

    setLoading(true)
    try {
      const updateData: any = {}
      if (bulkAssignee) updateData.assignee = bulkAssignee
      if (bulkStatus) updateData.status = bulkStatus
      if (bulkSeverity) updateData.severity = bulkSeverity

      const { error } = await supabase
        .from('bugs')
        .update(updateData)
        .in('id', selectedBugs)

      if (error) throw error

      toast.success(`${selectedBugs.length} bugs updated successfully!`)
      setOpen(false)
      setSelectedBugs([])
      setBulkAssignee("")
      setBulkStatus("")
      setBulkSeverity("")
      
      if (onBugsUpdated) {
        onBugsUpdated()
      }
    } catch (error) {
      console.error("Error updating bugs:", error)
      toast.error("Failed to update bugs")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[800px] max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconSettings className="size-5" />
            Bulk Bug Actions
          </DialogTitle>
          <DialogDescription>
            Select bugs and apply bulk actions like assignment, status changes, and severity updates.
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-6">
          {/* Filters */}
          <div className="space-y-4 p-4 border rounded-lg bg-muted/50">
            <h3 className="text-sm font-medium">Filters</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="search">Search</Label>
                <div className="relative">
                  <IconSearch className="absolute left-3 top-3 size-4 text-muted-foreground" />
                  <Input
                    id="search"
                    placeholder="Search bugs..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="status-filter">Status</Label>
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="Open">Open</SelectItem>
                    <SelectItem value="In Progress">In Progress</SelectItem>
                    <SelectItem value="Ready for QA">Ready for QA</SelectItem>
                    <SelectItem value="Closed">Closed</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="severity-filter">Severity</Label>
                <Select value={severityFilter} onValueChange={setSeverityFilter}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Severity</SelectItem>
                    <SelectItem value="CRITICAL">Critical</SelectItem>
                    <SelectItem value="HIGH">High</SelectItem>
                    <SelectItem value="MEDIUM">Medium</SelectItem>
                    <SelectItem value="LOW">Low</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>

          {/* Bulk Actions */}
          <div className="space-y-4 p-4 border rounded-lg bg-muted/50">
            <h3 className="text-sm font-medium">Bulk Actions</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="bulk-assignee">Assign To</Label>
                <Input
                  id="bulk-assignee"
                  placeholder="Team member name"
                  value={bulkAssignee}
                  onChange={(e) => setBulkAssignee(e.target.value)}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="bulk-status">Change Status</Label>
                <Select value={bulkStatus} onValueChange={setBulkStatus}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">No change</SelectItem>
                    <SelectItem value="Open">Open</SelectItem>
                    <SelectItem value="In Progress">In Progress</SelectItem>
                    <SelectItem value="Ready for QA">Ready for QA</SelectItem>
                    <SelectItem value="Closed">Closed</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="bulk-severity">Change Severity</Label>
                <Select value={bulkSeverity} onValueChange={setBulkSeverity}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select severity" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">No change</SelectItem>
                    <SelectItem value="CRITICAL">Critical</SelectItem>
                    <SelectItem value="HIGH">High</SelectItem>
                    <SelectItem value="MEDIUM">Medium</SelectItem>
                    <SelectItem value="LOW">Low</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>

          {/* Bug List */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-medium">
                Bugs ({filteredBugs.length}) - {selectedBugs.length} selected
              </h3>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="select-all"
                  checked={selectedBugs.length === filteredBugs.length && filteredBugs.length > 0}
                  onCheckedChange={handleSelectAll}
                />
                <Label htmlFor="select-all" className="text-sm">
                  Select All
                </Label>
              </div>
            </div>

            <div className="space-y-2 max-h-60 overflow-y-auto">
              {filteredBugs.map((bug) => (
                <div key={bug.id} className="flex items-center space-x-3 p-3 border rounded-lg">
                  <Checkbox
                    id={`bug-${bug.id}`}
                    checked={selectedBugs.includes(bug.id)}
                    onCheckedChange={(checked) => handleBugSelect(bug.id, checked as boolean)}
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium truncate">{bug.title}</span>
                      <span className="text-xs text-muted-foreground">#{bug.id}</span>
                    </div>
                    <div className="text-sm text-muted-foreground">
                      {bug.reporter} • {bug.assignee} • {bug.status}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="flex justify-end space-x-2 pt-4 border-t">
            <Button
              type="button"
              variant="outline"
              onClick={() => setOpen(false)}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button
              onClick={handleBulkUpdate}
              disabled={loading || selectedBugs.length === 0}
            >
              {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
              Update {selectedBugs.length} Bugs
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
