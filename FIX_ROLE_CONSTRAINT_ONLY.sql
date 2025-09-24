-- =============================================
-- FIX ROLE CONSTRAINT ONLY - NO DUPLICATE POLICIES
-- =============================================
-- This script ONLY fixes the role constraint error
-- It won't create duplicate policies or tables

-- =============================================
-- 1. FIX THE ROLE CONSTRAINT
-- =============================================

-- Update the check constraint to allow 'owner' role
ALTER TABLE public.team_members 
DROP CONSTRAINT IF EXISTS team_members_role_check;

-- Create new constraint that allows 'owner' role
ALTER TABLE public.team_members 
ADD CONSTRAINT team_members_role_check 
CHECK (role IN ('developer', 'tester', 'guest', 'owner'));

-- =============================================
-- 2. VERIFICATION
-- =============================================

-- Check the constraint was updated
SELECT constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE constraint_name = 'team_members_role_check';

-- Show that the fix worked
SELECT 'Role constraint updated successfully! Now allows: developer, tester, guest, owner' as status;

-- =============================================
-- FIX COMPLETE!
-- =============================================
-- After running this script:
-- 1. The role constraint will allow 'owner' role
-- 2. Project creation should work without team_members errors
-- 3. Try creating a project again - should work now!
