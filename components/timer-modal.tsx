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
import { Textarea } from "@/components/ui/textarea"
import { IconClock, IconPlayerStop, IconX } from "@tabler/icons-react"
import { toast } from "sonner"

interface TimerModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  todo: {
    id: number
    title: string
    status: string
  }
  onTodoUpdated?: () => void
}

export function TimerModal({ open, onOpenChange, todo, onTodoUpdated }: TimerModalProps) {
  const [timer, setTimer] = useState(0)
  const [isRunning, setIsRunning] = useState(false)
  const [notes, setNotes] = useState("")
  const [loading, setLoading] = useState(false)
  const { currentProject } = useAuth()

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null
    if (isRunning) {
      interval = setInterval(() => {
        setTimer((timer) => timer + 1)
      }, 1000)
    } else if (!isRunning && interval) {
      clearInterval(interval)
    }
    return () => {
      if (interval) clearInterval(interval)
    }
  }, [isRunning])

  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  const handleStart = () => {
    setIsRunning(true)
  }

  const handleStop = async () => {
    setIsRunning(false)
    await saveTimeEntry()
  }

  const handleCancel = () => {
    setIsRunning(false)
    setTimer(0)
    setNotes("")
    onOpenChange(false)
  }

  const saveTimeEntry = async () => {
    if (!supabase || !currentProject) {
      toast.error("Database not configured")
      return
    }

    setLoading(true)
    try {
      // Save time entry to database
      const { error } = await supabase
        .from('todo_time_entries')
        .insert({
          todo_id: todo.id,
          project_id: currentProject.id,
          duration_seconds: timer,
          notes: notes.trim() || null,
          created_at: new Date().toISOString()
        })

      if (error) throw error

      // Update todo status to IN_PROGRESS if it was OPEN
      if (todo.status === 'OPEN') {
        await supabase
          .from('todos')
          .update({ status: 'IN_PROGRESS' })
          .eq('id', todo.id)
      }

      toast.success(`Time logged: ${formatTime(timer)}`)
      
      if (onTodoUpdated) {
        onTodoUpdated()
      }
      
      onOpenChange(false)
      setTimer(0)
      setNotes("")
    } catch (error) {
      console.error("Error saving time entry:", error)
      toast.error("Failed to save time entry")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconClock className="size-5" />
            Timer - {todo.title}
          </DialogTitle>
          <DialogDescription>
            Track time spent on this task and add notes about your progress.
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-6">
          {/* Timer Display */}
          <div className="text-center">
            <div className="text-4xl font-mono font-bold text-primary mb-2">
              {formatTime(timer)}
            </div>
            <div className="text-sm text-muted-foreground">
              {isRunning ? "Timer is running..." : "Timer is stopped"}
            </div>
          </div>

          {/* Timer Controls */}
          <div className="flex justify-center gap-4">
            {!isRunning ? (
              <Button onClick={handleStart} className="gap-2">
                <IconClock className="size-4" />
                Start Timer
              </Button>
            ) : (
              <Button onClick={handleStop} variant="destructive" className="gap-2">
                <IconPlayerStop className="size-4" />
                Stop Timer
              </Button>
            )}
          </div>

          {/* Notes Input */}
          <div className="space-y-2">
            <Label htmlFor="notes">Notes (Optional)</Label>
            <Textarea
              id="notes"
              placeholder="Add notes about what you worked on..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
            />
          </div>

          {/* Action Buttons */}
          <div className="flex justify-end gap-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={handleCancel}
              disabled={loading}
            >
              <IconX className="mr-2 size-4" />
              Cancel
            </Button>
            {isRunning && (
              <Button
                onClick={handleStop}
                variant="destructive"
                disabled={loading}
              >
                <IconPlayerStop className="mr-2 size-4" />
                Stop & Save
              </Button>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

