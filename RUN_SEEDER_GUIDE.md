# Run Seeder Guide

## ✅ Fixed Seeder

I've updated the `DatabaseSeeder.php` to clear existing users before creating new ones. This will prevent duplicate email/phone errors.

## 🚀 Run These Commands

### **Step 1: Navigate to Backend**
```bash
cd speedgo-backend
```

### **Step 2: Run the Seeder**
```bash
php artisan db:seed
```

### **Step 3: If You Get Errors, Try Fresh Database**
```bash
php artisan migrate:fresh --seed
```

## 📱 Login Credentials After Seeder

### **Customer App:**
- **Phone:** `81338640` (your real Lebanese number)
- **Password:** `password`

### **Driver App:**
- **Phone:** `81338641` (similar number for testing)
- **Password:** `password`

### **Additional Test Drivers:**
- **Driver Two:** `2222222222` + `password`
- **Driver Three:** `3333333333` + `password`

## 🧪 Test the Flow

1. **Login as Customer** with `81338640` + `password`
2. **Book a ride** - select pickup and dropoff
3. **Login as Driver** with `81338641` + `password`
4. **Check Ride Requests** - see your booked ride
5. **Accept the ride** - moves to "My Rides"

## ✅ What the Seeder Does

- ✅ **Clears existing users** with same emails/phones
- ✅ **Creates customer** with your real number `81338640`
- ✅ **Creates driver** with similar number `81338641`
- ✅ **Creates test drivers** for additional testing
- ✅ **Sets up GPS coordinates** for location tracking

Run the seeder and you'll have working Lebanese phone numbers! 