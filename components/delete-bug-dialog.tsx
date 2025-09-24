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
import { IconBug, IconLoader2, IconAlertTriangle } from "@tabler/icons-react"
import { toast } from "sonner"

interface DeleteBugDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  bug: {
    id: number
    title: string
    severity: string
    status: string
  }
  onBugDeleted?: () => void
}

export function DeleteBugDialog({ open, onOpenChange, bug, onBugDeleted }: DeleteBugDialogProps) {
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
        .from('bug_time_entries')
        .delete()
        .eq('bug_id', bug.id)

      // Then delete the bug
      const { error } = await supabase
        .from('bugs')
        .delete()
        .eq('id', bug.id)

      if (error) {
        throw error
      }

      toast.success("Bug deleted successfully!")
      onOpenChange(false)
      
      if (onBugDeleted) {
        onBugDeleted()
      }
    } catch (error) {
      console.error("Error deleting bug:", error)
      toast.error("Failed to delete bug. Please check your Supabase configuration.")
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
            Delete Bug
          </DialogTitle>
          <DialogDescription className="text-left">
            Are you sure you want to delete this bug? This action cannot be undone.
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Bug Info */}
          <div className="bg-muted/50 p-4 rounded-lg">
            <div className="flex items-center gap-2 mb-2">
              <IconBug className="size-4" />
              <span className="text-sm font-medium">Bug #{bug.id}</span>
              <span className={`px-2 py-1 text-xs rounded-full ${
                bug.severity === 'CRITICAL' ? 'bg-red-100 text-red-800' :
                bug.severity === 'HIGH' ? 'bg-orange-100 text-orange-800' :
                bug.severity === 'MEDIUM' ? 'bg-yellow-100 text-yellow-800' :
                'bg-green-100 text-green-800'
              }`}>
                {bug.severity}
              </span>
            </div>
            <div className="text-sm font-medium mb-1">{bug.title}</div>
            <div className="text-xs text-muted-foreground">
              Status: {bug.status}
            </div>
          </div>

          {/* Warning Message */}
          <div className="bg-destructive/10 border border-destructive/20 p-4 rounded-lg">
            <div className="flex items-start gap-2">
              <IconAlertTriangle className="size-4 text-destructive mt-0.5 flex-shrink-0" />
              <div className="text-sm">
                <div className="font-medium text-destructive mb-1">Warning</div>
                <div className="text-destructive/80">
                  This will permanently delete the bug and all associated time entries and comments. 
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
                <IconBug className="size-4" />
              )}
              {loading ? "Deleting..." : "Delete Bug"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
