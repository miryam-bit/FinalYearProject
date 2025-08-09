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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchRideRequests();
  }

  Future<void> fetchRideRequests() async {
    setState(() {
      _loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Get current phone time
      final now = DateTime.now();
      final currentTime = now.toIso8601String();
      final timezoneOffset = now.timeZoneOffset.inHours;

      final response = await http.get(
        Uri.parse(
          'http://192.168.10.60:8000/api/driver/ride-requests?current_time=$currentTime&timezone_offset=$timezoneOffset',
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
          _hasActiveRide = data['has_active_ride'] ?? false;
          _hasScheduledRide = data['has_scheduled_ride'] ?? false;
          _scheduledRideTime = data['scheduled_ride_time'];
          _canAcceptRides = data['can_accept_rides'] ?? true;
          _message = data['message'] ?? 'No ride requests available';
          _loading = false;
        });
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        setState(() {
          _hasActiveRide = data['has_active_ride'] ?? false;
          _hasScheduledRide = data['has_scheduled_ride'] ?? false;
          _scheduledRideTime = data['scheduled_ride_time'];
          _canAcceptRides = data['can_accept_rides'] ?? false;
          _message = data['message'] ?? 'Cannot accept rides at this time';
          _loading = false;
        });
      } else {
        setState(() {
          _message = 'Failed to load ride requests';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _loading ? _buildLoadingState() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF2C3E50),
          size: 20,
        ),
      ),
      title: const Text(
        'Ride Requests',
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: fetchRideRequests,
          icon: const Icon(
            Icons.refresh,
            color: Color(0xFF3498DB),
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading ride requests...',
            style: TextStyle(
              color: Color(0xFF7F8C8D),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_hasActiveRide) {
      return _buildActiveRideMessage();
    }

    if (_hasScheduledRide && !_canAcceptRides) {
      return _buildScheduledRideConflict();
    }

    if (_hasScheduledRide && _canAcceptRides) {
      return Column(
        children: [
          _buildScheduledRideWarning(),
          Expanded(child: _buildRideRequestsList()),
        ],
      );
    }

    return _buildRideRequestsList();
  }

  Widget _buildActiveRideMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C3E50).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3498DB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF3498DB),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Active Ride in Progress',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your current ride first\nto accept new requests.',
              style: TextStyle(
                color: const Color(0xFF7F8C8D),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              title: 'View My Rides',
              icon: Icons.route,
              onTap: () => Navigator.pushNamed(context, '/my_rides'),
              isEnabled: true,
              color: const Color(0xFF3498DB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledRideConflict() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C3E50).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE67E22).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFFE67E22),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scheduled Ride Conflict',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You have a scheduled ride at $_scheduledRideTime.\nYou cannot accept new rides within 1 hour.',
              style: TextStyle(
                color: const Color(0xFF7F8C8D),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              title: 'View My Rides',
              icon: Icons.route,
              onTap: () => Navigator.pushNamed(context, '/my_rides'),
              isEnabled: true,
              color: const Color(0xFF3498DB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledRideWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE67E22).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE67E22).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFFE67E22),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message.contains('has passed')
                  ? 'Your scheduled ride time has passed. You can now accept other rides.'
                  : 'You have a scheduled ride at $_scheduledRideTime. You can still accept other rides.',
              style: const TextStyle(
                color: Color(0xFFE67E22),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestsList() {
    if (_rideRequests.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C3E50).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F8C8D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_taxi,
                  color: Color(0xFF7F8C8D),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                style: const TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rideRequests.length,
      itemBuilder: (context, index) {
        final ride = _rideRequests[index];
        final isScheduled = ride['scheduled_at'] != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C3E50).withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with customer info and scheduled badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isScheduled
                                ? const Color(0xFFE67E22).withOpacity(0.1)
                                : const Color(0xFF3498DB).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isScheduled ? Icons.schedule : Icons.person,
                        color:
                            isScheduled
                                ? const Color(0xFFE67E22)
                                : const Color(0xFF3498DB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer: ${ride['customer_name']}',
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Phone: ${ride['customer_phone']}',
                            style: const TextStyle(
                              color: Color(0xFF7F8C8D),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isScheduled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E22).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'SCHEDULED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location details
                _buildLocationRow(
                  icon: Icons.location_on,
                  label: 'Pickup',
                  location: ride['pickup_location'],
                  color: const Color(0xFF27AE60),
                ),
                const SizedBox(height: 8),
                _buildLocationRow(
                  icon: Icons.location_off,
                  label: 'Dropoff',
                  location: ride['dropoff_location'],
                  color: const Color(0xFFE74C3C),
                ),
                if (isScheduled) ...[
                  const SizedBox(height: 8),
                  _buildLocationRow(
                    icon: Icons.access_time,
                    label: 'Scheduled',
                    location: _formatTime(ride['scheduled_at']),
                    color: const Color(0xFFF39C12),
                  ),
                ],
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        title: isScheduled ? 'Accept Scheduled' : 'Accept',
                        icon: Icons.check,
                        onTap:
                            _canAcceptRides
                                ? () => _acceptRide(ride['id'])
                                : null,
                        isEnabled: _canAcceptRides,
                        color: const Color(0xFF27AE60),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        title: 'Reject',
                        icon: Icons.close,
                        onTap: () => _rejectRide(ride['id']),
                        isEnabled: true,
                        color: const Color(0xFFE74C3C),
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

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String location,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              location,
              style: TextStyle(color: const Color(0xFF2C3E50), fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isEnabled,
    required Color color,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: isEnabled ? color : const Color(0xFFD0D3D4),
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isEnabled
                ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnabled ? onTap : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? Colors.white : const Color(0xFF7F8C8D),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : const Color(0xFF7F8C8D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    // Parse UTC time and convert to local
    final dateTime = DateTime.parse(isoTime).toLocal();
    print(
      'DEBUG - Formatting time: UTC=$isoTime, Local=${dateTime.toString()}',
    );

    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _acceptRide(dynamic rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Get current phone time
      final now = DateTime.now();
      final currentTime = now.toIso8601String();
      final timezoneOffset = now.timeZoneOffset.inHours;

      // Convert rideId to string for API call
      final rideIdString = rideId.toString();

      final response = await http.post(
        Uri.parse('http://192.168.10.60:8000/api/driver/accept-ride'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ride_id': rideIdString,
          'current_time': currentTime,
          'timezone_offset': timezoneOffset,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ride accepted successfully!'),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Redirect to home page after accepting ride
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to accept ride'),
              backgroundColor: const Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept ride: ${response.body}'),
              backgroundColor: const Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _rejectRide(dynamic rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Convert rideId to string for API call
      final rideIdString = rideId.toString();

      final response = await http.post(
        Uri.parse('http://192.168.10.60:8000/api/driver/reject-ride'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ride_id': rideIdString}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // Remove the rejected ride from the list immediately
          setState(() {
            _rideRequests.removeWhere((ride) {
              final rideIdFromList = ride['id'];
              // Handle both string and int types
              if (rideIdFromList is int) {
                return rideIdFromList == int.tryParse(rideIdString);
              } else if (rideIdFromList is String) {
                return rideIdFromList == rideIdString;
              }
              return false;
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ride rejected'),
              backgroundColor: const Color(0xFFE67E22),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject ride: ${response.body}'),
              backgroundColor: const Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
