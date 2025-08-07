-- SQL Script to Update Driver Location for Testing
-- Run this in your database to manually set a driver's location

-- First, view all drivers to see their IDs
SELECT id, name, email, phone, latitude, longitude, role 
FROM users 
WHERE role = 'driver';

-- Then update a specific driver's location (replace 1 with the actual driver ID)
UPDATE users 
SET latitude = 40.7128, longitude = -74.0060  -- New York City coordinates
WHERE id = 1 AND role = 'driver';

-- Or update by email
UPDATE users 
SET latitude = 40.7128, longitude = -74.0060
WHERE email = 'driver@example.com' AND role = 'driver';

-- Or update by phone
UPDATE users 
SET latitude = 40.7128, longitude = -74.0060
WHERE phone = '+1234567890' AND role = 'driver';

-- Common test coordinates:
-- New York City: latitude = 40.7128, longitude = -74.0060
-- London: latitude = 51.5074, longitude = -0.1278
-- Tokyo: latitude = 35.6762, longitude = 139.6503
-- Sydney: latitude = -33.8688, longitude = 151.2093
-- Dubai: latitude = 25.2048, longitude = 55.2708
-- Paris: latitude = 48.8566, longitude = 2.3522
-- Berlin: latitude = 52.5200, longitude = 13.4050
-- Moscow: latitude = 55.7558, longitude = 37.6176
-- Beijing: latitude = 39.9042, longitude = 116.4074
-- Mumbai: latitude = 19.0760, longitude = 72.8777 