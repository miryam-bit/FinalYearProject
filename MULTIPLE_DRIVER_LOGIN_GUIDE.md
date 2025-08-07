# Multiple Driver Login Guide

## Method 1: Use Different Devices/Emulators (Recommended)

### Option A: Use Android Emulator + Physical Phone
1. **Keep current driver logged in on your phone**
2. **Open Android Studio** and start an emulator
3. **Install the driver app** on the emulator
4. **Login as different driver** on the emulator
5. Now you have 2 drivers logged in simultaneously

### Option B: Use Multiple Emulators
1. **Open Android Studio**
2. **Create multiple emulators** (AVD Manager)
3. **Install driver app** on each emulator
4. **Login as different drivers** on each emulator

### Option C: Use Different Physical Devices
1. **Keep current driver on your phone**
2. **Use another phone/tablet** with driver app
3. **Login as different driver** on the second device

## Method 2: Use Web Browser (API Testing)

### Step 1: Use Postman or Browser
1. **Keep driver app logged in on phone**
2. **Open Postman** or use browser developer tools
3. **Send login request** for different driver:

```
POST http://192.168.10.81:8000/api/auth/login
Content-Type: application/json

{
    "email": "john.driver@test.com",
    "password": "password"
}
```

### Step 2: Use the Token
- **Copy the token** from the response
- **Use this token** to make API calls as that driver
- **Update location** using the token

## Method 3: Use Multiple App Instances

### For Android (if supported):
1. **Enable "Multiple Windows"** in app settings
2. **Open driver app** in split screen
3. **Login as different drivers** in each instance

### For iOS:
1. **Use different Apple IDs** on same device
2. **Install app** under different accounts
3. **Login as different drivers** in each app instance

## Method 4: Use Database Direct Updates

### Keep Current Driver on Phone + Update Others in Database
1. **Keep your current driver logged in on phone**
2. **Update other drivers' locations directly in database:**

```sql
-- Update driver 2 location (without logging in)
UPDATE users 
SET latitude = 40.7200, longitude = -74.0100
WHERE email = 'sarah.driver@test.com' AND role = 'driver';

-- Update driver 3 location
UPDATE users 
SET latitude = 40.7500, longitude = -74.0500
WHERE email = 'mike.driver@test.com' AND role = 'driver';
```

3. **Test with customer app** - you'll see all drivers with their updated locations

## Method 5: Use Different App Versions

### Create Multiple App Builds:
1. **Modify app package name** for different builds
2. **Install multiple versions** of driver app
3. **Login as different drivers** in each app

## Quick Test Setup:

### Step 1: Create Test Drivers
```sql
-- Run this to create test drivers
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES 
('John Driver', 'john.driver@test.com', '+1234567890', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 40.7128, -74.0060, NOW(), NOW()),
('Sarah Driver', 'sarah.driver@test.com', '+1234567891', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 51.5074, -0.1278, NOW(), NOW()),
('Mike Driver', 'mike.driver@test.com', '+1234567892', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 35.6762, 139.6503, NOW(), NOW());
```

### Step 2: Set Different Locations
```sql
-- Set different locations for testing
UPDATE users SET latitude = 40.7128, longitude = -74.0060 WHERE email = 'john.driver@test.com';
UPDATE users SET latitude = 40.7200, longitude = -74.0100 WHERE email = 'sarah.driver@test.com';
UPDATE users SET latitude = 40.7500, longitude = -74.0500 WHERE email = 'mike.driver@test.com';
```

### Step 3: Login Credentials
- **Driver 1**: john.driver@test.com / password
- **Driver 2**: sarah.driver@test.com / password  
- **Driver 3**: mike.driver@test.com / password

## Recommended Approach:
**Use Method 1 (Emulator + Phone)** for the best testing experience:
1. Keep current driver on phone
2. Use emulator for second driver
3. Update locations in database for additional drivers
4. Test with customer app to see all drivers 