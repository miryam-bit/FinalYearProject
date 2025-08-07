-- Check current users in the database
SELECT '=== CURRENT USERS ===' as info;
SELECT id, name, phone, role, email FROM users ORDER BY role, id;

-- Check if 81338640 exists
SELECT '=== USERS WITH PHONE 81338640 ===' as info;
SELECT id, name, phone, role, email FROM users WHERE phone = '81338640';

-- Check what passwords are being used
SELECT '=== PASSWORD HASHES ===' as info;
SELECT id, name, phone, role, LEFT(password, 20) as password_start FROM users ORDER BY role, id;

-- Fix: Update or create user with 81338640 and correct password
-- First, delete any existing user with this phone number
DELETE FROM users WHERE phone = '81338640';

-- Create fresh user with 81338640 and password 'password'
INSERT INTO users (name, email, phone, password, role, created_at, updated_at) 
VALUES ('Test User', 'test@speedgo.com', '81338640', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer', NOW(), NOW());

-- Create driver user with 81338640 and password 'password'
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('Test Driver', 'driver@speedgo.com', '81338640', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 0.0, 0.0, NOW(), NOW());

-- Show final result
SELECT '=== FINAL USERS ===' as info;
SELECT id, name, phone, role, email FROM users ORDER BY role, id;

-- Show login credentials
SELECT '=== LOGIN CREDENTIALS ===' as info;
SELECT 'Phone: 81338640' as credential, 'Password: password' as value UNION ALL
SELECT 'Role: Customer' as credential, 'Role: Driver' as value; 