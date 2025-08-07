<?php

require_once 'vendor/autoload.php';

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;

echo "Updating database with phone number: 81338640\n";

// Update customer
$customer = User::where('role', 'customer')->first();
if ($customer) {
    $customer->phone = '81338640';
    $customer->save();
    echo "Updated customer: {$customer->name} - {$customer->phone}\n";
} else {
    echo "No customer found\n";
}

// Update driver
$driver = User::where('role', 'driver')->first();
if ($driver) {
    $driver->phone = '81338640';
    $driver->save();
    echo "Updated driver: {$driver->name} - {$driver->phone}\n";
} else {
    echo "No driver found\n";
}

echo "Database updated successfully!\n"; 