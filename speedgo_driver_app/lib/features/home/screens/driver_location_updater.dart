import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DriverLocationUpdater extends StatefulWidget {
  const DriverLocationUpdater({super.key});

  @override
  State<DriverLocationUpdater> createState() => _DriverLocationUpdaterState();
}

class _DriverLocationUpdaterState extends State<DriverLocationUpdater> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print('DriverLocationUpdater initialized'); // Debug print
    _startUpdatingLocation();
  }

  void _startUpdatingLocation() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateLocation());
    _updateLocation(); // Update immediately on start
  }

  Future<void> _updateLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    if (!serviceEnabled) return;

    final position = await Geolocator.getCurrentPosition();
    print('Sending location: ${position.latitude}, ${position.longitude}'); // Debug print
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    await http.post(
      Uri.parse('http://192.168.10.81:8000/api/driver/update-location'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: '{"latitude": ${position.latitude}, "longitude": ${position.longitude}}',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Invisible widget
  }
} 