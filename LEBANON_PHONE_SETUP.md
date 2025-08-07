# Lebanese Phone Number Setup Guide

## ✅ Updated Seeders

I've updated the `DatabaseSeeder.php` with your real Lebanese phone number:

### **Customer:**
- **Phone:** `81338640` (your real number)
- **Password:** `password`
- **Email:** `customer@speedgo.com`

### **Driver:**
- **Phone:** `81338641` (similar number for testing)
- **Password:** `password`
- **Email:** `driver@speedgo.com`

### **Additional Test Drivers:**
- **Driver Two:** `2222222222` + `password`
- **Driver Three:** `3333333333` + `password`

## 🚀 Run the Seeder

### **Option 1: Fresh Database**
```bash
cd speedgo-backend
php artisan migrate:fresh --seed
```

### **Option 2: Just Run Seeder**
```bash
cd speedgo-backend
php artisan db:seed
```

### **Option 3: Clear and Seed**
```bash
cd speedgo-backend
php artisan migrate:refresh --seed
```

## 📱 Test the Apps

### **Customer App:**
- **Phone:** `81338640`
- **Password:** `password`

### **Driver App:**
- **Phone:** `81338641`
- **Password:** `password`

## 🧪 Test the Complete Flow

1. **Login as Customer** with `81338640` + `password`
2. **Book a ride** - select pickup and dropoff locations
3. **Login as Driver** with `81338641` + `password`
4. **Check Ride Requests** - you should see your booked ride
5. **Accept the ride** - it moves to "My Rides"

## ✅ Benefits

- ✅ **Your real phone number** for customer testing
- ✅ **Similar number** for driver testing
- ✅ **Real GPS location** from your Lebanese phone
- ✅ **Real testing environment** - exactly like real users
- ✅ **Ready for notifications** when we add them

## 🔧 If You Get Errors

If you get duplicate phone number errors:

1. **Clear the database first:**
   ```bash
   php artisan migrate:fresh
   ```

2. **Then run the seeder:**
   ```bash
   php artisan db:seed
   ```

This will give you a clean database with your Lebanese phone numbers! 