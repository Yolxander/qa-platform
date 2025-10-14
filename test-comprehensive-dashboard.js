// Test script for the new comprehensive dashboard function
// This script can be run in the browser console to test the new functionality

async function testComprehensiveDashboard() {
  console.log('🧪 Testing Comprehensive Dashboard Function...');
  
  try {
    // Test the new comprehensive dashboard function directly
    console.log('1. Testing get_user_dashboard_data function...');
    const { data: dashboardData, error: dashboardError } = await supabase
      .rpc('get_user_dashboard_data', { user_profile_id: user.id });
    
    if (dashboardError) {
      console.error('❌ Error fetching comprehensive dashboard data:', dashboardError);
    } else {
      console.log('✅ Comprehensive dashboard data fetched successfully!');
      console.log('📊 Dashboard Data Summary:');
      console.log('  Projects:', dashboardData.projects);
      console.log('  Bugs Count:', dashboardData.bugs?.length || 0);
      console.log('  Todos Count:', dashboardData.todos?.length || 0);
      console.log('  Metrics:', dashboardData.metrics);
      console.log('  Chart Data Points:', dashboardData.chart_data?.length || 0);
      console.log('  Table Data Items:', dashboardData.table_data?.length || 0);
    }
    
    // Test the dashboard API endpoint with All Projects mode
    console.log('2. Testing Dashboard API with All Projects mode...');
    const response = await fetch('/api/dashboard?projectId=null', {
      headers: {
        'Authorization': `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}`
      }
    });
    
    if (response.ok) {
      const apiData = await response.json();
      console.log('✅ Dashboard API with All Projects mode successful!');
      console.log('📊 API Response Summary:');
      console.log('  Is All Projects:', apiData.isAllProjects);
      console.log('  Accessible Project Count:', apiData.accessibleProjectCount);
      console.log('  Total Bugs:', apiData.totalBugs);
      console.log('  Total Todos:', apiData.totalTodos);
      console.log('  Metrics:', apiData.metrics);
      console.log('  Chart Data Points:', apiData.chartData?.length || 0);
      console.log('  Table Data Items:', apiData.tableData?.length || 0);
      
      if (apiData.comprehensiveData) {
        console.log('📋 Comprehensive Data:');
        console.log('  Projects:', apiData.comprehensiveData.projects);
        console.log('  Bugs by Project:', apiData.comprehensiveData.bugs.byProject);
        console.log('  Todos by Project:', apiData.comprehensiveData.todos.byProject);
      }
    } else {
      console.error('❌ Dashboard API error:', response.status, response.statusText);
      const errorText = await response.text();
      console.error('Error details:', errorText);
    }
    
    console.log('🎉 Comprehensive dashboard test completed!');
    
  } catch (error) {
    console.error('❌ Error in test:', error);
  }
}

// Run the test if supabase and user are available
if (typeof supabase !== 'undefined' && typeof user !== 'undefined') {
  testComprehensiveDashboard();
} else {
  console.log('⚠️  Supabase or user not available. Make sure you are logged in.');
  console.log('💡 To run this test:');
  console.log('   1. Open the browser console');
  console.log('   2. Make sure you are logged in');
  console.log('   3. Run: testComprehensiveDashboard()');
}
