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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { Badge } from "@/components/ui/badge"
import { IconUsers, IconLoader2, IconSearch } from "@tabler/icons-react"
import { toast } from "sonner"

interface AssignTasksFormProps {
  children: React.ReactNode
  onTasksAssigned?: () => void
}

interface Todo {
  id: number
  title: string
  status: string
  severity: string
  assignee: string
  due_date: string
}

interface TeamMember {
  id: string
  name: string
  email: string
}

export function AssignTasksForm({ children, onTasksAssigned }: AssignTasksFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [todos, setTodos] = useState<Todo[]>([])
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([])
  const [selectedTodos, setSelectedTodos] = useState<number[]>([])
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [bulkAssignee, setBulkAssignee] = useState("")
  const { user } = useAuth()

  // Load todos and team members when dialog opens
  useEffect(() => {
    if (open) {
      loadTodos()
      loadTeamMembers()
    }
  }, [open])

  const loadTodos = async () => {
    try {
      const { data, error } = await supabase
        .from('todos')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setTodos(data || [])
    } catch (error) {
      console.error("Error loading todos:", error)
      toast.error("Failed to load todos")
    }
  }

  const loadTeamMembers = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, email')
        .order('name')

      if (error) throw error
      setTeamMembers(data || [])
    } catch (error) {
      console.error("Error loading team members:", error)
      toast.error("Failed to load team members")
    }
  }

  const filteredTodos = todos.filter(todo => {
    const matchesSearch = todo.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          todo.assignee.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === "all" || todo.status === statusFilter
    return matchesSearch && matchesStatus
  })

  const handleTodoSelect = (todoId: number, checked: boolean) => {
    if (checked) {
      setSelectedTodos(prev => [...prev, todoId])
    } else {
      setSelectedTodos(prev => prev.filter(id => id !== todoId))
    }
  }

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedTodos(filteredTodos.map(todo => todo.id))
    } else {
      setSelectedTodos([])
    }
  }

  const handleBulkAssign = async () => {
    if (!bulkAssignee) {
      toast.error("Please select an assignee")
      return
    }

    if (selectedTodos.length === 0) {
      toast.error("Please select at least one todo")
      return
    }

    setLoading(true)
    try {
      const { error } = await supabase
        .from('todos')
        .update({ assignee: bulkAssignee })
        .in('id', selectedTodos)

      if (error) throw error

      toast.success(`${selectedTodos.length} tasks assigned to ${bulkAssignee}`)
      setOpen(false)
      setSelectedTodos([])
      setBulkAssignee("")
      
      if (onTasksAssigned) {
        onTasksAssigned()
      }
    } catch (error) {
      console.error("Error assigning tasks:", error)
      toast.error("Failed to assign tasks")
    } finally {
      setLoading(false)
    }
  }

  const getStatusBadgeVariant = (status: string) => {
    switch (status) {
      case "OPEN":
        return "secondary"
      case "IN_PROGRESS":
        return "default"
      case "READY_FOR_QA":
        return "destructive"
      case "DONE":
        return "outline"
      default:
        return "secondary"
    }
  }

  const getSeverityBadgeVariant = (severity: string) => {
    switch (severity) {
      case "CRITICAL":
        return "destructive"
      case "HIGH":
        return "default"
      case "MEDIUM":
        return "secondary"
      case "LOW":
        return "outline"
      default:
        return "secondary"
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
            <IconUsers className="size-5" />
            Assign Tasks
          </DialogTitle>
          <DialogDescription>
            Select tasks and assign them to team members.
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-6">
          {/* Filters and Search */}
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <div className="flex-1">
                <div className="relative">
                  <IconSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground size-4" />
                  <Input
                    placeholder="Search tasks or assignees..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
              </div>
              <div className="w-48">
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger>
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="OPEN">Open</SelectItem>
                    <SelectItem value="IN_PROGRESS">In Progress</SelectItem>
                    <SelectItem value="READY_FOR_QA">Ready for QA</SelectItem>
                    <SelectItem value="DONE">Done</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>

          {/* Bulk Assignment */}
          <div className="p-4 border rounded-lg bg-muted/50">
            <div className="flex items-center gap-4">
              <div className="flex-1">
                <Label htmlFor="bulk-assignee">Assign Selected Tasks To:</Label>
                <Select value={bulkAssignee} onValueChange={setBulkAssignee}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select team member" />
                  </SelectTrigger>
                  <SelectContent>
                    {teamMembers.map((member) => (
                      <SelectItem key={member.id} value={member.name}>
                        {member.name} ({member.email})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <Button
                onClick={handleBulkAssign}
                disabled={loading || selectedTodos.length === 0 || !bulkAssignee}
              >
                {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
                Assign {selectedTodos.length} Tasks
              </Button>
            </div>
          </div>

          {/* Task List */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="select-all"
                  checked={selectedTodos.length === filteredTodos.length && filteredTodos.length > 0}
                  onCheckedChange={handleSelectAll}
                />
                <Label htmlFor="select-all" className="text-sm font-medium">
                  Select All ({filteredTodos.length} tasks)
                </Label>
              </div>
              <Badge variant="outline">
                {selectedTodos.length} selected
              </Badge>
            </div>

            <div className="space-y-2 max-h-60 overflow-y-auto">
              {filteredTodos.map((todo) => (
                <div
                  key={todo.id}
                  className={`p-3 border rounded-lg transition-colors ${
                    selectedTodos.includes(todo.id) ? 'bg-primary/5 border-primary' : 'hover:bg-muted/50'
                  }`}
                >
                  <div className="flex items-start space-x-3">
                    <Checkbox
                      id={`todo-${todo.id}`}
                      checked={selectedTodos.includes(todo.id)}
                      onCheckedChange={(checked) => handleTodoSelect(todo.id, checked as boolean)}
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <h4 className="text-sm font-medium truncate">{todo.title}</h4>
                        <div className="flex items-center gap-2 ml-2">
                          <Badge variant={getStatusBadgeVariant(todo.status)} className="text-xs">
                            {todo.status}
                          </Badge>
                          <Badge variant={getSeverityBadgeVariant(todo.severity)} className="text-xs">
                            {todo.severity}
                          </Badge>
                        </div>
                      </div>
                      <div className="flex items-center gap-4 mt-1 text-xs text-muted-foreground">
                        <span>Current: {todo.assignee}</span>
                        <span>Due: {todo.due_date}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {filteredTodos.length === 0 && (
              <div className="text-center py-8 text-muted-foreground">
                No tasks found matching your criteria.
              </div>
            )}
          </div>

          <div className="flex justify-end space-x-2 pt-4 border-t">
            <Button
              variant="outline"
              onClick={() => setOpen(false)}
              disabled={loading}
            >
              Cancel
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
