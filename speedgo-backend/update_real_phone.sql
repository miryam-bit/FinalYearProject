-- Update database with your real phone number
-- Replace 'YOUR_REAL_PHONE_NUMBER' with your actual phone number (without + sign)

-- Update customer account
UPDATE users 
SET phone = 'YOUR_REAL_PHONE_NUMBER' 
WHERE role = 'customer' 
LIMIT 1;

-- Update driver account  
UPDATE users 
SET phone = 'YOUR_REAL_PHONE_NUMBER' 
WHERE role = 'driver' 
LIMIT 1;

-- Show the updated users
SELECT id, name, phone, role FROM users WHERE phone = 'YOUR_REAL_PHONE_NUMBER'; 