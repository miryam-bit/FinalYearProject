<?php

namespace Database\Seeders;

use Illuminate\Support\Facades\Hash;
use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        // Clear existing users to avoid conflicts
        User::where('email', 'like', '%@speedgo.com')->delete();
        User::where('phone', 'in', ['81338640', '81338641', '81338642', '81338643'])->delete();

        User::factory()->create([
            'name' => 'Test Customer',
            'email' => 'customer@speedgo.com',
            'phone' => '81338640', // Your real Lebanese phone number
            'password' => Hash::make('password'),
            'role' => 'customer',
        ]);
        User::create([
            'name' => 'Test Driver',
            'email' => 'driver@speedgo.com',
            'phone' => '81338641', // Similar number for driver testing
            'password' => Hash::make('password'),
            'role' => 'driver',
            'latitude' => 0.0,
            'longitude' => 0.0,
        ]);
        User::create([
            'name' => 'Driver Two',
            'email' => 'driver2@speedgo.com',
            'phone' => '81338642',
            'password' => Hash::make('password'),
            'role' => 'driver',
            'latitude' => 0.0,
            'longitude' => 0.0,
        ]);
        User::create([
            'name' => 'Driver Three',
            'email' => 'driver3@speedgo.com',
            'phone' => '81338643',
            'password' => Hash::make('password'),
            'role' => 'driver',
            'latitude' => 0.0,
            'longitude' => 0.0,
        ]);
    }
}
