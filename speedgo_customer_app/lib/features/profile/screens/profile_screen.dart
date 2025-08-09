import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_bloc.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_event.dart';
import 'package:speedgo_customer_app/features/profile/screens/ride_history_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/settings_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/edit_profile_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/emergency_contacts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  int _totalRides = 0;
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadRideStats();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://192.168.10.60:8000/api/customer'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _userProfile = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRideStats() async {
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
            _totalRides = rides.length;
            _totalSpent = rides.fold(
              0.0,
              (sum, ride) => sum + (ride['fare'] ?? 0.0),
            );
          });
        }
      }
    } catch (e) {
      print('Error loading ride stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: const Icon(Icons.settings, color: Color(0xFF3498DB), size: 20),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Stats Cards
          _buildStatsSection(),
          const SizedBox(height: 24),

          // Menu Items
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3498DB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile?['name'] ?? 'User Name',
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?['phone'] ?? 'Phone Number',
                  style: const TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF27AE60).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: Color(0xFF27AE60),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
            icon: const Icon(Icons.edit, color: Color(0xFF3498DB), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_taxi,
            title: 'Total Rides',
            value: _totalRides.toString(),
            color: const Color(0xFF3498DB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            title: 'Total Spent',
            value: '\$${_totalSpent.toStringAsFixed(2)}',
            color: const Color(0xFF27AE60),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
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
          _buildMenuItem(
            icon: Icons.history,
            title: 'Ride History',
            subtitle: 'View your past rides',
            onTap: () => Navigator.pushNamed(context, '/ride-history'),
            showDivider: true,
          ),
          _buildMenuItem(
            icon: Icons.contacts,
            title: 'Emergency Contacts',
            subtitle: 'Manage your emergency contacts',
            onTap: () => Navigator.pushNamed(context, '/emergency-contacts'),
            showDivider: true,
          ),
          _buildMenuItem(
            icon: Icons.payment,
            title: 'Payment Methods',
            subtitle: 'Manage your payment options',
            onTap: () => _showComingSoon(),
            showDivider: true,
          ),
          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () => _showComingSoon(),
            showDivider: true,
          ),
          _buildMenuItem(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () => _showComingSoon(),
            showDivider: true,
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () => _showComingSoon(),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF3498DB), size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF7F8C8D),
            size: 16,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: Color(0xFFE0E0E0),
          ),
      ],
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This feature is coming soon!'),
        backgroundColor: const Color(0xFF3498DB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
