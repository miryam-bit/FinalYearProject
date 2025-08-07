# Using Existing Drivers from Seeders

## Your Existing Drivers

From your `DatabaseSeeder.php`, you have these drivers:

### Driver 1
- **Name**: Driver One
- **Email**: driver1@example.com
- **Phone**: 1111111111
- **Password**: password1

### Driver 2
- **Name**: Driver Two
- **Email**: driver2@example.com
- **Phone**: 2222222222
- **Password**: password2

### Driver 3
- **Name**: Driver Three
- **Email**: driver3@example.com
- **Phone**: 3333333333
- **Password**: password3

## Step 1: Run Seeders (if not already done)

```bash
cd speedgo-backend
php artisan db:seed
```

## Step 2: Check Current Driver Locations

```sql
-- Check all drivers and their current locations
SELECT id, name, email, phone, latitude, longitude, role 
FROM users 
WHERE role = 'driver';
```

## Step 3: Update Driver Locations for Testing

### Option A: Update by Email (Recommended)
```sql
-- Set Driver 1 close to pickup location
UPDATE users 
SET latitude = 40.7128, longitude = -74.0060
WHERE email = 'driver1@example.com' AND role = 'driver';

-- Set Driver 2 medium distance
UPDATE users 
SET latitude = 40.7200, longitude = -74.0100
WHERE email = 'driver2@example.com' AND role = 'driver';

-- Set Driver 3 far away (>3km)
UPDATE users 
SET latitude = 40.7500, longitude = -74.0500
WHERE email = 'driver3@example.com' AND role = 'driver';
```

### Option B: Update by ID
```sql
-- First check the IDs
SELECT id, name, email FROM users WHERE role = 'driver';

-- Then update by ID (replace 1, 2, 3 with actual IDs)
UPDATE users SET latitude = 40.7128, longitude = -74.0060 WHERE id = 1 AND role = 'driver';
UPDATE users SET latitude = 40.7200, longitude = -74.0100 WHERE id = 2 AND role = 'driver';
UPDATE users SET latitude = 40.7500, longitude = -74.0500 WHERE id = 3 AND role = 'driver';
```

## Step 4: Login as Different Drivers

### Method 1: Use Driver App
1. **Logout** from current driver
2. **Login** with different credentials:
   - Phone: `1111111111` / Password: `password1`
   - Phone: `2222222222` / Password: `password2`
   - Phone: `3333333333` / Password: `password3`

### Method 2: Use Postman
Create these requests in Postman:

#### Login Request 1
```
POST http://192.168.10.81:8000/api/auth/login
Content-Type: application/json

{
    "phone": "1111111111",
    "password": "password1"
}
```

#### Login Request 2
```
POST http://192.168.10.81:8000/api/auth/login
Content-Type: application/json

{
    "phone": "2222222222",
    "password": "password2"
}
```

#### Login Request 3
```
POST http://192.168.10.81:8000/api/auth/login
Content-Type: application/json

{
    "phone": "3333333333",
    "password": "password3"
}
```

## Step 5: Update Locations via API

After getting tokens from login, update locations:

### Update Driver 1 Location
```
POST http://192.168.10.81:8000/api/driver/update-location
Authorization: Bearer YOUR_DRIVER1_TOKEN
Content-Type: application/json

{
    "latitude": 40.7128,
    "longitude": -74.0060
}
```

### Update Driver 2 Location
```
POST http://192.168.10.81:8000/api/driver/update-location
Authorization: Bearer YOUR_DRIVER2_TOKEN
Content-Type: application/json

{
    "latitude": 40.7200,
    "longitude": -74.0100
}
```

### Update Driver 3 Location
```
POST http://192.168.10.81:8000/api/driver/update-location
Authorization: Bearer YOUR_DRIVER3_TOKEN
Content-Type: application/json

{
    "latitude": 40.7500,
    "longitude": -74.0500
}
```

## Step 6: Test Scenarios

### Scenario 1: All Drivers Close
```sql
UPDATE users SET latitude = 40.7128, longitude = -74.0060 WHERE email = 'driver1@example.com';
UPDATE users SET latitude = 40.7130, longitude = -74.0062 WHERE email = 'driver2@example.com';
UPDATE users SET latitude = 40.7125, longitude = -74.0058 WHERE email = 'driver3@example.com';
```

### Scenario 2: Mix of Close and Far
```sql
UPDATE users SET latitude = 40.7128, longitude = -74.0060 WHERE email = 'driver1@example.com'; -- Close
UPDATE users SET latitude = 40.7130, longitude = -74.0062 WHERE email = 'driver2@example.com'; -- Close
UPDATE users SET latitude = 40.7500, longitude = -74.0500 WHERE email = 'driver3@example.com'; -- Far
```

### Scenario 3: All Drivers Far
```sql
UPDATE users SET latitude = 40.7500, longitude = -74.0500 WHERE email = 'driver1@example.com';
UPDATE users SET latitude = 40.8000, longitude = -74.1000 WHERE email = 'driver2@example.com';
UPDATE users SET latitude = 40.8500, longitude = -74.1500 WHERE email = 'driver3@example.com';
```

## Step 7: Verify Drivers

```sql
-- Check all drivers with their locations
SELECT id, name, email, phone, latitude, longitude 
FROM users 
WHERE role = 'driver';
```

## Quick Test Workflow:

1. **Run seeders**: `php artisan db:seed`
2. **Update locations** in database (using SQL above)
3. **Login as different drivers** (using app or Postman)
4. **Test with customer app** - select pickup location and book ride
5. **You should see all 3 drivers** listed from closest to farthest

## Common Test Coordinates:
- **New York City**: 40.7128, -74.0060
- **Close to NY**: 40.7200, -74.0100
- **Medium distance**: 40.7300, -74.0200
- **Far from NY**: 40.7500, -74.0500
- **Very far**: 40.8000, -74.1000 