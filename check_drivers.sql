-- Check all drivers in the database
SELECT id, name, email, phone, latitude, longitude, role, created_at 
FROM users 
WHERE role = 'driver';

-- Count total drivers
SELECT COUNT(*) as total_drivers 
FROM users 
WHERE role = 'driver';

-- Check drivers with location data
SELECT id, name, email, phone, latitude, longitude 
FROM users 
WHERE role = 'driver' AND latitude IS NOT NULL AND longitude IS NOT NULL;

-- Check drivers without location data
SELECT id, name, email, phone, latitude, longitude 
FROM users 
WHERE role = 'driver' AND (latitude IS NULL OR longitude IS NULL); 