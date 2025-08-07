-- Update driver locations for testing
-- Replace the driver IDs with actual IDs from your database

-- Update Driver 1 to be close to customer (within 3km)
UPDATE users 
SET latitude = 40.7128, longitude = -74.0060  -- New York
WHERE id = 1 AND role = 'driver';

-- Update Driver 2 to be medium distance (2-3km)
UPDATE users 
SET latitude = 40.7200, longitude = -74.0100  -- Close to NY
WHERE id = 2 AND role = 'driver';

-- Update Driver 3 to be far away (more than 3km)
UPDATE users 
SET latitude = 40.7500, longitude = -74.0500  -- Far from NY
WHERE id = 3 AND role = 'driver';

-- Update Driver 4 to be very far (more than 3km)
UPDATE users 
SET latitude = 40.8000, longitude = -74.1000  -- Very far from NY
WHERE id = 4 AND role = 'driver';

-- Update Driver 5 to be in different city (more than 3km)
UPDATE users 
SET latitude = 40.8500, longitude = -74.1500  -- Different area
WHERE id = 5 AND role = 'driver';

-- Alternative: Update by email instead of ID
-- UPDATE users SET latitude = 40.7128, longitude = -74.0060 WHERE email = 'john.driver@test.com' AND role = 'driver';
-- UPDATE users SET latitude = 40.7200, longitude = -74.0100 WHERE email = 'sarah.driver@test.com' AND role = 'driver';
-- UPDATE users SET latitude = 40.7500, longitude = -74.0500 WHERE email = 'mike.driver@test.com' AND role = 'driver';
-- UPDATE users SET latitude = 40.8000, longitude = -74.1000 WHERE email = 'lisa.driver@test.com' AND role = 'driver';
-- UPDATE users SET latitude = 40.8500, longitude = -74.1500 WHERE email = 'ahmed.driver@test.com' AND role = 'driver'; 