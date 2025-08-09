<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use App\Models\Customer;
use App\Models\Ride;
use App\Models\EmergencyContact;

class CustomerController extends Controller
{
    /**
     * Get customer profile
     */
    public function getProfile(Request $request)
    {
        $customer = Auth::user();
        
        return response()->json([
            'id' => $customer->id,
            'name' => $customer->name,
            'email' => $customer->email,
            'phone' => $customer->phone,
            'created_at' => $customer->created_at,
        ]);
    }

    /**
     * Update customer profile
     */
    public function updateProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|max:255|unique:users,email,' . Auth::id(),
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $customer = Auth::user();
        $customer->name = $request->name;
        
        if ($request->has('email')) {
            $customer->email = $request->email;
        }
        
        $customer->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'customer' => [
                'id' => $customer->id,
                'name' => $customer->name,
                'email' => $customer->email,
                'phone' => $customer->phone,
            ]
        ]);
    }

    /**
     * Get customer ride history
     */
    public function getRideHistory(Request $request)
    {
        $customer = Auth::user();
        
        $rides = Ride::where('user_id', $customer->id)
            ->with(['driver:id,name,phone'])
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($ride) {
                return [
                    'id' => $ride->id,
                    'pickup_location' => $ride->pickup_location,
                    'dropoff_location' => $ride->dropoff_location,
                    'status' => $ride->status,
                    'fare' => $ride->fare,
                    'created_at' => $ride->created_at,
                    'scheduled_at' => $ride->scheduled_at,
                    'driver' => $ride->driver ? [
                        'id' => $ride->driver->id,
                        'name' => $ride->driver->name,
                        'phone' => $ride->driver->phone,
                    ] : null,
                ];
            });

        return response()->json([
            'rides' => $rides
        ]);
    }

    /**
     * Get customer ride statistics
     */
    public function getRideStats(Request $request)
    {
        $customer = Auth::user();
        
        $totalRides = Ride::where('user_id', $customer->id)->count();
        $totalSpent = Ride::where('user_id', $customer->id)
            ->where('status', 'completed')
            ->sum('fare');
        $completedRides = Ride::where('user_id', $customer->id)
            ->where('status', 'completed')
            ->count();

        return response()->json([
            'total_rides' => $totalRides,
            'total_spent' => $totalSpent,
            'completed_rides' => $completedRides,
        ]);
    }

    /**
     * Get emergency contacts
     */
    public function getEmergencyContacts(Request $request)
    {
        $customer = Auth::user();
        
        $contacts = EmergencyContact::where('customer_id', $customer->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($contact) {
                return [
                    'id' => $contact->id,
                    'name' => $contact->name,
                    'phone' => $contact->phone,
                    'relationship' => $contact->relationship,
                    'created_at' => $contact->created_at,
                ];
            });

        return response()->json([
            'contacts' => $contacts
        ]);
    }

    /**
     * Add emergency contact
     */
    public function addEmergencyContact(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'relationship' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $customer = Auth::user();
        
        $contact = EmergencyContact::create([
            'customer_id' => $customer->id,
            'name' => $request->name,
            'phone' => $request->phone,
            'relationship' => $request->relationship ?? 'Contact',
        ]);

        return response()->json([
            'message' => 'Emergency contact added successfully',
            'contact' => [
                'id' => $contact->id,
                'name' => $contact->name,
                'phone' => $contact->phone,
                'relationship' => $contact->relationship,
            ]
        ], 201);
    }

    /**
     * Update emergency contact
     */
    public function updateEmergencyContact(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'relationship' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $customer = Auth::user();
        
        $contact = EmergencyContact::where('id', $id)
            ->where('customer_id', $customer->id)
            ->first();

        if (!$contact) {
            return response()->json([
                'message' => 'Emergency contact not found'
            ], 404);
        }

        $contact->update([
            'name' => $request->name,
            'phone' => $request->phone,
            'relationship' => $request->relationship ?? 'Contact',
        ]);

        return response()->json([
            'message' => 'Emergency contact updated successfully',
            'contact' => [
                'id' => $contact->id,
                'name' => $contact->name,
                'phone' => $contact->phone,
                'relationship' => $contact->relationship,
            ]
        ]);
    }

    /**
     * Delete emergency contact
     */
    public function deleteEmergencyContact(Request $request, $id)
    {
        $customer = Auth::user();
        
        $contact = EmergencyContact::where('id', $id)
            ->where('customer_id', $customer->id)
            ->first();

        if (!$contact) {
            return response()->json([
                'message' => 'Emergency contact not found'
            ], 404);
        }

        $contact->delete();

        return response()->json([
            'message' => 'Emergency contact deleted successfully'
        ]);
    }
}
