import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingsSection(
              title: 'App Preferences',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Push Notifications',
                  subtitle: 'Receive ride updates and promotions',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.location_on,
                  title: 'Location Services',
                  subtitle: 'Allow app to access your location',
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme (coming soon)',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    _showComingSoon();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'Account',
              children: [
                _buildListTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => _showComingSoon(),
                ),
                _buildListTile(
                  icon: Icons.delete,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  onTap: () => _showDeleteAccountDialog(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'Support',
              children: [
                _buildListTile(
                  icon: Icons.help,
                  title: 'Help Center',
                  subtitle: 'Get help and find answers',
                  onTap: () => _showComingSoon(),
                ),
                _buildListTile(
                  icon: Icons.contact_support,
                  title: 'Contact Support',
                  subtitle: 'Get in touch with our team',
                  onTap: () => _showComingSoon(),
                ),
                _buildListTile(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF3498DB).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3498DB),
          size: 20,
        ),
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
        style: const TextStyle(
          color: Color(0xFF7F8C8D),
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3498DB),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF3498DB).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3498DB),
          size: 20,
        ),
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
        style: const TextStyle(
          color: Color(0xFF7F8C8D),
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Color(0xFF7F8C8D),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This feature is coming soon!'),
        backgroundColor: const Color(0xFF3498DB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showComingSoon();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'About SpeedGo',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Version: 1.0.0',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SpeedGo is your trusted ride-sharing companion, providing fast and reliable transportation services.',
                style: TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF3498DB),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
