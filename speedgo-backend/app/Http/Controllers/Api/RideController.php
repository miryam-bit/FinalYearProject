<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Ride;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
class RideController extends Controller
{
    public function bookRide(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pickup_location'   => 'required|string',
            'dropoff_location'  => 'required|string',
            'scheduled_at'      => 'nullable|date',
            'vehicle_type'      => 'required|string',
            'payment_method'    => 'required|string',
            'stops'             => 'nullable|array',
            // Remove driver_id requirement - drivers will accept requests
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $ride = Ride::create([
            'user_id'          => Auth::id(),
            'pickup_location'  => $request->pickup_location,
            'dropoff_location' => $request->dropoff_location,
            'scheduled_at'     => $request->scheduled_at,
            'vehicle_type'     => $request->vehicle_type,
            'payment_method'   => $request->payment_method,
            'status'           => 'pending',
            'stops'            => json_encode($request->stops),
            'driver_id'        => null, // No driver assigned initially
        ]);

        return response()->json(['message' => 'Ride request created successfully', 'ride' => $ride]);
    }

    public function cancelRide(Request $request)
    {
        $request->validate([
            'ride_id' => 'required|exists:rides,id',
            'reason' => 'nullable|string'
        ]);

        $ride = Ride::where('id', $request->ride_id)
                    ->where('user_id', Auth::id())
                    ->first();

        if (!$ride) {
            return response()->json(['message' => 'Ride not found'], 404);
        }

        if ($ride->status !== 'pending') {
            return response()->json(['message' => 'Cannot cancel a non-pending ride'], 400);
        }

        $ride->status = 'cancelled';
        $ride->save();

        return response()->json(['message' => 'Ride cancelled']);
    }

    public function rideHistory()
    {
        $rides = Ride::where('user_id', Auth::id())
                     ->orderBy('created_at', 'desc')
                     ->get();

        return response()->json($rides);
    }
    public function estimateFare(Request $request)
{
    $request->validate([
        'pickup.latitude' => 'required|numeric',
        'pickup.longitude' => 'required|numeric',
        'dropoff.latitude' => 'required|numeric',
        'dropoff.longitude' => 'required|numeric',
        'stops' => 'nullable|array',
        'stops.*.latitude' => 'required|numeric',
        'stops.*.longitude' => 'required|numeric',
    ]);

    $origin = $request->pickup['latitude'] . ',' . $request->pickup['longitude'];
    $destination = $request->dropoff['latitude'] . ',' . $request->dropoff['longitude'];
    $waypoints = collect($request->stops ?? [])->map(function($stop) {
        return $stop['latitude'] . ',' . $stop['longitude'];
    })->implode('|');

    $apiKey = 'AIzaSyDUAPMhKz0uqqwkVoWTdwpb0U9QSlpYHqE'; // hardcoded test


$params = [
    'origin' => $origin,
    'destination' => $destination,
    'key' => $apiKey,
];

if (!empty($waypoints)) {
    $params['waypoints'] = $waypoints;
}

$response = Http::get('https://maps.googleapis.com/maps/api/directions/json', $params);
$data = $response->json();

    if (empty($data['routes']) || !isset($data['routes'][0]['legs'])) {
        return response()->json(['error' => 'No route found'], 400);
    }

    $distanceMeters = 0;
    foreach ($data['routes'][0]['legs'] as $leg) {
        $distanceMeters += $leg['distance']['value'];
    }

    $durationText = $data['routes'][0]['legs'][0]['duration']['text'];

    $baseFare = 2.00;
    $ratePerKm = 0.75;
    $distanceKm = $distanceMeters / 1000;

    $fare = $baseFare + ($ratePerKm * $distanceKm);

    return response()->json([
        'estimated_fare' => round($fare, 2),
        'estimated_time' => $durationText,
        'distance_km' => round($distanceKm, 2)
    ]);
}


    public function sendInvoice(Request $request)
    {
        $request->validate(['ride_id' => 'required|exists:rides,id']);

        $ride = Ride::where('id', $request->ride_id)
                    ->where('user_id', Auth::id())
                    ->first();

        if (!$ride) {
            return response()->json(['message' => 'Ride not found'], 404);
        }

        // TODO: Build and send invoice email

        return response()->json(['message' => 'Invoice sent successfully (mock response)']);
    }

    // List all drivers
    public function listDrivers()
    {
        $drivers = \App\Models\User::where('role', 'driver')
            ->get(['id', 'name', 'email', 'phone', 'latitude', 'longitude']);
        return response()->json($drivers);
    }

