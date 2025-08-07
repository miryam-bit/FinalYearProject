<?php

namespace Database\Seeders;

use Illuminate\Support\Facades\Hash;
use App\Models\User;
use Illuminate\Database\Seeder;

class RealPhoneSeeder extends Seeder
{
    /**
     * Seed the application's database with real phone numbers.
     */
    public function run(): void
    {
        // Customer with real phone number
        User::updateOrCreate(
            ['phone' => 'YOUR_REAL_PHONE_NUMBER'], // Replace with your actual phone number
            [
                'name' => 'Test Customer',
                'email' => 'customer@speedgo.com',
                'password' => Hash::make('password'),
                'role' => 'customer',
            ]
        );

        // Driver with real phone number
        User::updateOrCreate(
            ['phone' => 'YOUR_REAL_PHONE_NUMBER'], // Replace with your actual phone number
            [
                'name' => 'Test Driver',
                'email' => 'driver@speedgo.com',
                'password' => Hash::make('password'),
                'role' => 'driver',
                'latitude' => 0.0, // Will be updated by GPS
                'longitude' => 0.0, // Will be updated by GPS
            ]
        );

        // Additional test drivers with different phone numbers
        User::updateOrCreate(
            ['phone' => '1111111111'],
            [
                'name' => 'Driver One',
                'email' => 'driver1@speedgo.com',
                'password' => Hash::make('password1'),
                'role' => 'driver',
                'latitude' => 0.0,
                'longitude' => 0.0,
            ]
        );

        User::updateOrCreate(
            ['phone' => '2222222222'],
            [
                'name' => 'Driver Two',
                'email' => 'driver2@speedgo.com',
                'password' => Hash::make('password2'),
                'role' => 'driver',
                'latitude' => 0.0,
                'longitude' => 0.0,
            ]
        );

        User::updateOrCreate(
            ['phone' => '3333333333'],
            [
                'name' => 'Driver Three',
                'email' => 'driver3@speedgo.com',
                'password' => Hash::make('password3'),
                'role' => 'driver',
                'latitude' => 0.0,
                'longitude' => 0.0,
            ]
        );
    }
} 