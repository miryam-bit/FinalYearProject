-- Fix phone numbers for Lebanese testing
-- First, let's see what we have
SELECT 'Current users:' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id;

-- Check if 81338640 already exists
SELECT 'Checking for 81338640:' as info;
SELECT id, name, phone, role FROM users WHERE phone = '81338640';

-- Update customer phone number (only if it's different)
UPDATE users 
SET phone = '81338640' 
WHERE role = 'customer' 
AND phone != '81338640'
LIMIT 1;

-- Update driver phone number (only if it's different)
UPDATE users 
SET phone = '81338640' 
WHERE role = 'driver' 
AND phone != '81338640'
LIMIT 1;

-- If 81338640 already exists for one role, update the other role to a different number
-- For example, if customer already has 81338640, give driver 81338641
UPDATE users 
SET phone = '81338641' 
WHERE role = 'driver' 
AND phone = '81338640'
AND EXISTS (SELECT 1 FROM users WHERE role = 'customer' AND phone = '81338640');

-- Show final result
SELECT 'Final users:' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id; 