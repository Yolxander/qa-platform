import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET() {
  try {
    if (!supabase) {
      return NextResponse.json({ error: 'Database not configured' }, { status: 500 })
    }

    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data, error } = await supabase
      .from('projects')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching projects:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in GET /api/projects:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    if (!supabase) {
      return NextResponse.json({ error: 'Database not configured' }, { status: 500 })
    }

    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const { name, description } = body

    if (!name || name.trim() === '') {
      return NextResponse.json({ error: 'Project name is required' }, { status: 400 })
    }

    const { data, error } = await supabase
      .from('projects')
      .insert({
        name: name.trim(),
        description: description?.trim() || null,
        user_id: user.id
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating project:', error)
      console.error('Error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint
      })
      
      // Provide more specific error messages
      let errorMessage = error.message
      if (error.code === 'PGRST116') {
        errorMessage = 'Projects table does not exist. Please run the database schema setup.'
      } else if (error.code === '42501') {
        errorMessage = 'Permission denied. Please check your database permissions.'
      } else if (error.message.includes('relation "projects" does not exist')) {
        errorMessage = 'Projects table not found. Please run the complete database schema.'
      }
      
      return NextResponse.json({ error: errorMessage }, { status: 400 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in POST /api/projects:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
