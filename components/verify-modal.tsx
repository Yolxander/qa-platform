"use client"

import * as React from "react"
import { IconCheck, IconX, IconUpload, IconCamera, IconExternalLink } from "@tabler/icons-react"

import { Badge } from "@/components/ui/badge"
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
import { Separator } from "@/components/ui/separator"
import { Textarea } from "@/components/ui/textarea"

interface VerifyModalProps {
  issue: {
    id: number
    title: string
    severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW"
    environment: "Prod" | "Stage" | "Dev"
    linkedPR?: string
    updatedAt: string
    assignee: string
  }
  children: React.ReactNode
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

export function VerifyModal({ issue, children }: VerifyModalProps) {
  const [open, setOpen] = React.useState(false)
  const [stepsToReproduce, setStepsToReproduce] = React.useState("")
  const [expectedResult, setExpectedResult] = React.useState("")
  const [actualResult, setActualResult] = React.useState("")
  const [fixNote, setFixNote] = React.useState("")
  const [regressionNote, setRegressionNote] = React.useState("")
  const [screenshots, setScreenshots] = React.useState<string[]>([])

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
    setOpen(false)
    // Reset form
    setStepsToReproduce("")
    setExpectedResult("")
    setActualResult("")
    setFixNote("")
    setRegressionNote("")
    setScreenshots([])
  }

  const handleFail = () => {
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
    setOpen(false)
    // Reset form
    setStepsToReproduce("")
    setExpectedResult("")
    setActualResult("")
    setFixNote("")
    setRegressionNote("")
    setScreenshots([])
  }

  const handleScreenshotUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files
    if (files) {
      const newScreenshots = Array.from(files).map(file => URL.createObjectURL(file))
      setScreenshots(prev => [...prev, ...newScreenshots])
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconCamera className="size-5" />
            Verify Issue: {issue.title}
          </DialogTitle>
          <DialogDescription>
            Review the issue details and test the fix
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Issue Summary */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">Issue Summary</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 border rounded-lg bg-muted/50">
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
          </div>

          <Separator />

          {/* Screenshots */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold">Screenshots</h3>
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
          </div>

          <Separator />

          {/* Steps to Reproduce */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">Steps to Reproduce</h3>
            <Textarea
              placeholder="1. Go to...
2. Click on...
3. Observe..."
              value={stepsToReproduce}
              onChange={(e) => setStepsToReproduce(e.target.value)}
              className="min-h-[100px]"
            />
          </div>

          <Separator />

          {/* Expected vs Actual */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">Expected vs Actual</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="expected">Expected Result (from report)</Label>
                <Textarea
                  id="expected"
                  placeholder="What should happen..."
                  value={expectedResult}
                  onChange={(e) => setExpectedResult(e.target.value)}
                  className="min-h-[80px]"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="actual">Actual Result</Label>
                <Textarea
                  id="actual"
                  placeholder="What actually happens..."
                  value={actualResult}
                  onChange={(e) => setActualResult(e.target.value)}
                  className="min-h-[80px]"
                />
              </div>
            </div>
          </div>

          <Separator />

          {/* Fix Note */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">Fix Note (from dev)</h3>
            <Textarea
              placeholder="Developer's notes about the fix..."
              value={fixNote}
              onChange={(e) => setFixNote(e.target.value)}
              className="min-h-[80px]"
            />
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-4 pt-4">
            <Button
              variant="outline"
              onClick={() => setOpen(false)}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleFail}
              className="gap-2"
            >
              <IconX className="size-4" />
              ❌ Fail
            </Button>
            <Button
              onClick={handlePass}
              className="gap-2"
            >
              <IconCheck className="size-4" />
              ✅ Pass
            </Button>
          </div>

          {/* Regression Note (only shown when failing) */}
          {regressionNote && (
            <div className="space-y-4 p-4 border border-destructive rounded-lg bg-destructive/5">
              <h4 className="text-sm font-semibold text-destructive">Regression Note Required</h4>
              <Textarea
                placeholder="Add regression note and screenshot..."
                value={regressionNote}
                onChange={(e) => setRegressionNote(e.target.value)}
                className="min-h-[80px]"
              />
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
