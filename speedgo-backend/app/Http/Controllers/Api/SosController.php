<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Emergency_contacts;
use App\Models\SosTrigger;
use App\Models\EmergencyContact;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;



class SosController extends Controller
{
    public function trigger(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);


        $user = Auth::user();
        $url = "https://maps.google.com/?q={$request->latitude},{$request->longitude}";

        // Save SOS event
        SosTrigger::create([
            'user_id'    => Auth::id(),
            'latitude'   => $request->latitude,
            'longitude'  => $request->longitude,
            'shared_url' => $url,
        ]);


        // Notify emergency contacts
        $contacts = Emergency_contacts::where('user_id', $user->id)->get();

        foreach ($contacts as $contact) {
            // Here you can send SMS/email notification if setup
            Log::info("Notify {$contact->name} at {$contact->phone}: $url");
        }

        return response()->json([
            'message' => 'SOS sent to emergency contacts',
            'url'     => $url,
            'contacts_notified' => $contacts->pluck('name')->values(), // add this
        ]);
    }
}
