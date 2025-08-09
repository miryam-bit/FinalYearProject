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

        // Validate that scheduled rides are only for the same day
        if ($request->scheduled_at) {
            $scheduledDate = \Carbon\Carbon::parse($request->scheduled_at);
            
            // Get current time from client or use server time as fallback
            $currentTime = $request->input('current_time');
            if ($currentTime) {
                $now = \Carbon\Carbon::parse($currentTime);
                $today = $now->startOfDay();
            } else {
                $now = now();
                $today = \Carbon\Carbon::today();
            }
            
            // Debug logging
            \Log::info('Booking validation - Current time: ' . $now->format('Y-m-d H:i:s'));
            \Log::info('Booking validation - Scheduled time: ' . $scheduledDate->format('Y-m-d H:i:s'));
            \Log::info('Booking validation - Today: ' . $today->format('Y-m-d H:i:s'));
            \Log::info('Booking validation - Same day check: ' . ($scheduledDate->isSameDay($today) ? 'Yes' : 'No'));
            
            if (!$scheduledDate->isSameDay($today)) {
                return response()->json([
                    'message' => 'Scheduled rides can only be booked for the same day.'
                ], 422);
            }
            
            // Ensure scheduled time is in the future
            if ($scheduledDate->isBefore($now)) {
                return response()->json([
                    'message' => 'Scheduled time must be in the future.'
                ], 422);
            }
        }

        // Time is already in UTC from the client
        $scheduledAt = null;
        if ($request->scheduled_at) {
            $scheduledAt = \Carbon\Carbon::parse($request->scheduled_at);
        }

        $ride = Ride::create([
            'user_id'          => Auth::id(),
            'pickup_location'  => $request->pickup_location,
            'dropoff_location' => $request->dropoff_location,
            'scheduled_at'     => $scheduledAt,
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
    public function getRideRequests(Request $request)
    {
        // Get current time from client or use server time as fallback
        $currentTime = $request->input('current_time');
        $timezoneOffset = (int) $request->input('timezone_offset', 0); // Convert to integer
        
        if ($currentTime) {
            $now = \Carbon\Carbon::parse($currentTime);
        } else {
            $now = now();
        }

        // Check if driver already has an active immediate ride (not scheduled)
        $activeImmediateRide = Ride::where('driver_id', Auth::id())
            ->whereIn('status', ['accepted', 'in_progress'])
            ->whereNull('scheduled_at') // Only immediate rides, not scheduled ones
            ->first();
        
        if ($activeImmediateRide) {
            return response()->json([
                'message' => 'You already have an active ride. Complete it first.',
                'has_active_ride' => true,
                'active_ride_id' => $activeImmediateRide->id,
                'can_accept_rides' => false,
                'ride_requests' => []
            ], 403);
        }

        // Check if driver has any scheduled rides
        $scheduledRide = Ride::where('driver_id', Auth::id())
            ->whereIn('status', ['accepted', 'in_progress'])
            ->whereNotNull('scheduled_at')
            ->first();

        if ($scheduledRide) {
            // Convert scheduled time to local timezone for comparison
            $localScheduledTime = $scheduledRide->scheduled_at->addHours($timezoneOffset);
            $timeDiff = $now->diffInMinutes($localScheduledTime);
            $isWithinOneHour = $timeDiff <= 60;
            $isPastScheduledTime = $now > $localScheduledTime;
            
            // Debug logging
            \Log::info('Driver ID: ' . Auth::id());
            \Log::info('Client current time: ' . $now->format('Y-m-d H:i:s'));
            \Log::info('Scheduled ride time: ' . $scheduledRide->scheduled_at->format('Y-m-d H:i:s'));
            \Log::info('Time difference: ' . $timeDiff . ' minutes');
            \Log::info('Is within 1 hour: ' . ($isWithinOneHour ? 'Yes' : 'No'));
            \Log::info('Is past scheduled time: ' . ($isPastScheduledTime ? 'Yes' : 'No'));
            
            // If scheduled time has passed, allow driver to take other rides
            if ($isPastScheduledTime) {
                // Continue to show ride requests - driver can take other rides
                $pendingRides = Ride::where('status', 'pending')
                    ->whereNull('driver_id')
                    ->with('user:id,name,phone')
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
                            'scheduled_at' => $ride->scheduled_at,
                            'created_at' => $ride->created_at,
                        ];
                    });

                return response()->json([
                    'message' => 'Available ride requests (scheduled ride time has passed)',
                    'has_active_ride' => false,
                    'has_scheduled_ride' => false,
                    'can_accept_rides' => true,
                    'ride_requests' => $pendingRides
                ]);
            }
            
            if ($isWithinOneHour) {
                // Within 1 hour - block completely
                $localScheduledTime = $scheduledRide->scheduled_at->addHours($timezoneOffset);
                $scheduledTime = $localScheduledTime->format('h:i A');
                $direction = $localScheduledTime > $now ? 'in' : 'ago';
                
                return response()->json([
                    'message' => "You have a scheduled ride at $scheduledTime ($timeDiff minutes $direction). You cannot accept new rides within 1 hour of your scheduled ride.",
                    'has_active_ride' => false,
                    'has_scheduled_ride' => true,
                    'scheduled_ride_time' => $scheduledTime,
                    'can_accept_rides' => false,
                    'ride_requests' => [] // Empty array - no ride requests shown
                ], 403);
            } else {
                // More than 1 hour away - allow access but show warning
                $localScheduledTime = $scheduledRide->scheduled_at->addHours($timezoneOffset);
                $scheduledTime = $localScheduledTime->format('h:i A');
                $hoursAway = floor($timeDiff / 60);
                $minutesAway = $timeDiff % 60;
                $timeString = $hoursAway > 0 ? "$hoursAway hours $minutesAway minutes" : "$minutesAway minutes";
                
                // Continue to show ride requests but with warning
                $pendingRides = Ride::where('status', 'pending')
                    ->whereNull('driver_id')
                    ->with('user:id,name,phone')
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
                            'scheduled_at' => $ride->scheduled_at,
                            'created_at' => $ride->created_at,
                        ];
                    });

                return response()->json([
                    'message' => "You have a scheduled ride at $scheduledTime ($timeString away). You can still accept other rides.",
                    'has_active_ride' => false,
                    'has_scheduled_ride' => true,
                    'scheduled_ride_time' => $scheduledTime,
                    'can_accept_rides' => true,
                    'ride_requests' => $pendingRides
                ]);
            }
        }

        // No active rides - show all pending rides
        $pendingRides = Ride::where('status', 'pending')
            ->whereNull('driver_id')
            ->with('user:id,name,phone')
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
                    'scheduled_at' => $ride->scheduled_at,
                    'created_at' => $ride->created_at,
                ];
            });

        return response()->json([
            'message' => 'Available ride requests',
            'has_active_ride' => false,
            'has_scheduled_ride' => false,
            'can_accept_rides' => true,
            'ride_requests' => $pendingRides
        ]);
    }

    // Accept a ride request
    public function acceptRide(Request $request)
    {
        $request->validate([
            'ride_id' => 'required|exists:rides,id',
        ]);

        // Get current time from client or use server time as fallback
        $currentTime = $request->input('current_time');
        $timezoneOffset = (int) $request->input('timezone_offset', 0); // Convert to integer
        
        if ($currentTime) {
            $now = \Carbon\Carbon::parse($currentTime);
        } else {
            $now = now();
        }

        // Check if driver already has an active immediate ride (not scheduled)
        $activeImmediateRide = Ride::where('driver_id', Auth::id())
            ->whereIn('status', ['accepted', 'in_progress'])
            ->whereNull('scheduled_at') // Only immediate rides, not scheduled ones
            ->first();
        
        if ($activeImmediateRide) {
            return response()->json([
                'message' => 'You already have an active ride. Complete it first.'
            ], 400);
        }

        // Check if driver has any scheduled rides
        $scheduledRide = Ride::where('driver_id', Auth::id())
            ->whereIn('status', ['accepted', 'in_progress'])
            ->whereNotNull('scheduled_at')
            ->first();

        if ($scheduledRide) {
            // Convert scheduled time to local timezone for comparison
            $localScheduledTime = $scheduledRide->scheduled_at->addHours($timezoneOffset);
            $timeDiff = $now->diffInMinutes($localScheduledTime);
            $isWithinOneHour = $timeDiff <= 60;
            $isPastScheduledTime = $now > $localScheduledTime;
            
            // If scheduled time has passed, allow driver to take other rides
            if ($isPastScheduledTime) {
                // Allow accepting new rides
            } else if ($isWithinOneHour) {
                // Within 1 hour - block accepting new rides
                $localScheduledTime = $scheduledRide->scheduled_at->addHours($timezoneOffset);
                $scheduledTime = $localScheduledTime->format('h:i A');
                $direction = $localScheduledTime > $now ? 'in' : 'ago';
                
                return response()->json([
                    'message' => "You have a scheduled ride at $scheduledTime ($timeDiff minutes $direction). You cannot accept new rides within 1 hour of your scheduled ride."
                ], 400);
            }
            // If more than 1 hour away, allow accepting new rides
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

        // Debug logging for accepted ride
        \Log::info('Ride accepted - ID: ' . $ride->id . ', Driver ID: ' . Auth::id() . ', Scheduled: ' . ($ride->scheduled_at ? $ride->scheduled_at->format('Y-m-d H:i:s') : 'No'));

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
            ->whereIn('status', ['accepted', 'in_progress']) // Only active rides, exclude completed/cancelled
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
                    'scheduled_at' => $ride->scheduled_at,
                    'created_at' => $ride->created_at,
                ];
            });
        return response()->json(['rides' => $rides]);
    }

    // Get ride history for the driver (including completed and cancelled rides)
    public function getDriverRideHistory(Request $request)
    {
        $driverId = Auth::id();
        $rides = Ride::where('driver_id', $driverId)
            ->whereIn('status', ['completed', 'cancelled']) // Only completed and cancelled rides
            ->with('user:id,name,phone') // Include customer info
            ->orderBy('created_at', 'desc')
            ->limit(20) // Limit to last 20 rides
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
                    'scheduled_at' => $ride->scheduled_at,
                    'created_at' => $ride->created_at,
                ];
            });
        return response()->json(['rides' => $rides]);
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

            // Check if trying to start a scheduled ride before its time
            if ($request->status === 'in_progress' && $ride->scheduled_at) {
                // Get current time from client or use server time as fallback
                $currentTime = $request->input('current_time');
                if ($currentTime) {
                    $now = \Carbon\Carbon::parse($currentTime);
                } else {
                    $now = now();
                }

                if ($now < $ride->scheduled_at) {
                    $scheduledTime = $ride->scheduled_at->format('h:i A');
                    $currentTimeFormatted = $now->format('h:i A');
                    $timeDiff = $now->diffInMinutes($ride->scheduled_at);
                    
                    return response()->json([
                        'message' => "Cannot start scheduled ride yet. Scheduled for $scheduledTime (current time: $currentTimeFormatted, $timeDiff minutes remaining)."
                    ], 400);
                }
            }

            // Validate status transitions
            $allowedTransitions = [
                'accepted' => ['in_progress', 'cancelled'],
                'in_progress' => ['completed'],
                'pending' => ['accepted', 'cancelled'],
            ];

            if (isset($allowedTransitions[$ride->status]) && !in_array($request->status, $allowedTransitions[$ride->status])) {
                return response()->json([
                    'message' => 'Invalid status transition. Current status: ' . $ride->status . ', Allowed: ' . implode(', ', $allowedTransitions[$ride->status])
                ], 400);
            }

            $oldStatus = $ride->status;
            $ride->status = $request->status;
            $ride->save();

            // Log the status change for debugging
            \Log::info("Ride status updated - ID: {$ride->id}, Driver: " . Auth::id() . ", From: $oldStatus, To: {$request->status}");

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

    // Debug method to test scheduled ride logic
    public function debugScheduledRide()
    {
        $driverId = Auth::id();
        $now = now();
        $oneHourBefore = $now->copy()->subHour();
        $oneHourAfter = $now->copy()->addHour();
        
        // Get all active rides (both immediate and scheduled)
        $allActiveRides = Ride::where('driver_id', $driverId)
            ->whereIn('status', ['accepted', 'in_progress'])
            ->get();
        
        // Get immediate rides (no scheduled_at)
        $immediateRides = Ride::where('driver_id', $driverId)
            ->whereIn('status', ['accepted', 'in_progress'])
            ->whereNull('scheduled_at')
            ->get();
        
        // Get scheduled rides
        $scheduledRides = Ride::where('driver_id', $driverId)
            ->whereIn('status', ['accepted', 'in_progress'])
            ->whereNotNull('scheduled_at')
            ->get();
        
        $conflictingRide = Ride::where('driver_id', $driverId)
            ->whereIn('status', ['accepted', 'in_progress'])
            ->whereNotNull('scheduled_at')
            ->where('scheduled_at', '>=', $oneHourBefore)
            ->where('scheduled_at', '<=', $oneHourAfter)
            ->first();
        
        // Calculate time differences for all scheduled rides
        $scheduledRidesWithTimeDiff = $scheduledRides->map(function($ride) use ($now) {
            $timeDiff = $now->diffInMinutes($ride->scheduled_at);
            $direction = $ride->scheduled_at > $now ? 'in' : 'ago';
            return [
                'id' => $ride->id,
                'scheduled_at' => $ride->scheduled_at->format('Y-m-d H:i:s'),
                'status' => $ride->status,
                'time_difference_minutes' => $timeDiff,
                'direction' => $direction,
                'is_within_1_hour' => $timeDiff <= 60
            ];
        });
        
        return response()->json([
            'driver_id' => $driverId,
            'current_time' => $now->format('Y-m-d H:i:s'),
            'one_hour_before' => $oneHourBefore->format('Y-m-d H:i:s'),
            'one_hour_after' => $oneHourAfter->format('Y-m-d H:i:s'),
            'all_active_rides' => $allActiveRides->map(function($ride) {
                return [
                    'id' => $ride->id,
                    'scheduled_at' => $ride->scheduled_at ? $ride->scheduled_at->format('Y-m-d H:i:s') : null,
                    'status' => $ride->status,
                    'type' => $ride->scheduled_at ? 'scheduled' : 'immediate'
                ];
            }),
            'immediate_rides' => $immediateRides->map(function($ride) {
                return [
                    'id' => $ride->id,
                    'status' => $ride->status
                ];
            }),
            'scheduled_rides' => $scheduledRidesWithTimeDiff,
            'conflicting_ride' => $conflictingRide ? [
                'id' => $conflictingRide->id,
                'scheduled_at' => $conflictingRide->scheduled_at->format('Y-m-d H:i:s'),
                'time_difference_minutes' => $now->diffInMinutes($conflictingRide->scheduled_at),
                'direction' => $conflictingRide->scheduled_at > $now ? 'in' : 'ago'
            ] : null,
            'can_see_ride_requests' => $immediateRides->isEmpty() && $conflictingRide === null,
            'can_accept_rides' => $conflictingRide === null
        ]);
    }
}
