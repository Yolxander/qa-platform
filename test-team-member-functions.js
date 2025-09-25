// Test script for team member functions
// This script can be run in the browser console to test the new functionality

async function testTeamMemberFunctions() {
  console.log('Testing team member functions...');
  
  try {
    // Test 1: Get member teams
    console.log('1. Testing get_member_teams function...');
    const { data: memberTeams, error: memberTeamsError } = await supabase
      .rpc('get_member_teams', { user_profile_id: user.id });
    
    if (memberTeamsError) {
      console.error('Error fetching member teams:', memberTeamsError);
    } else {
      console.log('Member teams found:', memberTeams?.length || 0);
      console.log('Member teams data:', memberTeams);
    }
    
    // Test 2: Get member projects
    console.log('2. Testing get_member_projects function...');
    const { data: memberProjects, error: memberProjectsError } = await supabase
      .rpc('get_member_projects', { user_profile_id: user.id });
    
    if (memberProjectsError) {
      console.error('Error fetching member projects:', memberProjectsError);
    } else {
      console.log('Member projects found:', memberProjects?.length || 0);
      console.log('Member projects data:', memberProjects);
    }
    
    // Test 3: Test with a specific team (if any exist)
    if (memberTeams && memberTeams.length > 0) {
      const firstTeam = memberTeams[0];
      console.log('3. Testing get_team_members function...');
      const { data: teamMembers, error: teamMembersError } = await supabase
        .rpc('get_team_members', { team_uuid: firstTeam.team_id });
      
      if (teamMembersError) {
        console.error('Error fetching team members:', teamMembersError);
      } else {
        console.log('Team members found:', teamMembers?.length || 0);
        console.log('Team members data:', teamMembers);
      }
    }
    
    console.log('Team member functions test completed!');
    
  } catch (error) {
    console.error('Error in test:', error);
  }
}

// Run the test if supabase and user are available
if (typeof supabase !== 'undefined' && typeof user !== 'undefined') {
  testTeamMemberFunctions();
} else {
  console.log('Supabase or user not available. Make sure you are logged in.');
}
