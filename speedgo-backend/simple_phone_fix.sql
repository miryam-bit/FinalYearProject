-- Simple fix: Use your real phone number for driver, different number for customer
-- This way you can test both apps on the same phone

-- First, let's see what we have
SELECT 'Current users:' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id;

-- Update existing 81338640 user to be a driver
UPDATE users 
SET role = 'driver', 
    name = 'Test Driver',
    email = 'driver@speedgo.com',
    latitude = 0.0,
    longitude = 0.0
WHERE phone = '81338640';

-- Create a new customer with a different number (so you can test both roles)
INSERT INTO users (name, email, phone, password, role, created_at, updated_at) 
VALUES ('Test Customer', 'customer@speedgo.com', '81338641', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer', NOW(), NOW());

-- Show final result
SELECT 'Final users:' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id;

-- Show login credentials
SELECT '=== LOGIN CREDENTIALS ===' as info;
SELECT 'Customer App:' as app, '81338641' as phone, 'password' as password UNION ALL
SELECT 'Driver App:' as app, '81338640' as phone, 'password' as password; 