import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  List<Map<String, dynamic>> _rideRequests = [];
  String _message = 'Loading...';
  bool _hasActiveRide = false;
  bool _hasScheduledRide = false;
  String? _scheduledRideTime;
  bool _canAcceptRides = true;

  Future<void> fetchRideRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Get current phone time
      final now = DateTime.now();
      final currentTime = now.toIso8601String();

      final response = await http.get(
        Uri.parse(
          'http://192.168.10.60:8000/api/driver/ride-requests?current_time=$currentTime',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rideRequests = List<Map<String, dynamic>>.from(
            data['ride_requests'] ?? [],
          );
          _message = data['message'] ?? 'Available ride requests';
          _hasActiveRide = data['has_active_ride'] ?? false;
          _hasScheduledRide = data['has_scheduled_ride'] ?? false;
          _scheduledRideTime = data['scheduled_ride_time'];
          _canAcceptRides = data['can_accept_rides'] ?? true;
        });
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        final errorMessage = data['message'] ?? 'Access denied';

        if (data['has_active_ride'] == true) {
          // Driver has an active immediate ride
          setState(() {
            _rideRequests = [];
            _message = errorMessage;
            _hasActiveRide = true;
            _hasScheduledRide = false;
            _canAcceptRides = false;
          });
        } else if (data['has_scheduled_ride'] == true) {
          // Driver has a scheduled ride within 1 hour
          setState(() {
            _rideRequests = [];
            _message = errorMessage;
            _hasActiveRide = false;
            _hasScheduledRide = true;
            _scheduledRideTime = data['scheduled_ride_time'];
            _canAcceptRides = false;
          });
        }
      } else {
        setState(() {
          _rideRequests = [];
          _message = 'Failed to load ride requests';
          _hasActiveRide = false;
          _hasScheduledRide = false;
          _canAcceptRides = false;
        });
      }
    } catch (e) {
      setState(() {
        _rideRequests = [];
        _message = 'Error: $e';
        _hasActiveRide = false;
        _hasScheduledRide = false;
        _canAcceptRides = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRideRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              fetchRideRequests();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasActiveRide) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info, color: Colors.blue, size: 64),
            const SizedBox(height: 16),
            const Text(
              'You have an active ride!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your current ride first\nto accept new requests.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/my_rides');
              },
              child: const Text('View My Rides'),
            ),
          ],
        ),
      );
    }

    if (_hasScheduledRide && !_canAcceptRides) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Scheduled Ride Conflict!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have a scheduled ride at $_scheduledRideTime.\nYou cannot accept new rides within 1 hour of your scheduled ride.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/my_rides');
              },
              child: const Text('View My Rides'),
            ),
          ],
        ),
      );
    }

    if (_hasScheduledRide && _canAcceptRides) {
      // Show warning banner for scheduled ride that's more than 1 hour away
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange[100],
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have a scheduled ride at $_scheduledRideTime. You can still accept other rides.',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildRideRequestsList()),
        ],
      );
    }

    return _buildRideRequestsList();
  }

  Widget _buildRideRequestsList() {
    if (_rideRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_taxi, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              _message,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _rideRequests.length,
      itemBuilder: (context, index) {
        final ride = _rideRequests[index];
        final isScheduled = ride['scheduled_at'] != null;

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: isScheduled ? 4 : 2,
          color: isScheduled ? Colors.orange[50] : Colors.white,
          child: Container(
            decoration:
                isScheduled
                    ? BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    )
                    : null,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer: ${ride['customer_name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isScheduled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'SCHEDULED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Phone: ${ride['customer_phone']}'),
                const SizedBox(height: 8),
                Text('Pickup: ${ride['pickup_location']}'),
                const SizedBox(height: 4),
                Text('Dropoff: ${ride['dropoff_location']}'),
                if (isScheduled) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled: ${_formatTime(ride['scheduled_at'])}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _canAcceptRides
                                ? () => _acceptRide(ride['id'])
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isScheduled ? 'Accept Scheduled' : 'Accept',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _rejectRide(ride['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _acceptRide(int rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Get current phone time
      final now = DateTime.now();
      final currentTime = now.toIso8601String();

      final response = await http.post(
        Uri.parse('http://192.168.10.60:8000/api/driver/accept-ride'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ride_id': rideId, 'current_time': currentTime}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride accepted successfully!')),
          );
          // Redirect to home page after accepting ride
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept ride: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectRide(int rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('http://192.168.10.60:8000/api/driver/reject-ride'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ride_id': rideId}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ride rejected')));
          setState(() {}); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject ride: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
