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
import { IconPlus, IconLoader2, IconX } from "@tabler/icons-react"
import { toast } from "sonner"

interface QuickAddFormProps {
  children: React.ReactNode
  onTodosCreated?: () => void
}

interface TodoItem {
  title: string
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW"
  environment: "Prod" | "Stage" | "Dev"
  assignee: string
  due_date: string
}

export function QuickAddForm({ children, onTodosCreated }: QuickAddFormProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const { user, currentProject } = useAuth()

  const [todos, setTodos] = useState<TodoItem[]>([
    {
      title: "",
      severity: "MEDIUM",
      environment: "Dev",
      assignee: "",
      due_date: "Today"
    }
  ])

  const [bulkSettings, setBulkSettings] = useState({
    severity: "MEDIUM" as "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
    environment: "Dev" as "Prod" | "Stage" | "Dev",
    assignee: "",
    due_date: "Today"
  })

  const addTodo = () => {
    setTodos(prev => [...prev, {
      title: "",
      severity: bulkSettings.severity,
      environment: bulkSettings.environment,
      assignee: bulkSettings.assignee,
      due_date: bulkSettings.due_date
    }])
  }

  const removeTodo = (index: number) => {
    if (todos.length > 1) {
      setTodos(prev => prev.filter((_, i) => i !== index))
    }
  }

  const updateTodo = (index: number, field: keyof TodoItem, value: string) => {
    setTodos(prev => prev.map((todo, i) => 
      i === index ? { ...todo, [field]: value } : todo
    ))
  }

  const applyBulkSettings = () => {
    setTodos(prev => prev.map(todo => ({
      ...todo,
      severity: bulkSettings.severity,
      environment: bulkSettings.environment,
      assignee: bulkSettings.assignee || todo.assignee,
      due_date: bulkSettings.due_date
    })))
    toast.success("Bulk settings applied to all todos")
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) {
      toast.error("You must be logged in to create todos")
      return
    }

    const validTodos = todos.filter(todo => todo.title.trim())
    if (validTodos.length === 0) {
      toast.error("Please add at least one todo with a title")
      return
    }

    setLoading(true)
    try {
      const todosToInsert = validTodos.map(todo => ({
        title: todo.title,
        issue_link: null,
        status: 'OPEN',
        severity: todo.severity,
        environment: todo.environment,
        assignee: todo.assignee,
        due_date: todo.due_date,
        quick_action: "Start",
        user_id: user.id,
        project_id: currentProject?.id || null
      }))

      const { data: insertedTodos, error } = await supabase
        .from('todos')
        .insert(todosToInsert)
        .select()

      if (error) {
        throw error
      }

      // Auto-populate issue links with the created todo IDs
      if (insertedTodos) {
        const updatePromises = insertedTodos.map(todo => 
          supabase
            .from('todos')
            .update({ issue_link: `#${todo.id}` })
            .eq('id', todo.id)
        )
        await Promise.all(updatePromises)
      }

      toast.success(`${validTodos.length} todos created successfully!`)
      setOpen(false)
      setTodos([{
        title: "",
        severity: "MEDIUM",
        environment: "Dev",
        assignee: "",
        due_date: "Today"
      }])
      
      if (onTodosCreated) {
        onTodosCreated()
      }
    } catch (error) {
      console.error("Error creating todos:", error)
      toast.error("Failed to create todos")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[700px] max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconPlus className="size-5" />
            Quick Add Multiple Tasks
          </DialogTitle>
          <DialogDescription>
            Add multiple tasks quickly with bulk settings.
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Bulk Settings */}
          <div className="space-y-4 p-4 border rounded-lg bg-muted/50">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-medium">Bulk Settings</h3>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={applyBulkSettings}
              >
                Apply to All
              </Button>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="bulk-severity">Severity</Label>
                <Select
                  value={bulkSettings.severity}
                  onValueChange={(value) => setBulkSettings(prev => ({ ...prev, severity: value as any }))}
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
                <Label htmlFor="bulk-environment">Environment</Label>
                <Select
                  value={bulkSettings.environment}
                  onValueChange={(value) => setBulkSettings(prev => ({ ...prev, environment: value as any }))}
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
                <Label htmlFor="bulk-assignee">Assignee</Label>
                <Input
                  id="bulk-assignee"
                  placeholder="Team member name"
                  value={bulkSettings.assignee}
                  onChange={(e) => setBulkSettings(prev => ({ ...prev, assignee: e.target.value }))}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="bulk-due-date">Due Date</Label>
                <Select
                  value={bulkSettings.due_date}
                  onValueChange={(value) => setBulkSettings(prev => ({ ...prev, due_date: value }))}
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
          </div>

          {/* Todo Items */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-medium">Tasks ({todos.length})</h3>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={addTodo}
              >
                <IconPlus className="size-4 mr-2" />
                Add Task
              </Button>
            </div>

            <div className="space-y-3 max-h-60 overflow-y-auto">
              {todos.map((todo, index) => (
                <div key={index} className="p-4 border rounded-lg space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Task {index + 1}</span>
                    {todos.length > 1 && (
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => removeTodo(index)}
                      >
                        <IconX className="size-4" />
                      </Button>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor={`title-${index}`}>Title *</Label>
                    <Input
                      id={`title-${index}`}
                      placeholder="Enter task title"
                      value={todo.title}
                      onChange={(e) => updateTodo(index, "title", e.target.value)}
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-2">
                      <Label htmlFor={`severity-${index}`}>Severity</Label>
                      <Select
                        value={todo.severity}
                        onValueChange={(value) => updateTodo(index, "severity", value)}
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
                      <Label htmlFor={`environment-${index}`}>Environment</Label>
                      <Select
                        value={todo.environment}
                        onValueChange={(value) => updateTodo(index, "environment", value)}
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

                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-2">
                      <Label htmlFor={`assignee-${index}`}>Assignee</Label>
                      <Input
                        id={`assignee-${index}`}
                        placeholder="Team member name"
                        value={todo.assignee}
                        onChange={(e) => updateTodo(index, "assignee", e.target.value)}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor={`due-date-${index}`}>Due Date</Label>
                      <Select
                        value={todo.due_date}
                        onValueChange={(value) => updateTodo(index, "due_date", value)}
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
            <Button type="submit" disabled={loading}>
              {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
              Create {todos.filter(t => t.title.trim()).length} Todos
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
