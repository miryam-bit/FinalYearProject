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
        ]);

        return response()->json(['message' => 'Ride booked', 'ride' => $ride]);
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
}
