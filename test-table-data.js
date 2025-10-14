// Test script to verify table data structure
// Run this in the browser console to test the data structure

async function testTableData() {
  console.log('🧪 Testing Table Data Structure...');
  
  try {
    // Test the dashboard API endpoint
    const response = await fetch('/api/dashboard?projectId=null', {
      headers: {
        'Authorization': `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}`
      }
    });
    
    if (response.ok) {
      const data = await response.json();
      console.log('✅ Dashboard API Response:');
      console.log('  Is All Projects:', data.isAllProjects);
      console.log('  Accessible Project Count:', data.accessibleProjectCount);
      console.log('  Table Data Length:', data.tableData?.length || 0);
      
      if (data.tableData && data.tableData.length > 0) {
        console.log('📊 Sample Table Data (first 3 items):');
        data.tableData.slice(0, 3).forEach((item, index) => {
          console.log(`  ${index + 1}. ${item.header}`);
          console.log(`     ID: ${item.id}`);
          console.log(`     Type: ${item.type}`);
          console.log(`     Status: ${item.status}`);
          console.log(`     Target: ${item.target}`);
          console.log(`     Due Date: ${item.due_date}`);
          console.log(`     Reviewer: ${item.reviewer}`);
          console.log(`     Source: ${item.source}`);
          console.log(`     Project: ${item.project || 'N/A'}`);
          console.log('     ---');
        });
        
        // Validate data structure
        const requiredFields = ['id', 'header', 'type', 'status', 'target', 'due_date', 'reviewer', 'source'];
        const missingFields = requiredFields.filter(field => !(field in data.tableData[0]));
        
        if (missingFields.length === 0) {
          console.log('✅ All required fields present in table data');
        } else {
          console.log('❌ Missing fields in table data:', missingFields);
        }
      } else {
        console.log('⚠️  No table data found');
        console.log('  This could mean:');
        console.log('    1. No bugs or todos exist');
        console.log('    2. No projects accessible to user');
        console.log('    3. Database migration not applied');
        console.log('    4. RPC function not working correctly');
      }
    } else {
      console.error('❌ Dashboard API error:', response.status, response.statusText);
      const errorText = await response.text();
      console.error('Error details:', errorText);
    }
    
  } catch (error) {
    console.error('❌ Error in test:', error);
  }
}

// Run the test if supabase is available
if (typeof supabase !== 'undefined') {
  testTableData();
} else {
  console.log('⚠️  Supabase not available. Make sure you are logged in.');
  console.log('💡 To run this test:');
  console.log('   1. Open the browser console');
  console.log('   2. Make sure you are logged in');
  console.log('   3. Run: testTableData()');
}
