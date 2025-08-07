-- Update database with Lebanese phone number: 81338640

-- Update customer account
UPDATE users 
SET phone = '81338640' 
WHERE role = 'customer' 
LIMIT 1;

-- Update driver account  
UPDATE users 
SET phone = '81338640' 
WHERE role = 'driver' 
LIMIT 1;

-- Show the updated users
SELECT id, name, phone, role FROM users WHERE phone = '81338640';

-- Show all users for verification
SELECT id, name, phone, role FROM users ORDER BY role; 