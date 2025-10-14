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

    let bugs, todos, accessibleProjectIds, comprehensiveDashboardData

    console.log('Dashboard API - projectId:', projectId, 'isAllProjects:', isAllProjects)

    if (isAllProjects) {
      console.log('🚀 ALL PROJECTS MODE - Using comprehensive dashboard function')
      console.log('👤 User ID:', user.id)
      
      // Use the new comprehensive dashboard function
      const { data: dashboardData, error: dashboardError } = await supabase
        .rpc('get_user_dashboard_data', { user_profile_id: user.id })

      if (dashboardError) {
        console.error('❌ Error fetching comprehensive dashboard data:', dashboardError)
        return NextResponse.json({ error: 'Failed to fetch dashboard data' }, { status: 500 })
      }

      if (!dashboardData) {
        console.error('❌ No dashboard data returned')
        return NextResponse.json({ error: 'No dashboard data available' }, { status: 404 })
      }

      // Store the comprehensive data for later use
      comprehensiveDashboardData = dashboardData
      
      // Extract data from the comprehensive response
      const projects = dashboardData.projects
      const ownedProjects = projects.owned || []
      const memberProjects = projects.member || []
      const allProjectIds = projects.all_ids || []
      
      bugs = dashboardData.bugs || []
      todos = dashboardData.todos || []
      accessibleProjectIds = allProjectIds

      // COMPREHENSIVE CONSOLE LOGGING FOR ALL PROJECTS MODE
      console.log('='.repeat(80))
      console.log('📊 COMPREHENSIVE DASHBOARD DATA FOR ALL PROJECTS')
      console.log('='.repeat(80))
      
      console.log('📁 PROJECTS BREAKDOWN:')
      console.log('  🏠 Owned Projects:', ownedProjects.length)
      ownedProjects.forEach((project, index) => {
        console.log(`    ${index + 1}. ${project.name} (ID: ${project.id})`)
        console.log(`       Description: ${project.description || 'No description'}`)
        console.log(`       Created: ${new Date(project.created_at).toLocaleString()}`)
      })
      
      console.log('  👥 Member Projects:', memberProjects.length)
      memberProjects.forEach((project, index) => {
        console.log(`    ${index + 1}. ${project.name} (ID: ${project.id})`)
        console.log(`       Team: ${project.team_name} (Role: ${project.role})`)
        console.log(`       Joined: ${new Date(project.joined_at).toLocaleString()}`)
        console.log(`       Owner: ${project.user_id}`)
      })
      
      console.log('  📋 Total Accessible Projects:', allProjectIds.length)
      console.log('  🔗 All Project IDs:', allProjectIds)
      
      console.log('🐛 BUGS BREAKDOWN:')
      console.log('  📊 Total Bugs:', bugs.length)
      if (bugs.length > 0) {
        const bugsByProject = bugs.reduce((acc, bug) => {
          const projectName = bug.project_name || 'Unknown Project'
          acc[projectName] = (acc[projectName] || 0) + 1
          return acc
        }, {})
        
        console.log('  📈 Bugs by Project:')
        Object.entries(bugsByProject).forEach(([project, count]) => {
          console.log(`    ${project}: ${count} bugs`)
        })
        
        const bugsByStatus = bugs.reduce((acc, bug) => {
          acc[bug.status] = (acc[bug.status] || 0) + 1
          return acc
        }, {})
        
        console.log('  📊 Bugs by Status:')
        Object.entries(bugsByStatus).forEach(([status, count]) => {
          console.log(`    ${status}: ${count} bugs`)
        })
        
        const bugsBySeverity = bugs.reduce((acc, bug) => {
          acc[bug.severity] = (acc[bug.severity] || 0) + 1
          return acc
        }, {})
        
        console.log('  ⚠️  Bugs by Severity:')
        Object.entries(bugsBySeverity).forEach(([severity, count]) => {
          console.log(`    ${severity}: ${count} bugs`)
        })
        
        console.log('  🔍 Sample Bugs (first 3):')
        bugs.slice(0, 3).forEach((bug, index) => {
          console.log(`    ${index + 1}. ${bug.title}`)
          console.log(`       Project: ${bug.project_name}`)
          console.log(`       Status: ${bug.status} | Severity: ${bug.severity}`)
          console.log(`       Assignee: ${bug.assignee || 'Unassigned'}`)
          console.log(`       Created: ${new Date(bug.created_at).toLocaleString()}`)
        })
      } else {
        console.log('  ℹ️  No bugs found across all projects')
      }
      
      console.log('✅ TODOS BREAKDOWN:')
      console.log('  📊 Total Todos:', todos.length)
      if (todos.length > 0) {
        const todosByProject = todos.reduce((acc, todo) => {
          const projectName = todo.project_name || 'Unknown Project'
          acc[projectName] = (acc[projectName] || 0) + 1
          return acc
        }, {})
        
        console.log('  📈 Todos by Project:')
        Object.entries(todosByProject).forEach(([project, count]) => {
          console.log(`    ${project}: ${count} todos`)
        })
        
        const todosByStatus = todos.reduce((acc, todo) => {
          acc[todo.status] = (acc[todo.status] || 0) + 1
          return acc
        }, {})
        
        console.log('  📊 Todos by Status:')
        Object.entries(todosByStatus).forEach(([status, count]) => {
          console.log(`    ${status}: ${count} todos`)
        })
        
        console.log('  🔍 Sample Todos (first 3):')
        todos.slice(0, 3).forEach((todo, index) => {
          console.log(`    ${index + 1}. ${todo.title}`)
          console.log(`       Project: ${todo.project_name}`)
          console.log(`       Status: ${todo.status} | Severity: ${todo.severity}`)
          console.log(`       Assignee: ${todo.assignee}`)
          console.log(`       Due: ${new Date(todo.due_date).toLocaleString()}`)
        })
      } else {
        console.log('  ℹ️  No todos found across all projects')
      }
      
      console.log('📈 METRICS SUMMARY:')
      console.log('  🏠 Owned Projects:', dashboardData.metrics.owned_projects_count)
      console.log('  👥 Member Projects:', dashboardData.metrics.member_projects_count)
      console.log('  📊 Total Projects:', dashboardData.metrics.total_projects)
      console.log('  🐛 Total Bugs:', dashboardData.metrics.total_bugs)
      console.log('  🔓 Open Bugs:', dashboardData.metrics.open_bugs)
      console.log('  🔍 Ready for QA Bugs:', dashboardData.metrics.ready_for_qa_bugs)
      console.log('  ⚠️  Critical Bugs:', dashboardData.metrics.critical_bugs)
      console.log('  ✅ Total Todos:', dashboardData.metrics.total_todos)
      console.log('  🔓 Open Todos:', dashboardData.metrics.open_todos)
      console.log('  🔄 In Progress Todos:', dashboardData.metrics.in_progress_todos)
      console.log('  🔍 Ready for QA Todos:', dashboardData.metrics.ready_for_qa_todos)
      console.log('  ✅ Done Todos:', dashboardData.metrics.done_todos)
      
      console.log('📊 CHART DATA:')
      console.log('  📈 Chart Data Points:', dashboardData.chart_data.length)
      if (dashboardData.chart_data.length > 0) {
        console.log('  📅 Recent Activity (last 5 days):')
        dashboardData.chart_data.slice(-5).forEach((point, index) => {
          console.log(`    ${point.date}: ${point.opened} opened, ${point.closed} closed`)
        })
      }
      
      console.log('📋 TABLE DATA:')
      console.log('  📊 Total Table Items:', dashboardData.table_data.length)
      if (dashboardData.table_data.length > 0) {
        const tableBySource = dashboardData.table_data.reduce((acc, item) => {
          acc[item.source] = (acc[item.source] || 0) + 1
          return acc
        }, {})
        console.log('  📈 Table Items by Source:')
        Object.entries(tableBySource).forEach(([source, count]) => {
          console.log(`    ${source}: ${count} items`)
        })
      }
      
      console.log('='.repeat(80))
      console.log('✅ COMPREHENSIVE DASHBOARD DATA LOGGING COMPLETE')
      console.log('='.repeat(80))
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
    let totalBugs, openBugs, readyForQABugs, criticalBugs, totalTodos, openTodos, inProgressTodos, readyForQATodos, doneTodos

    if (isAllProjects && comprehensiveDashboardData) {
      // Use metrics from comprehensive function
      totalBugs = comprehensiveDashboardData.metrics.total_bugs || 0
      openBugs = comprehensiveDashboardData.metrics.open_bugs || 0
      readyForQABugs = comprehensiveDashboardData.metrics.ready_for_qa_bugs || 0
      criticalBugs = comprehensiveDashboardData.metrics.critical_bugs || 0
      totalTodos = comprehensiveDashboardData.metrics.total_todos || 0
      openTodos = comprehensiveDashboardData.metrics.open_todos || 0
      inProgressTodos = comprehensiveDashboardData.metrics.in_progress_todos || 0
      readyForQATodos = comprehensiveDashboardData.metrics.ready_for_qa_todos || 0
      doneTodos = comprehensiveDashboardData.metrics.done_todos || 0
    } else {
      // Calculate metrics from individual queries (single project mode)
      totalBugs = bugs?.length || 0
      openBugs = bugs?.filter(bug => bug.status === 'Open').length || 0
      readyForQABugs = bugs?.filter(bug => bug.status === 'Ready for QA').length || 0
      criticalBugs = bugs?.filter(bug => bug.severity === 'CRITICAL' && bug.status === 'Open').length || 0
      totalTodos = todos?.length || 0
      openTodos = todos?.filter(todo => todo.status === 'OPEN').length || 0
      inProgressTodos = todos?.filter(todo => todo.status === 'IN_PROGRESS').length || 0
      readyForQATodos = todos?.filter(todo => todo.status === 'READY_FOR_QA').length || 0
      doneTodos = todos?.filter(todo => todo.status === 'DONE').length || 0
    }

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

    // Get chart data and table data
    let chartData, tableData

    if (isAllProjects && comprehensiveDashboardData) {
      // Use data from comprehensive function
      chartData = comprehensiveDashboardData.chart_data || []
      tableData = comprehensiveDashboardData.table_data || []
    } else {
      // Generate chart data for the last 14 days (single project mode)
    const fourteenDaysAgo = new Date()
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14)

    const recentBugs = bugs?.filter(bug => 
      new Date(bug.created_at) >= fourteenDaysAgo
    ) || []

      chartData = []
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
      tableData = [
        ...(bugs || []).map(bug => ({
          id: bug.id,
          header: bug.title,
          type: bug.severity,
          status: bug.status,
          target: bug.assignee,
          due_date: bug.created_at,
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
          due_date: todo.due_date,
          reviewer: 'Assign reviewer',
          source: 'todo',
          project: isAllProjects ? todo.projects?.name || 'Unknown Project' : undefined
        }))
      ]
    }

    const responseData = {
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
      accessibleProjectCount: isAllProjects ? accessibleProjectIds?.length || 0 : 1,
      // Add comprehensive data for debugging when in All Projects mode
      ...(isAllProjects && comprehensiveDashboardData ? {
        comprehensiveData: {
          projects: {
            owned: comprehensiveDashboardData.projects?.owned || [],
            member: comprehensiveDashboardData.projects?.member || [],
            total: (comprehensiveDashboardData.projects?.owned || []).length + (comprehensiveDashboardData.projects?.member || []).length
          },
          bugs: {
            total: bugs?.length || 0,
            byProject: bugs?.reduce((acc, bug) => {
              const projectName = bug.project_name || 'Unknown Project'
              acc[projectName] = (acc[projectName] || 0) + 1
              return acc
            }, {}) || {}
          },
          todos: {
            total: todos?.length || 0,
            byProject: todos?.reduce((acc, todo) => {
              const projectName = todo.project_name || 'Unknown Project'
              acc[projectName] = (acc[projectName] || 0) + 1
              return acc
            }, {}) || {}
          }
        }
      } : {})
    }

    return NextResponse.json(responseData)
  } catch (error) {
    console.error('Dashboard API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
