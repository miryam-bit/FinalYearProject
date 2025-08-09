import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://192.168.10.60:8000/api/emergency-contacts'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _contacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load emergency contacts';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading emergency contacts: $e';
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
          'Emergency Contacts',
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
            onPressed: () => _showAddContactDialog(),
            icon: const Icon(Icons.add, color: Color(0xFF3498DB)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error.isNotEmpty
              ? _buildErrorState()
              : _buildContactsList(),
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
            onPressed: _loadEmergencyContacts,
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

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
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
                Icons.contacts,
                color: Color(0xFF7F8C8D),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Emergency Contacts',
              style: TextStyle(
                color: const Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add emergency contacts for safety',
              style: TextStyle(color: const Color(0xFF7F8C8D), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddContactDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Contact',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmergencyContacts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return _buildContactCard(contact, index);
        },
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, int index) {
    final name = contact['name'] ?? 'Unknown';
    final phone = contact['phone'] ?? 'No phone';
    final relationship = contact['relationship'] ?? 'Contact';

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
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emergency,
            color: Color(0xFFE74C3C),
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phone,
              style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
            ),
            Text(
              relationship,
              style: const TextStyle(
                color: Color(0xFF3498DB),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF7F8C8D)),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditContactDialog(contact, index);
            } else if (value == 'delete') {
              _showDeleteContactDialog(contact, index);
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF3498DB), size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Color(0xFFE74C3C), size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF7F8C8D)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addContact(
                  nameController.text,
                  phoneController.text,
                  relationshipController.text,
                );
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFF3498DB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditContactDialog(Map<String, dynamic> contact, int index) {
    final nameController = TextEditingController(text: contact['name']);
    final phoneController = TextEditingController(text: contact['phone']);
    final relationshipController = TextEditingController(
      text: contact['relationship'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Emergency Contact',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF7F8C8D)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateContact(
                  contact['id'],
                  nameController.text,
                  phoneController.text,
                  relationshipController.text,
                );
              },
              child: const Text(
                'Update',
                style: TextStyle(
                  color: Color(0xFF3498DB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteContactDialog(Map<String, dynamic> contact, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Contact',
            style: TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${contact['name']}?',
            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF7F8C8D)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteContact(contact['id']);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addContact(
    String name,
    String phone,
    String relationship,
  ) async {
    if (name.isEmpty || phone.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final response = await http.post(
          Uri.parse('http://192.168.10.60:8000/api/emergency-contacts'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'phone': phone,
            'relationship': relationship,
          }),
        );

        if (response.statusCode == 201) {
          _showSuccess('Contact added successfully');
          _loadEmergencyContacts();
        } else {
          final data = jsonDecode(response.body);
          _showError(data['message'] ?? 'Failed to add contact');
        }
      }
    } catch (e) {
      _showError('Error adding contact: $e');
    }
  }

  Future<void> _updateContact(
    String id,
    String name,
    String phone,
    String relationship,
  ) async {
    if (name.isEmpty || phone.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final response = await http.put(
          Uri.parse('http://192.168.10.60:8000/api/emergency-contacts/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'phone': phone,
            'relationship': relationship,
          }),
        );

        if (response.statusCode == 200) {
          _showSuccess('Contact updated successfully');
          _loadEmergencyContacts();
        } else {
          final data = jsonDecode(response.body);
          _showError(data['message'] ?? 'Failed to update contact');
        }
      }
    } catch (e) {
      _showError('Error updating contact: $e');
    }
  }

  Future<void> _deleteContact(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final response = await http.delete(
          Uri.parse('http://192.168.10.60:8000/api/emergency-contacts/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          _showSuccess('Contact deleted successfully');
          _loadEmergencyContacts();
        } else {
          final data = jsonDecode(response.body);
          _showError(data['message'] ?? 'Failed to delete contact');
        }
      }
    } catch (e) {
      _showError('Error deleting contact: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
