// Simple test script to verify the simplified invitation system
// Run this with: node test-simple-setup.js

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY environment variables')
  process.exit(1)
}

async function testSimpleSetup() {
  console.log('Testing simplified invitation system...')
  
  try {
    // Test 1: Check if invitations API endpoint is accessible
    console.log('\n1. Testing GET /api/invitations...')
    const response = await fetch('http://localhost:3000/api/invitations')
    console.log('Status:', response.status)
    
    if (response.status === 401) {
      console.log('✅ API endpoint exists and requires authentication (expected)')
    } else if (response.status === 500) {
      const errorText = await response.text()
      if (errorText.includes('team_invitations table does not exist')) {
        console.log('❌ team_invitations table missing. Run simple-invitations-setup.sql')
      } else {
        console.log('⚠️  API returns 500 for different reason:', errorText)
      }
    } else if (response.status === 200) {
      const data = await response.json()
      console.log('✅ API endpoint working, invitations:', data.invitations?.length || 0)
    } else {
      console.log('❌ Unexpected status:', response.status)
    }
    
    // Test 2: Check database table
    console.log('\n2. Testing database table...')
    const { createClient } = await import('@supabase/supabase-js')
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    
    const { data, error } = await supabase
      .from('team_invitations')
      .select('*')
      .limit(1)
    
    if (error) {
      if (error.message.includes('relation "team_invitations" does not exist')) {
        console.log('❌ team_invitations table does not exist')
        console.log('   Run: cat db-schemas/functions/simple-invitations-setup.sql')
      } else if (error.message.includes('permission denied') || error.message.includes('JWT')) {
        console.log('✅ team_invitations table exists but requires authentication (expected)')
      } else {
        console.log('❌ Database error:', error.message)
      }
    } else {
      console.log('✅ team_invitations table accessible')
    }
    
    console.log('\n✅ Tests completed!')
    console.log('\n📋 Next steps:')
    console.log('1. If table is missing, run: cat db-schemas/functions/simple-invitations-setup.sql')
    console.log('2. Start your Next.js app: npm run dev')
    console.log('3. Log in and test the invitation notifications')
    
  } catch (error) {
    console.error('❌ Test failed:', error.message)
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Make sure your Next.js app is running: npm run dev')
    }
  }
}

testSimpleSetup()
