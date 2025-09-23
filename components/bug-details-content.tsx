"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { IconArrowLeft, IconExternalLink, IconMessage, IconPaperclip, IconUser, IconClock } from "@tabler/icons-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { Textarea } from "@/components/ui/textarea"

interface BugDetailsContentProps {
  bugId: number
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

const getStatusBadgeVariant = (status: string) => {
  switch (status) {
    case "Open":
      return "default"
    case "Closed":
      return "outline"
    default:
      return "secondary"
  }
}

const getEnvironmentBadgeVariant = (environment: string) => {
  switch (environment) {
    case "Prod":
      return "destructive"
    case "Stage":
      return "default"
    case "Dev":
      return "secondary"
    default:
      return "outline"
  }
}

// Mock bug details data - in a real app, this would be fetched based on bugId
const mockBugDetails = {
  id: 1,
  title: "Login button not responding on mobile",
  status: "Open" as const,
  severity: "CRITICAL" as const,
  environment: "Prod" as const,
  url: "https://app.example.com/login",
  stepsToReproduce: "1. Open the mobile app\n2. Navigate to the login screen\n3. Tap the 'Login' button\n4. Observe that nothing happens",
  expectedResult: "User should be redirected to the dashboard after successful login",
  actualResult: "Login button appears to be pressed but no action occurs, user remains on login screen",
  screenshots: [
    "/api/placeholder/400/300",
    "/api/placeholder/400/300",
    "/api/placeholder/400/300"
  ],
  linkedPR: "#PR-123",
  externalTicketId: "JIRA-456",
  reporter: "Sarah Chen",
  assignee: "Alex Thompson",
  createdAt: "2024-01-15T10:30:00Z",
  updatedAt: "2 hours ago"
}

const mockComments = [
  {
    id: 1,
    author: "Alex Thompson",
    timestamp: "2 hours ago",
    content: "I've reproduced this issue on iOS Safari. The button click event isn't being captured properly. @Sarah Chen can you test on Android as well?",
    attachments: ["screenshot1.png"]
  },
  {
    id: 2,
    author: "Sarah Chen",
    timestamp: "1 hour ago",
    content: "Confirmed on Android Chrome as well. The issue seems to be with the touch event handler. @Mike Johnson any insights on this?",
    attachments: []
  },
  {
    id: 3,
    author: "Mike Johnson",
    timestamp: "30 minutes ago",
    content: "Looking into the touch event handling. This might be related to the recent changes in the mobile navigation component.",
    attachments: []
  }
]

const mockActivityLog = [
  {
    id: 1,
    action: "Bug created",
    user: "Sarah Chen",
    timestamp: "2024-01-15T10:30:00Z",
    details: "Bug reported via mobile app"
  },
  {
    id: 2,
    action: "Assigned",
    user: "System",
    timestamp: "2024-01-15T10:35:00Z",
    details: "Assigned to Alex Thompson"
  },
  {
    id: 3,
    action: "Status changed",
    user: "Alex Thompson",
    timestamp: "2024-01-15T11:00:00Z",
    details: "Status changed from New to In Progress"
  },
  {
    id: 4,
    action: "Comment added",
    user: "Alex Thompson",
    timestamp: "2 hours ago",
    details: "Added comment about iOS Safari reproduction"
  },
  {
    id: 5,
    action: "Comment added",
    user: "Sarah Chen",
    timestamp: "1 hour ago",
    details: "Added comment confirming Android issue"
  }
]

export function BugDetailsContent({ bugId }: BugDetailsContentProps) {
  const router = useRouter()
  const [newComment, setNewComment] = React.useState("")

  // In a real app, fetch bug details based on bugId
  const bug = mockBugDetails
  const comments = mockComments
  const activityLog = mockActivityLog

  const handleAddComment = () => {
    if (newComment.trim()) {
      console.log("Adding comment:", newComment)
      setNewComment("")
    }
  }

  return (
    <div className="px-4 lg:px-6 space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button
          variant="outline"
          size="sm"
          onClick={() => router.push("/bugs")}
          className="gap-2"
        >
          <IconArrowLeft className="size-4" />
          Back to Bugs
        </Button>
        <div className="flex items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{bug.title}</h1>
          </div>
        </div>
      </div>

      {/* URL of Occurrence and Steps to Reproduce - Side by side on larger screens */}
      <div className="grid grid-cols-1 @container/bug-details:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>URL of Occurrence</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              <span className="text-sm font-mono bg-muted px-2 py-1 rounded">
                {bug.url}
              </span>
              <Button variant="outline" size="sm">
                <IconExternalLink className="size-4" />
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Steps to Reproduce</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="whitespace-pre-line text-sm">
              {bug.stepsToReproduce}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Expected vs Actual */}
      <Card>
        <CardHeader>
          <CardTitle>Expected vs Actual</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label className="text-sm font-medium text-green-600">Expected Result</Label>
              <div className="text-sm bg-green-50 p-3 rounded-md border border-green-200">
                {bug.expectedResult}
              </div>
            </div>
            <div className="space-y-2">
              <Label className="text-sm font-medium text-red-600">Actual Result</Label>
              <div className="text-sm bg-red-50 p-3 rounded-md border border-red-200">
                {bug.actualResult}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Screenshots */}
      <Card>
        <CardHeader>
          <CardTitle>Screenshots</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {bug.screenshots.map((screenshot, index) => (
              <div key={index} className="relative group cursor-pointer">
                <img
                  src={screenshot}
                  alt={`Screenshot ${index + 1}`}
                  className="w-full h-48 object-cover rounded-md border hover:opacity-90 transition-opacity"
                  onClick={() => console.log(`Opening lightbox for screenshot ${index + 1}`)}
                />
                <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all rounded-md flex items-center justify-center">
                  <span className="text-white opacity-0 group-hover:opacity-100 transition-opacity text-sm">
                    Click to enlarge
                  </span>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Linked PR/Commit and Comments - Side by side on larger screens */}
      <div className="grid grid-cols-1 @container/bug-details:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Linked PR/Commit & External Ticket</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Label className="text-sm font-medium">Pull Request:</Label>
                <span className="text-sm font-mono bg-muted px-2 py-1 rounded">
                  {bug.linkedPR}
                </span>
                <Button variant="outline" size="sm">
                  <IconExternalLink className="size-4" />
                </Button>
              </div>
              <div className="flex items-center gap-2">
                <Label className="text-sm font-medium">External Ticket:</Label>
                <span className="text-sm font-mono bg-muted px-2 py-1 rounded">
                  {bug.externalTicketId}
                </span>
                <Button variant="outline" size="sm">
                  <IconExternalLink className="size-4" />
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Comments</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {comments.map((comment) => (
                <div key={comment.id} className="border-l-2 border-muted pl-4">
                  <div className="flex items-center gap-2 mb-2">
                    <IconUser className="size-4 text-muted-foreground" />
                    <span className="font-medium text-sm">{comment.author}</span>
                    <span className="text-xs text-muted-foreground">{comment.timestamp}</span>
                  </div>
                  <div className="text-sm mb-2">
                    {comment.content}
                  </div>
                  {comment.attachments.length > 0 && (
                    <div className="flex items-center gap-1">
                      <IconPaperclip className="size-3 text-muted-foreground" />
                      <span className="text-xs text-muted-foreground">
                        {comment.attachments.join(", ")}
                      </span>
                    </div>
                  )}
                </div>
              ))}
              
              <Separator />
              
              <div className="space-y-3">
                <Textarea
                  placeholder="Add a comment... Use @ to mention team members"
                  value={newComment}
                  onChange={(e) => setNewComment(e.target.value)}
                  className="min-h-[80px]"
                />
                <div className="flex justify-end">
                  <Button onClick={handleAddComment} disabled={!newComment.trim()}>
                    <IconMessage className="size-4 mr-2" />
                    Add Comment
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Activity Log */}
      <Card>
        <CardHeader>
          <CardTitle>Activity Log</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {activityLog.map((activity) => (
              <div key={activity.id} className="flex items-start gap-3">
                <div className="flex-shrink-0 w-2 h-2 bg-primary rounded-full mt-2"></div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-medium text-sm">{activity.action}</span>
                    <span className="text-xs text-muted-foreground">by {activity.user}</span>
                  </div>
                  <div className="text-xs text-muted-foreground mb-1">
                    <IconClock className="size-3 inline mr-1" />
                    {activity.timestamp}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {activity.details}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
