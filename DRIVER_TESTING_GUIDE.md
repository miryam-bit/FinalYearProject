# Driver Testing Guide

## Step 1: Check Current Drivers
Run this SQL first to see what drivers exist:
```sql
SELECT id, name, email, phone, latitude, longitude, role 
FROM users 
WHERE role = 'driver';
```

## Step 2: Create Test Drivers (if needed)
If you don't have enough drivers, run the `create_test_drivers.sql` script to create 5 test drivers.

## Step 3: Login as Different Drivers

### Method 1: Use Driver App
1. **Logout** from current driver account
2. **Login** with different driver credentials:
   - Email: `john.driver@test.com` / Password: `password`
   - Email: `sarah.driver@test.com` / Password: `password`
   - Email: `mike.driver@test.com` / Password: `password`
   - Email: `lisa.driver@test.com` / Password: `password`
   - Email: `ahmed.driver@test.com` / Password: `password`

### Method 2: Use Postman/API Testing
Send POST request to: `http://192.168.10.81:8000/api/auth/login`
```json
{
    "email": "john.driver@test.com",
    "password": "password"
}
```

## Step 4: Update Driver Locations in Database

### Option A: Update by Driver ID
```sql
-- Update driver with ID 1 to be close to customer
UPDATE users 
SET latitude = 40.7128, longitude = -74.0060
WHERE id = 1 AND role = 'driver';

-- Update driver with ID 2 to be medium distance
UPDATE users 
SET latitude = 40.7200, longitude = -74.0100
WHERE id = 2 AND role = 'driver';

-- Update driver with ID 3 to be far away (>3km)
UPDATE users 
SET latitude = 40.7500, longitude = -74.0500
WHERE id = 3 AND role = 'driver';
```

### Option B: Update by Email
```sql
-- Update specific driver by email
UPDATE users 
SET latitude = 40.7128, longitude = -74.0060
WHERE email = 'john.driver@test.com' AND role = 'driver';
```

## Step 5: Test Customer App
1. Open customer app
2. Select pickup location (e.g., New York: 40.7128, -74.0060)
3. Tap "Book a Ride"
4. You should see all drivers listed from closest to farthest
5. Drivers ≥3km away will show "Too far away!" and be unselectable

## Test Scenarios

### Scenario 1: Multiple Close Drivers
```sql
-- Set 3 drivers close to pickup location
UPDATE users SET latitude = 40.7128, longitude = -74.0060 WHERE id = 1;
UPDATE users SET latitude = 40.7130, longitude = -74.0062 WHERE id = 2;
UPDATE users SET latitude = 40.7125, longitude = -74.0058 WHERE id = 3;
```

### Scenario 2: Mix of Close and Far Drivers
```sql
-- 2 close drivers, 3 far drivers
UPDATE users SET latitude = 40.7128, longitude = -74.0060 WHERE id = 1; -- Close
UPDATE users SET latitude = 40.7130, longitude = -74.0062 WHERE id = 2; -- Close
UPDATE users SET latitude = 40.7500, longitude = -74.0500 WHERE id = 3; -- Far
UPDATE users SET latitude = 40.8000, longitude = -74.1000 WHERE id = 4; -- Far
UPDATE users SET latitude = 40.8500, longitude = -74.1500 WHERE id = 5; -- Far
```

### Scenario 3: All Drivers Far Away
```sql
-- All drivers more than 3km away
UPDATE users SET latitude = 40.7500, longitude = -74.0500 WHERE id = 1;
UPDATE users SET latitude = 40.8000, longitude = -74.1000 WHERE id = 2;
UPDATE users SET latitude = 40.8500, longitude = -74.1500 WHERE id = 3;
UPDATE users SET latitude = 40.9000, longitude = -74.2000 WHERE id = 4;
UPDATE users SET latitude = 40.9500, longitude = -74.2500 WHERE id = 5;
```

## Common Coordinates for Testing
- **New York City**: 40.7128, -74.0060
- **London**: 51.5074, -0.1278
- **Tokyo**: 35.6762, 139.6503
- **Sydney**: -33.8688, 151.2093
- **Dubai**: 25.2048, 55.2708 