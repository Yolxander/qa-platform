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
} from "@/components/ui/dialog"
import { IconTrash, IconLoader2, IconAlertTriangle } from "@tabler/icons-react"
import { toast } from "sonner"

interface DeleteTodoDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  todo: {
    id: number
    title: string
  }
  onTodoDeleted?: () => void
}

export function DeleteTodoDialog({ open, onOpenChange, todo, onTodoDeleted }: DeleteTodoDialogProps) {
  const [loading, setLoading] = useState(false)
  const { currentProject } = useAuth()

  const handleDelete = async () => {
    if (!supabase) {
      toast.error("Database not configured. Please set up Supabase environment variables.")
      return
    }

    setLoading(true)
    try {
      // First delete related time entries
      await supabase
        .from('todo_time_entries')
        .delete()
        .eq('todo_id', todo.id)

      // Then delete the todo
      const { error } = await supabase
        .from('todos')
        .delete()
        .eq('id', todo.id)

      if (error) {
        throw error
      }

      toast.success("Todo deleted successfully!")
      onOpenChange(false)
      
      if (onTodoDeleted) {
        onTodoDeleted()
      }
    } catch (error) {
      console.error("Error deleting todo:", error)
      toast.error("Failed to delete todo. Please check your Supabase configuration.")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[400px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-destructive">
            <IconAlertTriangle className="size-5" />
            Delete Todo
          </DialogTitle>
          <DialogDescription className="text-left">
            Are you sure you want to delete this todo? This action cannot be undone.
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Todo Info */}
          <div className="bg-muted/50 p-4 rounded-lg">
            <div className="text-sm font-medium text-muted-foreground mb-1">Todo to be deleted:</div>
            <div className="font-medium">{todo.title}</div>
          </div>

          {/* Warning Message */}
          <div className="bg-destructive/10 border border-destructive/20 p-4 rounded-lg">
            <div className="flex items-start gap-2">
              <IconAlertTriangle className="size-4 text-destructive mt-0.5 flex-shrink-0" />
              <div className="text-sm">
                <div className="font-medium text-destructive mb-1">Warning</div>
                <div className="text-destructive/80">
                  This will permanently delete the todo and all associated time entries. 
                  You will not be able to recover this data.
                </div>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex justify-end gap-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button
              onClick={handleDelete}
              variant="destructive"
              disabled={loading}
              className="gap-2"
            >
              {loading ? (
                <IconLoader2 className="size-4 animate-spin" />
              ) : (
                <IconTrash className="size-4" />
              )}
              {loading ? "Deleting..." : "Delete Todo"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

