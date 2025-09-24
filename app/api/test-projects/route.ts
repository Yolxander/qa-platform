import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET() {
  try {
    if (!supabase) {
      return NextResponse.json({ 
        error: 'Database not configured',
        message: 'Please check your .env.local file' 
      }, { status: 500 })
    }

    // Test if projects table exists by trying to select from it
    const { data, error } = await supabase
      .from('projects')
      .select('count')
      .limit(1)

    if (error) {
      return NextResponse.json({
        error: 'Projects table does not exist',
        details: error.message,
        suggestion: 'Please run the SQL schema from projects-schema.sql'
      }, { status: 500 })
    }

    return NextResponse.json({
      success: true,
      message: 'Projects table exists and is accessible'
    })
  } catch (error) {
    console.error('Error testing projects table:', error)
    return NextResponse.json({ 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}
