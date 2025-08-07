import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  Future<List<Map<String, dynamic>>> fetchRides() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('http://192.168.10.60:8000/api/driver/rides'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List rides = jsonDecode(response.body);
      return rides.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load rides');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rides')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rides available'));
          }
          final rides = snapshot.data!;
          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return ListTile(
                title: Text('Pickup: ${ride['pickup_location']}'),
                subtitle: Text(
                  'Dropoff: ${ride['dropoff_location']}\nStatus: ${ride['status']}',
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement ride status update
                  },
                  child: const Text('Update Status'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