    // Get ride requests for drivers (pending rides without assigned drivers)
    public function getRideRequests()
    {
        // Check if driver already has an active ride
        $activeRide = Ride::where('driver_id', Auth::id())
            ->whereIn('status', ['accepted', 'in_progress'])
            ->first();
        
        if ($activeRide) {
            return response()->json([
                'message' => 'You already have an active ride. Complete it first.',
                'has_active_ride' => true,
                'active_ride_id' => $activeRide->id
            ], 403);
        }

        $rideRequests = Ride::where('status', 'pending')
            ->whereNull('driver_id')
            ->with('user:id,name,phone') // Include customer info
            ->get()
            ->map(function ($ride) {
                return [
                    'id' => $ride->id,
                    'pickup_location' => $ride->pickup_location,
                    'dropoff_location' => $ride->dropoff_location,
                    'customer_name' => $ride->user->name,
                    'customer_phone' => $ride->user->phone,
                    'vehicle_type' => $ride->vehicle_type,
                    'payment_method' => $ride->payment_method,
                    'created_at' => $ride->created_at,
                ];
            });
        
        return response()->json([
            'ride_requests' => $rideRequests,
            'has_active_ride' => false
        ]);
    }

    // Accept a ride request
    public function acceptRide(Request $request)
    {
        $request->validate([
            'ride_id' => 'required|exists:rides,id',
        ]);

        // Check if driver already has an active ride
        $activeRide = Ride::where('driver_id', Auth::id())
            ->whereIn('status', ['accepted', 'in_progress'])
            ->first();
        
        if ($activeRide) {
            return response()->json(['message' => 'You already have an active ride. Complete it first.'], 400);
        }

        $ride = Ride::where('id', $request->ride_id)
            ->where('status', 'pending')
            ->whereNull('driver_id')
            ->first();

        if (!$ride) {
            return response()->json(['message' => 'Ride request not found or already assigned'], 404);
        }

        $ride->driver_id = Auth::id();
        $ride->status = 'accepted';
        $ride->save();

        return response()->json(['message' => 'Ride accepted successfully', 'ride' => $ride]);
    }

    // Reject a ride request
    public function rejectRide(Request $request)
    {
        $request->validate([
            'ride_id' => 'required|exists:rides,id',
        ]);

        $ride = Ride::where('id', $request->ride_id)
            ->where('status', 'pending')
            ->whereNull('driver_id')
            ->first();

        if (!$ride) {
            return response()->json(['message' => 'Ride request not found or already assigned'], 404);
        }

        $ride->status = 'rejected';
        $ride->save();

        return response()->json(['message' => 'Ride rejected successfully']);
    }

    // Get rides assigned to the authenticated driver (only active rides)
    public function getDriverRides(Request $request)
    {
        $driverId = Auth::id();
        $rides = Ride::where('driver_id', $driverId)
            ->whereIn('status', ['accepted', 'in_progress']) // Only active rides
            ->with('user:id,name,phone') // Include customer info
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($ride) {
                return [
                    'id' => $ride->id,
                    'pickup_location' => $ride->pickup_location,
                    'dropoff_location' => $ride->dropoff_location,
                    'customer_name' => $ride->user->name,
                    'customer_phone' => $ride->user->phone,
                    'status' => $ride->status,
                    'vehicle_type' => $ride->vehicle_type,
                    'payment_method' => $ride->payment_method,
                    'created_at' => $ride->created_at,
                ];
            });
        return response()->json($rides);
    }

    // Update the status of a ride assigned to the driver
    public function updateRideStatus(Request $request)
    {
        $request->validate([
            'ride_id' => 'required|exists:rides,id',
            'status' => 'required|string|in:pending,accepted,in_progress,completed,cancelled,rejected',
        ]);

        try {
            $ride = Ride::where('id', $request->ride_id)
                ->where('driver_id', Auth::id())
                ->first();

            if (!$ride) {
                return response()->json(['message' => 'Ride not found or not assigned to this driver'], 404);
            }

            // Validate status transitions
            $allowedTransitions = [
                'accepted' => ['in_progress'],
                'in_progress' => ['completed'],
            ];

            if (isset($allowedTransitions[$ride->status]) && !in_array($request->status, $allowedTransitions[$ride->status])) {
                return response()->json([
                    'message' => 'Invalid status transition. Current status: ' . $ride->status . ', Allowed: ' . implode(', ', $allowedTransitions[$ride->status])
                ], 400);
            }

            $oldStatus = $ride->status;
            $ride->status = $request->status;
            $ride->save();

            return response()->json([
                'message' => 'Ride status updated from ' . $oldStatus . ' to ' . $request->status,
                'ride' => $ride
            ]);

        } catch (\Exception $e) {
            \Log::error('Error updating ride status: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error updating ride status: ' . $e->getMessage()
            ], 500);
        }
    }

    public function updateDriverLocation(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);
        $driver = \App\Models\User::find(Auth::id());
        if (!$driver || $driver->role !== 'driver') {
            return response()->json(['message' => 'Not authorized'], 403);
        }
        $driver->latitude = $request->latitude;
        $driver->longitude = $request->longitude;
        $driver->save();
        return response()->json(['message' => 'Location updated']);
    }
}
