<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class Ride extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'pickup_location',
        'dropoff_location',
        'stops',
        'vehicle_type',
        'payment_method',
        'status',
        'scheduled_at',
        'driver_id',
    ];

    protected $casts = [
        'stops'        => 'array',
        'scheduled_at' => 'datetime',
    ];

    
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}
