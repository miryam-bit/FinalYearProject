<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\emergency_contacts;
use Illuminate\Support\Facades\Auth;

class EmergencyContactController extends Controller
{
    public function index()
    {
        return emergency_contacts::where('user_id', Auth::id())->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'  => 'required|string',
            'phone' => 'required|string',
        ]);

        $contact = emergency_contacts::create([
            'user_id' => Auth::id(),
            'name'    => $request->name,
            'phone'   => $request->phone,
        ]);

        return response()->json(['message' => 'Contact added', 'contact' => $contact]);
    }

    public function destroy($id)
    {
        emergency_contacts::where('id', $id)
            ->where('user_id', Auth::id())
            ->delete();

        return response()->json(['message' => 'Contact deleted']);
    }
}

