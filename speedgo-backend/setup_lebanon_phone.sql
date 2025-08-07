-- Setup Lebanese phone number 81338640 for testing
-- This script will handle the duplicate issue properly

-- First, let's see current users
SELECT 'Current users before update:' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id;

-- Delete any existing users with phone 81338640 to avoid conflicts
DELETE FROM users WHERE phone = '81338640';

-- Create fresh customer with your phone number
INSERT INTO users (name, email, phone, password, role, created_at, updated_at) 
VALUES ('Test Customer', 'customer@speedgo.com', '81338640', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer', NOW(), NOW());

-- Create fresh driver with your phone number  
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('Test Driver', 'driver@speedgo.com', '81338640', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 0.0, 0.0, NOW(), NOW());

-- Show final result
SELECT 'Final users after update:' as info;
SELECT id, name, phone, role FROM users ORDER BY role, id;

-- Show users with your phone number
SELECT 'Users with phone 81338640:' as info;
SELECT id, name, phone, role FROM users WHERE phone = '81338640'; 