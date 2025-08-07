<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class AdminController extends Controller
{
    // View all drivers and their locations
    public function getAllDrivers()
    {
        $drivers = User::where('role', 'driver')
            ->select('id', 'name', 'email', 'phone', 'latitude', 'longitude', 'created_at')
            ->get();
        
        return response()->json([
            'drivers' => $drivers,
            'total_drivers' => $drivers->count()
        ]);
    }

    // Update driver location by ID
    public function updateDriverLocation(Request $request)
    {
        $request->validate([
            'driver_id' => 'required|integer|exists:users,id',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $driver = User::where('id', $request->driver_id)
            ->where('role', 'driver')
            ->first();

        if (!$driver) {
            return response()->json(['message' => 'Driver not found'], 404);
        }

        $driver->latitude = $request->latitude;
        $driver->longitude = $request->longitude;
        $driver->save();

        return response()->json([
            'message' => 'Driver location updated successfully',
            'driver' => [
                'id' => $driver->id,
                'name' => $driver->name,
                'latitude' => $driver->latitude,
                'longitude' => $driver->longitude
            ]
        ]);
    }

    // Create a test driver if needed
    public function createTestDriver(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'phone' => 'required|string|unique:users,phone',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $driver = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'password' => bcrypt('password123'), // Default password
            'role' => 'driver',
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
        ]);

        return response()->json([
            'message' => 'Test driver created successfully',
            'driver' => [
                'id' => $driver->id,
                'name' => $driver->name,
                'email' => $driver->email,
                'phone' => $driver->phone,
                'latitude' => $driver->latitude,
                'longitude' => $driver->longitude
            ]
        ]);
    }

    // Get driver by ID
    public function getDriver($id)
    {
        $driver = User::where('id', $id)
            ->where('role', 'driver')
            ->select('id', 'name', 'email', 'phone', 'latitude', 'longitude')
            ->first();

        if (!$driver) {
            return response()->json(['message' => 'Driver not found'], 404);
        }

        return response()->json(['driver' => $driver]);
    }
} 