import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://192.168.10.60:8000/api/rides'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rides = data['rides'] ?? [];

          setState(() {
            _rides = List<Map<String, dynamic>>.from(rides);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load ride history';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading ride history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ride History',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
        ),
        actions: [
          IconButton(
            onPressed: _loadRideHistory,
            icon: const Icon(Icons.refresh, color: Color(0xFF3498DB)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error.isNotEmpty
              ? _buildErrorState()
              : _buildRideHistory(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              color: const Color(0xFF2C3E50),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error,
            style: TextStyle(color: const Color(0xFF7F8C8D), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRideHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistory() {
    if (_rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7F8C8D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                color: Color(0xFF7F8C8D),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Rides Yet',
              style: TextStyle(
                color: const Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ride history will appear here',
              style: TextStyle(color: const Color(0xFF7F8C8D), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rides.length,
        itemBuilder: (context, index) {
          final ride = _rides[index];
          return _buildRideCard(ride, index);
        },
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, int index) {
    final status = ride['status'] ?? 'unknown';
    final pickup = ride['pickup_location'] ?? 'Unknown';
    final dropoff = ride['dropoff_location'] ?? 'Unknown';
    final fare = ride['fare'] ?? 0.0;
    final createdAt = ride['created_at'] ?? '';
    final scheduledAt = ride['scheduled_at'];
    final driverName = ride['driver']?['name'] ?? 'Unknown Driver';

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
      child: Column(
        children: [
          // Header with status and date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    color: const Color(0xFF7F8C8D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Ride details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup location
                _buildLocationRow(
                  icon: Icons.my_location,
                  label: 'Pickup',
                  location: pickup,
                  color: const Color(0xFF27AE60),
                ),
                const SizedBox(height: 12),

                // Dropoff location
                _buildLocationRow(
                  icon: Icons.location_on,
                  label: 'Dropoff',
                  location: dropoff,
                  color: const Color(0xFFE74C3C),
                ),
                const SizedBox(height: 16),

                // Driver info
                if (driverName != 'Unknown Driver')
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498DB).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF3498DB),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver',
                              style: TextStyle(
                                color: const Color(0xFF7F8C8D),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              driverName,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Fare and actions
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fare',
                            style: TextStyle(
                              color: const Color(0xFF7F8C8D),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$${fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (status == 'completed')
                      ElevatedButton(
                        onPressed: () => _rateRide(ride),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Rate',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: const Color(0xFF7F8C8D), fontSize: 12),
              ),
              Text(
                location,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF27AE60);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      case 'in_progress':
        return const Color(0xFF3498DB);
      case 'accepted':
        return const Color(0xFFF39C12);
      case 'pending':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'accepted':
        return 'ACCEPTED';
      case 'pending':
        return 'PENDING';
      default:
        return 'UNKNOWN';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown Date';
    }
  }

  void _rateRide(Map<String, dynamic> ride) {
    // TODO: Implement rating functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rating feature coming soon!'),
        backgroundColor: const Color(0xFF3498DB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
