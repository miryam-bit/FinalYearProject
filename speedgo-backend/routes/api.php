

<?php
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\RideController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\FeedbackController;
use App\Http\Controllers\Api\EmergencyContactController;
use App\Http\Controllers\Api\SosController;

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;


Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);

});


Route::middleware('auth:sanctum')->group(function () {

    // Customer Profile
    Route::get('/customer', [CustomerController::class, 'profile']);
    Route::put('/customer/update', [CustomerController::class, 'update']);




    // Rides
    Route::middleware('auth:sanctum')->group(function () {
    Route::post('/ride/book', [RideController::class, 'bookRide']);
    Route::post('/ride/cancel', [RideController::class, 'cancelRide']);
    Route::get('/rides', [RideController::class, 'rideHistory']);
    Route::post('/ride/send-invoice', [RideController::class, 'sendInvoice']); // ✅
    Route::post('/ride/estimate-fare', [RideController::class, 'estimateFare']); // ✅
    });

    // Transactions
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/transactions', [TransactionController::class, 'index']);
        Route::post('/wallet/add', [TransactionController::class, 'addFunds']);
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/emergency-contacts', [EmergencyContactController::class, 'index']);
        Route::post('/emergency-contacts', [EmergencyContactController::class, 'store']);
        Route::delete('/emergency-contacts/{id}', [EmergencyContactController::class, 'destroy']);
    });
    Route::post('/sos/trigger', [SosController::class, 'trigger']);

    // Feedback
    Route::post('/feedback', [FeedbackController::class, 'store']);
});
