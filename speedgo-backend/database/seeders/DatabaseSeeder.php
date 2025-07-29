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

        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'phone' => '9999999999', // Added phone field
            'password' => Hash::make('password'),
            'role' => 'customer',
        ]);
        User::create([
            'name' => 'Driver One',
            'email' => 'driver1@example.com',
            'phone' => '1111111111',
            'password' => Hash::make('password1'),
            'role' => 'driver',
        ]);
        User::create([
            'name' => 'Driver Two',
            'email' => 'driver2@example.com',
            'phone' => '2222222222',
            'password' => Hash::make('password2'),
            'role' => 'driver',
        ]);
        User::create([
            'name' => 'Driver Three',
            'email' => 'driver3@example.com',
            'phone' => '3333333333',
            'password' => Hash::make('password3'),
            'role' => 'driver',
        ]);
    }
}
