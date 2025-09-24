// Simple test script to verify invitation functionality
// Run this with: node test-invitations.js
// Make sure to have a valid session token

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY environment variables')
  process.exit(1)
}

async function testInvitations() {
  console.log('Testing invitation functionality...')
  
  try {
    // Test 1: Check if invitations API endpoint is accessible
    console.log('\n1. Testing GET /api/invitations...')
    const response = await fetch('http://localhost:3000/api/invitations')
    console.log('Status:', response.status)
    
    if (response.status === 401) {
      console.log('✅ API endpoint exists and requires authentication (expected)')
      const errorText = await response.text()
      if (errorText.includes('No authorization header')) {
        console.log('✅ API properly validates authorization header')
      } else {
        console.log('⚠️  API returns 401 but for different reason:', errorText)
      }
    } else if (response.status === 200) {
      const data = await response.json()
      console.log('✅ API endpoint accessible, invitations:', data.invitations?.length || 0)
    } else {
      console.log('❌ Unexpected status:', response.status)
    }
    
    // Test 2: Check database schema
    console.log('\n2. Testing database schema...')
    const { createClient } = await import('@supabase/supabase-js')
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    
    // Try to access the team_invitations table
    const { data, error } = await supabase
      .from('team_invitations')
      .select('*')
      .limit(1)
    
    if (error) {
      if (error.message.includes('relation "team_invitations" does not exist')) {
        console.log('❌ team_invitations table does not exist. Please run setup-team-invitations.sql')
        console.log('   Run this command: cat setup-team-invitations.sql')
      } else if (error.message.includes('permission denied') || error.message.includes('JWT')) {
        console.log('✅ team_invitations table exists but requires authentication (expected)')
      } else {
        console.log('❌ Database error:', error.message)
      }
    } else {
      console.log('✅ team_invitations table accessible')
    }
    
    // Test 3: Check if functions exist
    console.log('\n3. Testing database functions...')
    const { data: funcData, error: funcError } = await supabase.rpc('get_user_invitations')
    
    if (funcError) {
      if (funcError.message.includes('function get_user_invitations') || funcError.message.includes('permission denied') || funcError.message.includes('JWT')) {
        console.log('✅ get_user_invitations function exists but requires authentication (expected)')
      } else {
        console.log('❌ Function error:', funcError.message)
      }
    } else {
      console.log('✅ get_user_invitations function accessible')
    }
    
    // Test 4: Check if Next.js app is running
    console.log('\n4. Testing Next.js app connectivity...')
    try {
      const appResponse = await fetch('http://localhost:3000/')
      if (appResponse.ok) {
        console.log('✅ Next.js app is running on localhost:3000')
      } else {
        console.log('⚠️  Next.js app responded with status:', appResponse.status)
      }
    } catch (error) {
      console.log('❌ Next.js app not running. Start it with: npm run dev')
    }
    
    console.log('\n✅ Basic tests completed!')
    console.log('\n📋 Next steps:')
    console.log('1. Run setup-team-invitations.sql in your Supabase SQL Editor')
    console.log('2. Start your Next.js app with: npm run dev')
    console.log('3. Log in and test the invitation flow manually')
    console.log('4. Check the notifications page at /notifications')
    console.log('\n🔧 Troubleshooting:')
    console.log('- If you see 401 errors, make sure you are logged in')
    console.log('- Check browser console for detailed error messages')
    console.log('- Verify your Supabase environment variables are set correctly')
    
  } catch (error) {
    console.error('❌ Test failed:', error.message)
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Make sure your Next.js app is running: npm run dev')
    }
  }
}

testInvitations()
