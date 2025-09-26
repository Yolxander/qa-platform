"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { IconCheck, IconX, IconUpload, IconClipboardCheck, IconExternalLink, IconArrowLeft, IconMessage, IconPhoto, IconUser, IconClock } from "@tabler/icons-react"
import { supabase } from "@/lib/supabase"

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

export function VerifyPageContent({ issueId }: VerifyPageContentProps) {
  const router = useRouter()
  const [todo, setTodo] = React.useState<any>(null)
  const [loading, setLoading] = React.useState(true)
  const [stepsToReproduce, setStepsToReproduce] = React.useState("")
  const [expectedResult, setExpectedResult] = React.useState("")
  const [actualResult, setActualResult] = React.useState("")
  const [fixNote, setFixNote] = React.useState("")
  const [regressionNote, setRegressionNote] = React.useState("")
  const [screenshots, setScreenshots] = React.useState<string[]>([])
  const [showRegressionNote, setShowRegressionNote] = React.useState(false)

  // Fetch todo data from database
  const fetchTodoDetails = async () => {
    try {
      setLoading(true)
      
      if (!supabase) {
        console.warn('Supabase not configured')
        return
      }

      const { data, error } = await supabase
        .from('todos')
        .select('*')
        .eq('id', issueId)
        .single()

      if (error) {
        console.error('Error fetching todo details:', error)
        return
      }

      if (data) {
        setTodo(data)
      }
    } catch (error) {
      console.error('Error fetching todo details:', error)
    } finally {
      setLoading(false)
    }
  }

  React.useEffect(() => {
    fetchTodoDetails()
  }, [issueId])

  const handlePass = async () => {
    if (!todo || !supabase) return
    
    try {
      // Update todo status to DONE
      const { error } = await supabase
        .from('todos')
        .update({ 
          status: 'DONE',
          updated_at: new Date().toISOString()
        })
        .eq('id', todo.id)

      if (error) {
        console.error('Error updating todo status:', error)
        return
      }

      console.log("✅ PASS - Todo marked as Done", {
        todoId: todo.id,
        title: todo.title,
        stepsToReproduce,
        expectedResult,
        actualResult,
        fixNote,
        screenshots
      })
      // Navigate back to QA queue
      router.push("/ready-for-qa")
    } catch (error) {
      console.error('Error updating todo:', error)
    }
  }

  const handleFail = async () => {
    if (!todo || !supabase) return
    
    if (!showRegressionNote) {
      setShowRegressionNote(true)
      return
    }
    
    try {
      // Update todo status back to IN_PROGRESS
      const { error } = await supabase
        .from('todos')
        .update({ 
          status: 'IN_PROGRESS',
          updated_at: new Date().toISOString()
        })
        .eq('id', todo.id)

      if (error) {
        console.error('Error updating todo status:', error)
        return
      }

      console.log("❌ FAIL - Todo reopened to In Progress", {
        todoId: todo.id,
        title: todo.title,
        stepsToReproduce,
        expectedResult,
        actualResult,
        fixNote,
        regressionNote,
        screenshots
      })
      // Navigate back to QA queue
      router.push("/ready-for-qa")
    } catch (error) {
      console.error('Error updating todo:', error)
    }
  }

  const handleScreenshotUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files
    if (files) {
      const newScreenshots = Array.from(files).map(file => URL.createObjectURL(file))
      setScreenshots(prev => [...prev, ...newScreenshots])
    }
  }

  // Show loading state
  if (loading) {
    return (
      <div className="px-4 lg:px-6">
        <div className="flex items-center gap-4 mb-6">
          <Button
            variant="outline"
            size="sm"
            onClick={() => router.push("/ready-for-qa")}
            className="gap-2"
          >
            <IconArrowLeft className="size-4" />
            Back to QA Queue
          </Button>
        </div>
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
            <p className="text-muted-foreground">Loading task details...</p>
          </div>
        </div>
      </div>
    )
  }

  // Show error state if todo not found
  if (!todo) {
    return (
      <div className="px-4 lg:px-6">
        <div className="flex items-center gap-4 mb-6">
          <Button
            variant="outline"
            size="sm"
            onClick={() => router.push("/ready-for-qa")}
            className="gap-2"
          >
            <IconArrowLeft className="size-4" />
            Back to QA Queue
          </Button>
        </div>
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <h2 className="text-2xl font-bold mb-2">Task Not Found</h2>
            <p className="text-muted-foreground mb-4">The task you're looking for doesn't exist or has been deleted.</p>
            <Button onClick={() => router.push("/ready-for-qa")}>
              Return to QA Queue
            </Button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="px-4 lg:px-6">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <Button
          variant="outline"
          size="sm"
          onClick={() => router.push("/ready-for-qa")}
          className="gap-2"
        >
          <IconArrowLeft className="size-4" />
          Back to QA Queue
        </Button>
      </div>

      {/* E-commerce Product Overview Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Section - Task Details */}
        <div className="space-y-6 lg:col-span-2">
          {/* Task Header */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Badge variant={getEnvironmentBadgeVariant(todo.environment)}>
                  {todo.environment}
                </Badge>
                <Badge variant={getSeverityBadgeVariant(todo.severity)}>
                  {todo.severity}
                </Badge>
              </div>
              <div className="flex items-center gap-2">
                <Button variant="outline" size="sm">
                  <IconClipboardCheck className="size-4" />
                </Button>
              </div>
            </div>
            <h1 className="text-3xl font-bold tracking-tight">{todo.title}</h1>
            <p className="text-muted-foreground">Task #{todo.id}</p>
          </div>

          {/* QA Verification Form */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>QA Verification</CardTitle>
                <div className="flex gap-2">
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
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Steps to Reproduce */}
              <div className="space-y-2">
                <Label htmlFor="steps">Steps to Reproduce</Label>
                <Textarea
                  id="steps"
                  placeholder="1. Go to...
2. Click on...
3. Observe..."
                  value={stepsToReproduce}
                  onChange={(e) => setStepsToReproduce(e.target.value)}
                  className="min-h-[120px]"
                />
              </div>

              {/* Expected vs Actual */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="expected">Expected Result</Label>
                  <Textarea
                    id="expected"
                    placeholder="What should happen..."
                    value={expectedResult}
                    onChange={(e) => setExpectedResult(e.target.value)}
                    className="min-h-[120px]"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="actual">Actual Result</Label>
                  <Textarea
                    id="actual"
                    placeholder="What actually happens..."
                    value={actualResult}
                    onChange={(e) => setActualResult(e.target.value)}
                    className="min-h-[120px]"
                  />
                </div>
              </div>

              {/* Fix Note */}
              <div className="space-y-2">
                <Label htmlFor="fixNote">Fix Note (from dev)</Label>
                <Textarea
                  id="fixNote"
                  placeholder="Developer's notes about the fix..."
                  value={fixNote}
                  onChange={(e) => setFixNote(e.target.value)}
                  className="min-h-[120px]"
                />
              </div>

              {/* Regression Note (shown when failing) */}
              {showRegressionNote && (
                <div className="space-y-2">
                  <Label htmlFor="regressionNote" className="text-destructive">Regression Note Required</Label>
                  <Textarea
                    id="regressionNote"
                    placeholder="Add regression note and screenshot..."
                    value={regressionNote}
                    onChange={(e) => setRegressionNote(e.target.value)}
                    className="min-h-[120px] border-destructive"
                  />
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Right Section - Task Metadata & Screenshots/Visuals */}
        <div className="space-y-6">
          {/* Task Metadata */}
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Assignee:</span>
                <span className="ml-2 font-medium">{todo.assignee || "Unassigned"}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Due Date:</span>
                <span className="ml-2 font-medium">{todo.due_date}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Created:</span>
                <span className="ml-2 font-medium">{new Date(todo.created_at).toLocaleDateString()}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Updated:</span>
                <span className="ml-2 font-medium">{new Date(todo.updated_at).toLocaleDateString()}</span>
              </div>
            </div>
          </div>

          {/* Issue Link */}
          {todo.issue_link && (
            <div className="space-y-2">
              <h3 className="text-sm font-medium">Related Issue</h3>
              <div className="flex items-center gap-2">
                <span className="text-sm font-mono bg-muted px-3 py-2 rounded-md flex-1">
                  {todo.issue_link}
                </span>
                <Button variant="outline" size="sm">
                  <IconExternalLink className="size-4" />
                </Button>
              </div>
            </div>
          )}

          {/* Screenshots Section */}
          <div className="space-y-4">
            {/* Main Screenshot */}
            <div className="aspect-square bg-gray-100 rounded-lg overflow-hidden">
              {screenshots.length > 0 ? (
                <img
                  src={screenshots[0]}
                  alt="Main verification screenshot"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-gray-100">
                  <div className="text-center text-gray-500">
                    <IconPhoto className="size-12 mx-auto mb-2" />
                    <p>No screenshots uploaded</p>
                  </div>
                </div>
              )}
            </div>

            {/* Thumbnail Screenshots */}
            {screenshots.length > 1 && (
              <div className="grid grid-cols-2 gap-2">
                {screenshots.slice(1, 5).map((screenshot, index) => (
                  <div key={index} className="aspect-square bg-gray-100 rounded-lg overflow-hidden cursor-pointer hover:opacity-80 transition-opacity">
                    <img
                      src={screenshot}
                      alt={`Screenshot ${index + 2}`}
                      className="w-full h-full object-cover"
                    />
                  </div>
                ))}
              </div>
            )}

            {/* Upload Screenshots */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <IconUpload className="size-5" />
                  Upload Screenshots
                </CardTitle>
              </CardHeader>
              <CardContent>
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
                  Choose Screenshots
                </Label>
                <p className="text-sm text-muted-foreground mt-2">
                  Upload screenshots to document your verification process
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
}
