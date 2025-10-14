import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

export async function GET(request: NextRequest) {
  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    
    if (!supabaseUrl || !supabaseAnonKey) {
      return NextResponse.json({ error: 'Supabase not configured' }, { status: 500 })
    }

    // Create a new supabase client for server-side use
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    // Get the authorization header
    const authHeader = request.headers.get('authorization')
    if (!authHeader) {
      return NextResponse.json({ error: 'No authorization header' }, { status: 401 })
    }

    // Extract the token from the header
    const token = authHeader.replace('Bearer ', '')
    
    // Set the session for this request
    const { data: { user }, error: userError } = await supabase.auth.getUser(token)
    if (userError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Get query parameters
    const { searchParams } = new URL(request.url)
    const projectId = searchParams.get('projectId')
    const isAllProjects = !projectId || projectId === 'null' || projectId === 'undefined'

    let bugs, todos, accessibleProjectIds

    console.log('Dashboard API - projectId:', projectId, 'isAllProjects:', isAllProjects)

    if (isAllProjects) {
      // Get all accessible projects for the user
      const { data: ownedProjects, error: ownedError } = await supabase
        .from('projects')
        .select('id')
        .eq('user_id', user.id)

      if (ownedError) {
        console.error('Error fetching owned projects:', ownedError)
        return NextResponse.json({ error: 'Failed to fetch owned projects' }, { status: 500 })
      }

      // Get invited projects
      const { data: memberProjects, error: memberError } = await supabase
        .rpc('get_member_projects', { user_profile_id: user.id })

      if (memberError) {
        console.error('Error fetching member projects:', memberError)
        return NextResponse.json({ error: 'Failed to fetch member projects' }, { status: 500 })
      }

      // Combine all accessible project IDs
      const ownedProjectIds = ownedProjects?.map(p => p.id) || []
      const invitedProjectIds = memberProjects?.map(p => p.project_id) || []
      accessibleProjectIds = [...new Set([...ownedProjectIds, ...invitedProjectIds])]

      console.log('All Projects Mode - Accessible project IDs:', accessibleProjectIds)

      // Fetch bugs from all accessible projects
      const { data: bugsData, error: bugsError } = await supabase
        .from('bugs')
        .select('*, projects!inner(name)')
        .in('project_id', accessibleProjectIds)

      if (bugsError) {
        console.error('Error fetching bugs:', bugsError)
        return NextResponse.json({ error: 'Failed to fetch bugs' }, { status: 500 })
      }

      // Fetch todos from all accessible projects
      const { data: todosData, error: todosError } = await supabase
        .from('todos')
        .select('*, projects!inner(name)')
        .in('project_id', accessibleProjectIds)

      if (todosError) {
        console.error('Error fetching todos:', todosError)
        return NextResponse.json({ error: 'Failed to fetch todos' }, { status: 500 })
      }

      bugs = bugsData
      todos = todosData
    } else {
      // Single project mode - existing logic
      const { data: bugsData, error: bugsError } = await supabase
        .from('bugs')
        .select('*')
        .eq('user_id', user.id)
        .eq('project_id', projectId)

      if (bugsError) {
        console.error('Error fetching bugs:', bugsError)
        return NextResponse.json({ error: 'Failed to fetch bugs' }, { status: 500 })
      }

      const { data: todosData, error: todosError } = await supabase
        .from('todos')
        .select('*')
        .eq('user_id', user.id)
        .eq('project_id', projectId)

      if (todosError) {
        console.error('Error fetching todos:', todosError)
        return NextResponse.json({ error: 'Failed to fetch todos' }, { status: 500 })
      }

      bugs = bugsData
      todos = todosData
    }

    console.log('Dashboard API - Bugs found:', bugs?.length || 0, 'Project ID:', projectId, 'All Projects:', isAllProjects)
    console.log('Dashboard API - Todos found:', todos?.length || 0, 'Project ID:', projectId, 'All Projects:', isAllProjects)
    console.log('Dashboard API - Sample bugs:', bugs?.slice(0, 2))
    console.log('Dashboard API - Sample todos:', todos?.slice(0, 2))

    // Calculate dashboard metrics
    const totalBugs = bugs?.length || 0
    const openBugs = bugs?.filter(bug => bug.status === 'Open').length || 0
    const readyForQABugs = bugs?.filter(bug => bug.status === 'Ready for QA').length || 0
    const criticalBugs = bugs?.filter(bug => bug.severity === 'CRITICAL' && bug.status === 'Open').length || 0

    // Calculate MTTR (Mean Time To Resolution) - calculate from actual data
    const resolvedBugs = bugs?.filter(bug => bug.status === 'Closed') || []
    let mttr = 'N/A'
    if (resolvedBugs.length > 0) {
      // Calculate average time between creation and resolution
      const totalTime = resolvedBugs.reduce((sum, bug) => {
        const created = new Date(bug.created_at)
        const updated = new Date(bug.updated_at)
        return sum + (updated.getTime() - created.getTime())
      }, 0)
      const avgTimeMs = totalTime / resolvedBugs.length
      const avgHours = Math.round(avgTimeMs / (1000 * 60 * 60))
      mttr = avgHours > 24 ? `${Math.round(avgHours / 24)}d` : `${avgHours}h`
    }

    // Calculate todo metrics
    const totalTodos = todos?.length || 0
    const openTodos = todos?.filter(todo => todo.status === 'OPEN').length || 0
    const inProgressTodos = todos?.filter(todo => todo.status === 'IN_PROGRESS').length || 0
    const readyForQATodos = todos?.filter(todo => todo.status === 'READY_FOR_QA').length || 0
    const doneTodos = todos?.filter(todo => todo.status === 'DONE').length || 0

    // Get recent activity for chart data (last 14 days)
    const fourteenDaysAgo = new Date()
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14)

    const recentBugs = bugs?.filter(bug => 
      new Date(bug.created_at) >= fourteenDaysAgo
    ) || []

    // Generate chart data for the last 14 days
    const chartData = []
    for (let i = 13; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      const dateStr = date.toISOString().split('T')[0]
      
      const openedOnDate = recentBugs.filter(bug => 
        bug.created_at.split('T')[0] === dateStr
      ).length

      const closedOnDate = bugs?.filter(bug => 
        bug.status === 'Closed' && 
        bug.updated_at.split('T')[0] === dateStr
      ).length || 0

      chartData.push({
        date: dateStr,
        opened: openedOnDate,
        closed: closedOnDate
      })
    }

    // Prepare table data (combining bugs and todos)
    const tableData = [
      ...(bugs || []).map(bug => ({
        id: bug.id,
        header: bug.title,
        type: bug.severity,
        status: bug.status,
        target: bug.assignee,
        limit: bug.created_at,
        reviewer: bug.reporter,
        source: 'bug',
        project: isAllProjects ? bug.projects?.name || 'Unknown Project' : undefined
      })),
      ...(todos || []).map(todo => ({
        id: todo.id + 10000, // Offset to avoid ID conflicts
        header: todo.title,
        type: todo.severity,
        status: todo.status,
        target: todo.assignee,
        limit: todo.due_date,
        reviewer: 'Assign reviewer',
        source: 'todo',
        project: isAllProjects ? todo.projects?.name || 'Unknown Project' : undefined
      }))
    ]

    const dashboardData = {
      metrics: {
        openIssues: openBugs,
        readyForQA: readyForQATodos, // Changed to show todos ready for QA
        mttr: mttr,
        criticalOpen: criticalBugs,
        // Additional metrics for better insights
        totalBugs,
        totalTodos,
        openTodos,
        inProgressTodos,
        doneTodos
      },
      chartData,
      tableData,
      totalBugs,
      totalTodos: todos?.length || 0,
      isAllProjects,
      accessibleProjectCount: isAllProjects ? accessibleProjectIds?.length || 0 : 1
    }

    return NextResponse.json(dashboardData)
  } catch (error) {
    console.error('Dashboard API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
