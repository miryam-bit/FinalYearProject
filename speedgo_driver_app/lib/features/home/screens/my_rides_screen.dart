import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://192.168.10.60:8000/api/driver/rides'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: Raw API response: $data'); // Debug print

        List<Map<String, dynamic>> rides = [];

        // Handle different possible response formats
        dynamic ridesData;
        if (data is Map) {
          ridesData = data['rides'];
        } else if (data is List) {
          ridesData = data;
        } else {
          ridesData = [];
        }

        print(
          'DEBUG: Rides data type: ${ridesData.runtimeType}',
        ); // Debug print
        print('DEBUG: Rides data: $ridesData'); // Debug print

        if (ridesData is List) {
          print('DEBUG: Processing ${ridesData.length} rides'); // Debug print
          for (int i = 0; i < ridesData.length; i++) {
            try {
              var ride = ridesData[i];
              print('DEBUG: Processing ride $i: $ride'); // Debug print

              if (ride is Map) {
                // Ensure all required fields are present and properly typed
                Map<String, dynamic> safeRide = {
                  'id': ride['id']?.toString() ?? '',
                  'customer_name':
                      ride['customer_name']?.toString() ?? 'Unknown',
                  'customer_phone': ride['customer_phone']?.toString() ?? 'N/A',
                  'pickup_location':
                      ride['pickup_location']?.toString() ?? 'N/A',
                  'dropoff_location':
                      ride['dropoff_location']?.toString() ?? 'N/A',
                  'status': ride['status']?.toString() ?? 'pending',
                  'scheduled_at': ride['scheduled_at']?.toString(),
                };
                rides.add(safeRide);
                print('DEBUG: Added safe ride: $safeRide'); // Debug print
              } else {
                print(
                  'DEBUG: Ride $i is not a Map, type: ${ride.runtimeType}',
                ); // Debug print
              }
            } catch (e) {
              print('DEBUG: Error processing ride $i: $e'); // Debug print
              // Continue with next ride
            }
          }
        } else {
          print(
            'DEBUG: Rides data is not a List, type: ${ridesData.runtimeType}',
          ); // Debug print
        }

        setState(() {
          _rides = rides;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load rides: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
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
        'My Rides',
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _fetchRides,
          icon: const Icon(Icons.refresh, color: Color(0xFF3498DB), size: 20),
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
            'Loading your rides...',
            style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error.isNotEmpty) {
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
                  color: const Color(0xFFE74C3C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE74C3C),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Error Loading Rides',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error,
                style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                title: 'Retry',
                icon: Icons.refresh,
                onTap: _fetchRides,
                isEnabled: true,
                color: const Color(0xFF3498DB),
              ),
            ],
          ),
        ),
      );
    }

    if (_rides.isEmpty) {
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
                  Icons.route,
                  color: Color(0xFF7F8C8D),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Active Rides',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You don\'t have any active rides at the moment.\nCompleted rides are automatically removed from this list.\nCheck ride requests to get started.',
                style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                title: 'View Ride Requests',
                icon: Icons.list,
                onTap: () => Navigator.pushNamed(context, '/ride_requests'),
                isEnabled: true,
                color: const Color(0xFF3498DB),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rides.length,
      itemBuilder: (context, index) {
        if (index >= _rides.length) {
          return const SizedBox.shrink();
        }

        final ride = _rides[index];
        if (ride == null) {
          return const SizedBox.shrink();
        }

        try {
          final status = (ride['status'] ?? 'pending').toString();
          final isScheduled =
              ride['scheduled_at'] != null &&
              ride['scheduled_at'].toString().isNotEmpty;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
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
                                fontWeight: FontWeight.w600,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(status).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                      icon: Icons.schedule,
                      label: 'Scheduled',
                      location: _formatTime(ride['scheduled_at']),
                      color: const Color(0xFFF39C12),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action buttons
                  _buildActionButtons(ride, status, isScheduled),
                ],
              ),
            ),
          );
        } catch (e) {
          print('DEBUG: Error in _buildBody: $e');
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE74C3C).withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Error displaying ride information',
              style: TextStyle(color: Color(0xFFE74C3C)),
            ),
          );
        }
      },
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String location,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: const Color(0xFF7F8C8D),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: location,
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> ride,
    String status,
    bool isScheduled,
  ) {
    try {
      final rideId = ride['id'];
      if (rideId == null || rideId.toString().isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.3)),
          ),
          child: const Text(
            'Invalid ride ID',
            style: TextStyle(color: Color(0xFFE74C3C), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        );
      }

      switch (status) {
        case 'pending':
        case 'accepted':
          final canStart = _canStartRide(ride, isScheduled);
          String buttonTitle = 'Start Ride';
          String? disabledReason;

          if (isScheduled && !canStart) {
            final scheduledAt = ride['scheduled_at'];
            if (scheduledAt != null && scheduledAt.toString().isNotEmpty) {
              try {
                final scheduledTime =
                    DateTime.parse(scheduledAt.toString()).toLocal();
                final formattedTime = _formatTime(scheduledAt.toString());
                buttonTitle = 'Start Ride at $formattedTime';
                disabledReason = 'Ride is scheduled for $formattedTime';
              } catch (e) {
                buttonTitle = 'Start Ride (Scheduled)';
                disabledReason = 'Ride is scheduled for later';
              }
            }
          }

          return Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildActionButton(
                  title: buttonTitle,
                  icon: Icons.play_arrow,
                  onTap:
                      canStart
                          ? () => _updateRideStatus(rideId, 'in_progress')
                          : null,
                  isEnabled: canStart,
                  color: const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Expanded(
                flex: 1,
                child: _buildActionButton(
                  title: 'Cancel',
                  icon: Icons.close,
                  onTap: () => _updateRideStatus(rideId, 'cancelled'),
                  isEnabled: true,
                  color: const Color(0xFFE74C3C),
                ),
              ),
            ],
          );
        case 'in_progress':
          return Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  title: 'Complete Ride',
                  icon: Icons.check_circle,
                  onTap: () => _updateRideStatus(rideId, 'completed'),
                  isEnabled: true,
                  color: const Color(0xFF27AE60),
                ),
              ),
            ],
          );
        case 'completed':
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF27AE60).withOpacity(0.3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 18),
                SizedBox(width: 8),
                Text(
                  'Ride Completed',
                  style: TextStyle(
                    color: Color(0xFF27AE60),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        case 'cancelled':
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE74C3C).withOpacity(0.3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, color: Color(0xFFE74C3C), size: 18),
                SizedBox(width: 8),
                Text(
                  'Ride Cancelled',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        default:
          return const SizedBox.shrink();
      }
    } catch (e) {
      print('DEBUG: Error in _buildActionButtons: $e');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.3)),
        ),
        child: const Text(
          'Error loading actions',
          style: TextStyle(color: Color(0xFFE74C3C), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isEnabled,
    required Color color,
  }) {
    return Container(
      height: 42, // Reduced from 48
      decoration: BoxDecoration(
        color: isEnabled ? color : const Color(0xFFD0D3D4),
        borderRadius: BorderRadius.circular(10), // Reduced from 12
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
          borderRadius: BorderRadius.circular(10), // Reduced from 12
          onTap: isEnabled ? onTap : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? Colors.white : const Color(0xFF7F8C8D),
                  size: 16, // Reduced from 18
                ),
                const SizedBox(width: 4), // Reduced from 6
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : const Color(0xFF7F8C8D),
                      fontSize: 12, // Reduced from 14
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
        return const Color(0xFFE67E22);
      case 'in_progress':
        return const Color(0xFF3498DB);
      case 'completed':
        return const Color(0xFF27AE60);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
        return Icons.schedule;
      case 'in_progress':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  bool _canStartRide(Map<String, dynamic> ride, bool isScheduled) {
    if (!isScheduled) return true;

    try {
      final scheduledAt = ride['scheduled_at'];
      if (scheduledAt == null || scheduledAt.toString().isEmpty) return true;

      print('DEBUG: Checking if ride can start - scheduled time: $scheduledAt');

      final scheduledTime = DateTime.parse(scheduledAt.toString()).toLocal();
      final now = DateTime.now();

      print('DEBUG: Scheduled time (local): $scheduledTime');
      print('DEBUG: Current time (local): $now');
      print(
        'DEBUG: Can start ride: ${now.isAfter(scheduledTime) || now.isAtSameMomentAs(scheduledTime)}',
      );

      // Allow starting if current time is after or at the scheduled time
      return now.isAfter(scheduledTime) || now.isAtSameMomentAs(scheduledTime);
    } catch (e) {
      // If there's an error parsing the date, allow starting the ride
      print('Error parsing scheduled time: $e');
      return true;
    }
  }

  String _formatTime(dynamic isoTime) {
    try {
      if (isoTime == null || isoTime.toString().isEmpty) {
        return 'Not scheduled';
      }

      // Parse UTC time and convert to local
      final dateTime = DateTime.parse(isoTime.toString()).toLocal();

      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      print('Error formatting time: $e');
      return 'Invalid time';
    }
  }

  Future<void> _updateRideStatus(dynamic rideId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Get current phone time
      final now = DateTime.now();
      final currentTime = now.toIso8601String();

      // Convert rideId to string if it's not already
      final rideIdString = rideId.toString();

      final response = await http.post(
        Uri.parse('http://192.168.10.60:8000/api/ride/update-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ride_id': rideIdString,
          'status': status,
          'current_time': currentTime,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // If ride is completed, remove it from the list immediately
          if (status == 'completed') {
            setState(() {
              _rides.removeWhere((ride) {
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
          } else {
            // For other status updates, refresh the list to get updated status
            _fetchRides();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ride ${status} successfully!'),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to update ride status'),
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
              content: Text('Failed to update ride status: ${response.body}'),
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
