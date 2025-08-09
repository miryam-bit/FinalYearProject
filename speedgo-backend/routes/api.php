<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RideController;
use App\Http\Controllers\Api\CustomerController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Auth routes
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('/logout', [AuthController::class, 'logout']);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Customer routes
    Route::get('/customer', [CustomerController::class, 'getProfile']);
    Route::put('/customer/update', [CustomerController::class, 'updateProfile']);
    Route::get('/rides', [CustomerController::class, 'getRideHistory']);
    Route::get('/ride-stats', [CustomerController::class, 'getRideStats']);
    
    // Emergency contacts
    Route::get('/emergency-contacts', [CustomerController::class, 'getEmergencyContacts']);
    Route::post('/emergency-contacts', [CustomerController::class, 'addEmergencyContact']);
    Route::put('/emergency-contacts/{id}', [CustomerController::class, 'updateEmergencyContact']);
    Route::delete('/emergency-contacts/{id}', [CustomerController::class, 'deleteEmergencyContact']);

    // Driver routes
    Route::get('/driver/rides', [RideController::class, 'getDriverRides']);
    Route::get('/driver/ride-history', [RideController::class, 'getDriverRideHistory']);
    Route::get('/driver/ride-requests', [RideController::class, 'getRideRequests']);
    
    // Ride routes
    Route::post('/ride/update-status', [RideController::class, 'updateRideStatus']);
    Route::post('/ride', [RideController::class, 'store']);
    Route::post('/ride/book', [RideController::class, 'bookRide']);
    Route::post('/ride/cancel', [RideController::class, 'cancelRide']);
    Route::post('/ride/estimate-fare', [RideController::class, 'estimateFare']);
    Route::post('/driver/accept-ride', [RideController::class, 'acceptRide']);
    Route::post('/driver/reject-ride', [RideController::class, 'rejectRide']);
    Route::post('/driver/update-location', [RideController::class, 'updateDriverLocation']);
});
