-- Fix login credentials for Lebanese testing
-- We need different phone numbers for customer and driver

-- First, let's see what we have
SELECT '=== CURRENT USERS ===' as info;
SELECT id, name, phone, role, email FROM users ORDER BY role, id;

-- Clean up any existing 81338640 users
DELETE FROM users WHERE phone = '81338640';

-- Create customer with 81338640 (your real number)
INSERT INTO users (name, email, phone, password, role, created_at, updated_at) 
VALUES ('Test Customer', 'customer@speedgo.com', '81338640', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer', NOW(), NOW());

-- Create driver with 81338641 (similar number for testing)
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('Test Driver', 'driver@speedgo.com', '81338641', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 0.0, 0.0, NOW(), NOW());

-- Show final result
SELECT '=== FINAL USERS ===' as info;
SELECT id, name, phone, role, email FROM users ORDER BY role, id;

-- Show login credentials
SELECT '=== LOGIN CREDENTIALS ===' as info;
SELECT 'Customer App:' as app, '81338640' as phone, 'password' as password UNION ALL
SELECT 'Driver App:' as app, '81338641' as phone, 'password' as password; 