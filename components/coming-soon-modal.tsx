"use client"

import { useState } from "react"
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
import { toast } from "sonner"
import { IconMail, IconLoader2 } from "@tabler/icons-react"

interface ComingSoonModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  planName: string
}

export function ComingSoonModal({ open, onOpenChange, planName }: ComingSoonModalProps) {
  const [email, setEmail] = useState("")
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!email.trim()) {
      toast.error("Please enter your email address")
      return
    }

    if (!email.includes("@")) {
      toast.error("Please enter a valid email address")
      return
    }

    setLoading(true)
    
    try {
      // Simulate API call - in a real app, you'd send this to your backend
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      toast.success("Thanks! We'll notify you when this feature is ready.")
      setEmail("")
      onOpenChange(false)
    } catch (error) {
      toast.error("Something went wrong. Please try again.")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconMail className="size-5" />
            Coming Soon: {planName}
          </DialogTitle>
          <DialogDescription>
            This feature will be ready soon! Leave your email to get notified when it's available.
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email">Email Address</Label>
            <Input
              id="email"
              type="email"
              placeholder="your@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          
          <div className="flex justify-end space-x-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading && <IconLoader2 className="mr-2 size-4 animate-spin" />}
              Notify Me
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
