"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { IconCheck, IconX, IconUpload, IconClipboardCheck, IconExternalLink, IconArrowLeft } from "@tabler/icons-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

interface VerifyPageContentProps {
  issueId: number
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

// Mock issue data - in a real app, this would be fetched based on issueId
const mockIssue = {
  id: 1,
  title: "Fix login authentication bug",
  severity: "CRITICAL" as const,
  environment: "Prod" as const,
  linkedPR: "#PR-123",
  updatedAt: "2 hours ago",
  assignee: "Sarah Chen",
  description: "Users are unable to log in to the application due to authentication token validation issues. This affects all production users and prevents access to the main dashboard."
}

export function VerifyPageContent({ issueId }: VerifyPageContentProps) {
  const router = useRouter()
  const [stepsToReproduce, setStepsToReproduce] = React.useState("")
  const [expectedResult, setExpectedResult] = React.useState("")
  const [actualResult, setActualResult] = React.useState("")
  const [fixNote, setFixNote] = React.useState("")
  const [regressionNote, setRegressionNote] = React.useState("")
  const [screenshots, setScreenshots] = React.useState<string[]>([])
  const [showRegressionNote, setShowRegressionNote] = React.useState(false)

  // In a real app, fetch issue data based on issueId
  const issue = mockIssue

  const handlePass = () => {
    console.log("✅ PASS - Issue marked as Done", {
      issueId: issue.id,
      title: issue.title,
      stepsToReproduce,
      expectedResult,
      actualResult,
      fixNote,
      screenshots
    })
    // Navigate back to QA queue
    router.push("/ready-for-qa")
  }

  const handleFail = () => {
    if (!showRegressionNote) {
      setShowRegressionNote(true)
      return
    }
    
    console.log("❌ FAIL - Issue reopened to In Dev", {
      issueId: issue.id,
      title: issue.title,
      stepsToReproduce,
      expectedResult,
      actualResult,
      fixNote,
      regressionNote,
      screenshots
    })
    // Navigate back to QA queue
    router.push("/ready-for-qa")
  }

  const handleScreenshotUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files
    if (files) {
      const newScreenshots = Array.from(files).map(file => URL.createObjectURL(file))
      setScreenshots(prev => [...prev, ...newScreenshots])
    }
  }

  return (
    <div className="px-4 lg:px-6 space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button
          variant="outline"
          size="sm"
          onClick={() => router.push("/ready-for-qa")}
          className="gap-2"
        >
          <IconArrowLeft className="size-4" />
          Back to QA Queue
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight flex items-center gap-2">
            <IconClipboardCheck className="size-6" />
            Verifying {issue.title}
          </h1>
        </div>
      </div>

      {/* Issue Summary Card */}
      <Card>
        <CardHeader>
          <CardTitle>Issue Summary</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label className="text-sm font-medium">Title</Label>
              <p className="text-sm">{issue.title}</p>
            </div>
            <div className="space-y-2">
              <Label className="text-sm font-medium">Issue URL</Label>
              <div className="flex items-center gap-2">
                <span className="text-sm font-mono">#{issue.id}</span>
                <IconExternalLink className="size-3 text-muted-foreground" />
              </div>
            </div>
            <div className="space-y-2">
              <Label className="text-sm font-medium">Severity</Label>
              <Badge variant={getSeverityBadgeVariant(issue.severity)}>
                {issue.severity}
              </Badge>
            </div>
            <div className="space-y-2">
              <Label className="text-sm font-medium">Environment</Label>
              <Badge variant={getEnvironmentBadgeVariant(issue.environment)}>
                {issue.environment}
              </Badge>
            </div>
            <div className="space-y-2">
              <Label className="text-sm font-medium">Assignee</Label>
              <p className="text-sm">{issue.assignee}</p>
            </div>
            <div className="space-y-2">
              <Label className="text-sm font-medium">Updated</Label>
              <p className="text-sm text-muted-foreground">{issue.updatedAt}</p>
            </div>
          </div>
          <div className="mt-4 space-y-2">
            <Label className="text-sm font-medium">Description</Label>
            <p className="text-sm text-muted-foreground">{issue.description}</p>
          </div>
        </CardContent>
      </Card>

      {/* Screenshots Card */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Screenshots</CardTitle>
            <div className="flex items-center gap-2">
              <Input
                type="file"
                accept="image/*"
                multiple
                onChange={handleScreenshotUpload}
                className="hidden"
                id="screenshot-upload"
              />
              <Label
                htmlFor="screenshot-upload"
                className="flex items-center gap-2 px-3 py-2 border rounded-md cursor-pointer hover:bg-accent"
              >
                <IconUpload className="size-4" />
                Upload Screenshots
              </Label>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {screenshots.map((screenshot, index) => (
              <div key={index} className="relative group">
                <img
                  src={screenshot}
                  alt={`Screenshot ${index + 1}`}
                  className="w-full h-32 object-cover rounded-md border"
                />
                <Button
                  size="sm"
                  variant="destructive"
                  className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity"
                  onClick={() => setScreenshots(prev => prev.filter((_, i) => i !== index))}
                >
                  <IconX className="size-3" />
                </Button>
              </div>
            ))}
            {screenshots.length === 0 && (
              <div className="col-span-full flex items-center justify-center h-32 border-2 border-dashed rounded-md text-muted-foreground">
                No screenshots uploaded
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Steps to Reproduce Card */}
      <Card>
        <CardHeader>
          <CardTitle>Steps to Reproduce</CardTitle>
        </CardHeader>
        <CardContent>
          <Textarea
            placeholder="1. Go to...
2. Click on...
3. Observe..."
            value={stepsToReproduce}
            onChange={(e) => setStepsToReproduce(e.target.value)}
            className="min-h-[120px]"
          />
        </CardContent>
      </Card>

      {/* Expected vs Actual Card */}
      <Card>
        <CardHeader>
          <CardTitle>Expected vs Actual</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="expected">Expected Result (from report)</Label>
              <Textarea
                id="expected"
                placeholder="What should happen..."
                value={expectedResult}
                onChange={(e) => setExpectedResult(e.target.value)}
                className="min-h-[100px]"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="actual">Actual Result</Label>
              <Textarea
                id="actual"
                placeholder="What actually happens..."
                value={actualResult}
                onChange={(e) => setActualResult(e.target.value)}
                className="min-h-[100px]"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Fix Note Card */}
      <Card>
        <CardHeader>
          <CardTitle>Fix Note (from dev)</CardTitle>
        </CardHeader>
        <CardContent>
          <Textarea
            placeholder="Developer's notes about the fix..."
            value={fixNote}
            onChange={(e) => setFixNote(e.target.value)}
            className="min-h-[100px]"
          />
        </CardContent>
      </Card>

      {/* Regression Note Card (shown when failing) */}
      {showRegressionNote && (
        <Card className="border-destructive">
          <CardHeader>
            <CardTitle className="text-destructive">Regression Note Required</CardTitle>
          </CardHeader>
          <CardContent>
            <Textarea
              placeholder="Add regression note and screenshot..."
              value={regressionNote}
              onChange={(e) => setRegressionNote(e.target.value)}
              className="min-h-[100px]"
            />
          </CardContent>
        </Card>
      )}

      {/* Actions */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center justify-end gap-4">
            <Button
              variant="outline"
              onClick={() => router.push("/ready-for-qa")}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleFail}
              className="gap-2"
            >
              <IconX className="size-4" />
              Fail
            </Button>
            <Button
              onClick={handlePass}
              className="gap-2"
            >
              <IconCheck className="size-4" />
              Pass
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
