# Postman Guide for Multiple Driver Testing

## Step 1: Download and Install Postman
1. Go to https://www.postman.com/downloads/
2. Download and install Postman for your operating system
3. Create a free account or skip (you can use without account)

## Step 2: Create a New Collection
1. **Open Postman**
2. **Click "New"** → **"Collection"**
3. **Name it**: "SpeedGo Driver Testing"
4. **Click "Create"**

## Step 3: Login as Different Drivers

### Request 1: Login as Driver 1
1. **Right-click on your collection** → **"Add Request"**
2. **Name it**: "Login - Driver One"
3. **Method**: POST
4. **URL**: `http://192.168.10.81:8000/api/auth/login`
5. **Headers tab**:
   - Key: `Content-Type`
   - Value: `application/json`
6. **Body tab** → **Select "raw"** → **Select "JSON"**
7. **Enter this JSON**:
```json
{
    "phone": "1111111111",
    "password": "password1"
}
```
8. **Click "Send"**
9. **Copy the token** from the response (look for `"token": "..."`)

### Request 2: Login as Driver 2
1. **Right-click on your collection** → **"Add Request"**
2. **Name it**: "Login - Driver Two"
3. **Method**: POST
4. **URL**: `http://192.168.10.81:8000/api/auth/login`
5. **Headers tab**:
   - Key: `Content-Type`
   - Value: `application/json`
6. **Body tab** → **Select "raw"** → **Select "JSON"**
7. **Enter this JSON**:
```json
{
    "phone": "2222222222",
    "password": "password2"
}
```
8. **Click "Send"**
9. **Copy the token** from the response

### Request 3: Login as Driver 3
1. **Right-click on your collection** → **"Add Request"**
2. **Name it**: "Login - Driver Three"
3. **Method**: POST
4. **URL**: `http://192.168.10.81:8000/api/auth/login`
5. **Headers tab**:
   - Key: `Content-Type`
   - Value: `application/json`
6. **Body tab** → **Select "raw"** → **Select "JSON"**
7. **Enter this JSON**:
```json
{
    "phone": "3333333333",
    "password": "password3"
}
```
8. **Click "Send"**
9. **Copy the token** from the response

## Step 4: Update Driver Locations

### Request 4: Update John Driver Location
1. **Right-click on your collection** → **"Add Request"**
2. **Name it**: "Update John Location"
3. **Method**: POST
4. **URL**: `http://192.168.10.81:8000/api/driver/update-location`
5. **Headers tab**:
   - Key: `Content-Type`
   - Value: `application/json`
   - Key: `Authorization`
   - Value: `Bearer YOUR_JOHN_TOKEN_HERE` (replace with John's token)
6. **Body tab** → **Select "raw"** → **Select "JSON"**
7. **Enter this JSON**:
```json
{
    "latitude": 40.7128,
    "longitude": -74.0060
}
```
8. **Click "Send"**

### Request 5: Update Sarah Driver Location
1. **Right-click on your collection** → **"Add Request"**
2. **Name it**: "Update Sarah Location"
3. **Method**: POST
4. **URL**: `http://192.168.10.81:8000/api/driver/update-location`
5. **Headers tab**:
   - Key: `Content-Type`
   - Value: `application/json`
   - Key: `Authorization`
   - Value: `Bearer YOUR_SARAH_TOKEN_HERE` (replace with Sarah's token)
6. **Body tab** → **Select "raw"** → **Select "JSON"**
7. **Enter this JSON**:
```json
{
    "latitude": 40.7200,
    "longitude": -74.0100
}
```
8. **Click "Send"**

### Request 6: Update Mike Driver Location
1. **Right-click on your collection** → **"Add Request"**
2. **Name it**: "Update Mike Location"
3. **Method**: POST
4. **URL**: `http://192.168.10.81:8000/api/driver/update-location`
5. **Headers tab**:
   - Key: `Content-Type`
   - Value: `application/json`
   - Key: `Authorization`
   - Value: `Bearer YOUR_MIKE_TOKEN_HERE` (replace with Mike's token)
6. **Body tab** → **Select "raw"** → **Select "JSON"**
7. **Enter this JSON**:
```json
{
    "latitude": 40.7500,
    "longitude": -74.0500
}
```
8. **Click "Send"**

## Step 5: Check All Drivers

### Request 7: View All Drivers
1. **Right-click on your collection** → **"Add Request"**
2. **Name it**: "Get All Drivers"
3. **Method**: GET
4. **URL**: `http://192.168.10.81:8000/api/drivers`
5. **Click "Send"**
6. **You should see all drivers with their locations**

## Step 6: Test Different Scenarios

### Scenario 1: All Drivers Close
Update all drivers to be close to pickup location:
```json
// John - Very close
{"latitude": 40.7128, "longitude": -74.0060}

// Sarah - Close
{"latitude": 40.7130, "longitude": -74.0062}

// Mike - Close
{"latitude": 40.7125, "longitude": -74.0058}
```

### Scenario 2: Mix of Close and Far
```json
// John - Close
{"latitude": 40.7128, "longitude": -74.0060}

// Sarah - Close
{"latitude": 40.7130, "longitude": -74.0062}

// Mike - Far (>3km)
{"latitude": 40.7500, "longitude": -74.0500}
```

### Scenario 3: All Drivers Far
```json
// John - Far
{"latitude": 40.7500, "longitude": -74.0500}

// Sarah - Far
{"latitude": 40.8000, "longitude": -74.1000}

// Mike - Far
{"latitude": 40.8500, "longitude": -74.1500}
```

## Step 7: Save and Organize

### Create Environment Variables
1. **Click the gear icon** (top right)
2. **Click "Add"** to create new environment
3. **Name it**: "SpeedGo Testing"
4. **Add variables**:
   - `base_url`: `http://192.168.10.81:8000`
   - `john_token`: (paste John's token)
   - `sarah_token`: (paste Sarah's token)
   - `mike_token`: (paste Mike's token)

### Use Variables in Requests
- **URL**: `{{base_url}}/api/auth/login`
- **Authorization**: `Bearer {{john_token}}`

## Quick Test Workflow:

1. **Run "Login - John Driver"** → Copy token
2. **Run "Login - Sarah Driver"** → Copy token  
3. **Run "Login - Mike Driver"** → Copy token
4. **Update tokens** in environment variables
5. **Run "Update John Location"** with close coordinates
6. **Run "Update Sarah Location"** with medium coordinates
7. **Run "Update Mike Location"** with far coordinates
8. **Run "Get All Drivers"** to verify
9. **Test with customer app** to see driver selection

## Common Coordinates for Testing:
- **New York City**: 40.7128, -74.0060
- **Close to NY**: 40.7200, -74.0100
- **Medium distance**: 40.7300, -74.0200
- **Far from NY**: 40.7500, -74.0500
- **Very far**: 40.8000, -74.1000 