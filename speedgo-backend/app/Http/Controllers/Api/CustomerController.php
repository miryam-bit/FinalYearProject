<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
//use App\Http\Controllers\Api\Hash;
use Illuminate\Support\Facades\Hash;

class CustomerController extends Controller
{
    public function profile(Request $request)
    {
        return response()->json($request->user());
    }

    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'     => 'sometimes|string|max:255',
            'email'    => 'sometimes|email|unique:users,email,' . Auth::id(),
            'phone'    => 'sometimes|string|unique:users,phone,' . Auth::id(),
            'password' => 'sometimes|string|min:6',
            'photo'    => 'nullable|image|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = $request->user();

        if ($request->has('name'))     $user->name     = $request->name;
        if ($request->has('email'))    $user->email    = $request->email;
        if ($request->has('phone'))    $user->phone    = $request->phone;
        if ($request->has('password')) $user->password = Hash::make($request->password);

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('profile_photos', 'public');
            $user->photo = $path;
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => $user
        ]);
    }

}
