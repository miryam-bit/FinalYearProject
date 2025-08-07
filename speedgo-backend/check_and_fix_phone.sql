-- Check current database state
SELECT '=== CURRENT USERS ===' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id;

SELECT '=== USERS WITH PHONE 81338640 ===' as info;
SELECT id, name, phone, role FROM users WHERE phone = '81338640';

-- Solution: Update the existing user with phone 81338640 to be a driver
-- and create a new customer with a different number, or vice versa

-- Option 1: Make the existing 81338640 user a driver, create new customer
UPDATE users 
SET role = 'driver', 
    name = 'Test Driver',
    email = 'driver@speedgo.com',
    latitude = 0.0,
    longitude = 0.0
WHERE phone = '81338640';

-- Create a new customer with a different number
INSERT INTO users (name, email, phone, password, role, created_at, updated_at) 
VALUES ('Test Customer', 'customer@speedgo.com', '81338641', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer', NOW(), NOW());

-- Show final result
SELECT '=== FINAL USERS ===' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id; 