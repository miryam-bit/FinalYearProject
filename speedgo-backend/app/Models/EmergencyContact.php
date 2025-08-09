<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmergencyContact extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'name',
        'phone',
        'relationship',
    ];

    /**
     * Get the customer that owns the emergency contact.
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }
}
