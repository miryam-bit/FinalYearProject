<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;


use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
class AuthController extends Controller
{public function register(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name'     => 'required|string|max:255',
                'email'    => 'required|email|unique:users,email',
                'phone'    => 'required|unique:users,phone',
                'password' => 'required|min:6'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = User::create([
                'name'     => $request->name,
                'email'    => $request->email,
                'phone'    => $request->phone,
                'password' => Hash::make($request->password),
                'otp'      => rand(1000, 9999),
            ]);

            return response()->json([
                'status' => true,
                'message' => 'User registered. OTP sent.',
                'user' => $user
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong!',
                'error' => $e->getMessage()
            ], 500);
        }
    }



    public function verifyOtp(Request $request)
    {
        try {
            $request->validate([
                'phone' => 'required',
                'otp'   => 'required',
            ]);
            $user = User::where('phone', $request->phone)->first();

            if (!$user) {
                return response()->json(['status' => false, 'message' => 'User not found'], 404);
            }

            if ($user->otp != $request->otp) {
                return response()->json(['status' => false, 'message' => 'Invalid OTP'], 401);
            }

            // ✅ clear OTP
            $user->otp = null;
            $user->save();

            // ✅ generate token
            $token = $user->createToken('customer-token')->plainTextToken;

            return response()->json([
                'status'  => true,
                'message' => 'OTP verified',
                'token'   => $token,
                'user'    => $user,
            ]);
        } catch (\Exception $e) {
            Log::error('OTP Verification failed: ' . $e->getMessage());
            return response()->json(['message' => 'Server error', 'error' => $e->getMessage()], 500);
        }
    }

public function login(Request $request)
{
    $request->validate([
        'phone' => 'required',
        'password' => 'required',
    ]);

    $user = User::where('phone', $request->phone)->first();

    if (!$user || !Hash::check($request->password, $user->password)) {
        return response()->json(['status' => false, 'message' => 'Invalid credentials'], 401);
    }

    //if ($user->otp !== null) {
        //return response()->json(['status' => false, 'message' => 'Please verify your phone number first'], 403);
   // }

    $token = $user->createToken('customer-token')->plainTextToken;

    return response()->json([
        'status' => true,
        'message' => 'Login successful',
        'token' => $token,
        'user' => $user,
    ]);
}


    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }








}
