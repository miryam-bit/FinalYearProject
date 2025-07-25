<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Transaction;
use Illuminate\Support\Facades\Auth;

class TransactionController extends Controller
{
    public function index()
    {
        $transactions = Transaction::where('user_id', Auth::id())
                                   ->orderBy('created_at', 'desc')
                                   ->get();

        return response()->json($transactions);
    }


    public function addFunds(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'method' => 'required|string', // e.g. Stripe, Paystack
        ]);

        $transaction = Transaction::create([
            'user_id'   => Auth::id(),
            'amount'    => $request->amount,
            'method'    => $request->method,
            'status'    => 'success', // or 'pending' if async
            'reference' => 'TXN-' . strtoupper(uniqid()),
        ]);

        return response()->json([
            'message'     => 'Funds added successfully',
            'transaction' => $transaction
        ]);
    }
}
