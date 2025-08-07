# Real Phone Number Setup Guide

## Step 1: Update the Seeder with Your Real Phone Number

1. **Open the file:** `speedgo-backend/database/seeders/RealPhoneSeeder.php`
2. **Replace** `YOUR_REAL_PHONE_NUMBER` with your actual phone number
3. **Example:** If your phone number is `+1234567890`, change it to:
   ```php
   'phone' => '1234567890', // Remove the + sign
   ```

## Step 2: Run the Seeder

```bash
cd speedgo-backend
php artisan db:seed --class=RealPhoneSeeder
```

## Step 3: Test the Apps

### Customer App:
- **Phone:** Your real phone number
- **Password:** `password`

### Driver App:
- **Phone:** Your real phone number  
- **Password:** `password`

## Step 4: Alternative - Direct Database Update

If you prefer to update directly in the database:

```sql
-- Update customer
UPDATE users SET phone = 'YOUR_REAL_PHONE_NUMBER' WHERE role = 'customer' LIMIT 1;

-- Update driver  
UPDATE users SET phone = 'YOUR_REAL_PHONE_NUMBER' WHERE role = 'driver' LIMIT 1;
```

## Step 5: Test the Flow

1. **Login as Customer** with your real phone number
2. **Book a ride** - select pickup and dropoff
3. **Login as Driver** with your real phone number (in a different app instance)
4. **Check Ride Requests** - you should see the ride you just booked
5. **Accept the ride** - it should move to "My Rides"

## Important Notes:

- ✅ **Use the same phone number** for both customer and driver testing
- ✅ **Remove the + sign** from phone numbers in the database
- ✅ **Keep the test drivers** (1111111111, 2222222222, 3333333333) for additional testing
- ✅ **The driver's location** will be updated automatically by GPS

## Troubleshooting:

- **If login fails:** Check that the phone number is exactly the same in both apps
- **If no rides appear:** Make sure you're logged in as a driver, not a customer
- **If location issues:** Grant location permissions to the driver app 