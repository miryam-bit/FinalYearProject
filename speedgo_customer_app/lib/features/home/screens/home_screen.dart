import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_bloc.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_event.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_state.dart';
import 'package:speedgo_customer_app/auth/screens/login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedgo_customer_app/features/home/models/stop_model.dart';
import 'package:speedgo_customer_app/features/home/widgets/ride_booking_panel.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  PolylinePoints polylinePoints = PolylinePoints(
    apiKey: "AIzaSyDUAPMhKz0uqqwkVoWTdwpb0U9QSlpYHqE",
  );

  final List<Stop> _stops = [];
  final List<TextEditingController> _controllers = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _availableDrivers = [];
  Map<String, dynamic>? _selectedDriver;
  DateTime? _scheduledTime;

  // Panel Controller
  final PanelController _panelController = PanelController();
  bool _isPanelOpen = true;

  // Custom Marker Icons
  BitmapDescriptor _pickupMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _stopMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _dropoffMarker = BitmapDescriptor.defaultMarker;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _setMarkerIcons();
    _addInitialStops();
    _determinePosition();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setMarkerIcons() async {
    _pickupMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/pickup_marker.png',
    );
    _stopMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/stop_marker.png',
    );
    _dropoffMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/dropoff_marker.png',
    );
  }

  void _addInitialStops() {
    setState(() {
      _stops.add(Stop(id: const Uuid().v4())); // For pickup
      _controllers.add(TextEditingController());
      _stops.add(Stop(id: const Uuid().v4())); // For destination
      _controllers.add(TextEditingController());
    });
  }

  void _addStop() {
    setState(() {
      _stops.insert(_stops.length - 1, Stop(id: const Uuid().v4()));
      _controllers.insert(_controllers.length - 1, TextEditingController());
    });
  }

  Future<void> _determinePosition() async {
    final GoogleMapController controller = await _controller.future;
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    Position position = await Geolocator.getCurrentPosition();
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      var p = placemarks.first;
      String address = "${p.name}, ${p.street}";
      setState(() {
        _stops[0].prediction = Prediction.fromJson({
          "description": address,
          "place_id": const Uuid().v4(),
          "lat": position.latitude.toString(),
          "lng": position.longitude.toString(),
          "types": [],
        });
        _controllers[0].text = address;
      });
      _drawRoute();
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final apiKey = "AIzaSyDUAPMhKz0uqqwkVoWTdwpb0U9QSlpYHqE";
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        return {'lat': location['lat'], 'lng': location['lng']};
      }
    }
    return null;
  }

  void _onStopSelected(int index, Prediction prediction) async {
    print('=== LOCATION SELECTION DEBUG ===');
    print('Stop index: $index');
    print('Prediction description: "${prediction.description}"');
    print('Prediction place_id: "${prediction.placeId}"');

    // First, immediately set the prediction with available data
    setState(() {
      _stops[index].prediction = Prediction.fromJson({
        "description": prediction.description ?? "Unknown Location",
        "place_id": prediction.placeId ?? "",
        "lat": prediction.lat ?? "0",
        "lng": prediction.lng ?? "0",
        "types": prediction.types ?? [],
      });
    });

    // Update the controller text
    _controllers[index].text = prediction.description ?? "";

    print('Immediately set prediction for stop $index');
    print('Updated controller text: "${_controllers[index].text}"');

    // Then try to get more detailed coordinates if we have a place_id
    if (prediction.placeId != null && prediction.placeId!.isNotEmpty) {
      final details = await getPlaceDetails(prediction.placeId!);
      if (details != null) {
        setState(() {
          _stops[index].prediction = Prediction.fromJson({
            "description": prediction.description ?? "Unknown Location",
            "place_id": prediction.placeId,
            "lat": details['lat'].toString(),
            "lng": details['lng'].toString(),
            "types": prediction.types ?? [],
          });
        });
        print(
          'Updated with detailed coordinates: ${details['lat']}, ${details['lng']}',
        );
      } else {
        print('Failed to get place details for: ${prediction.description}');
      }
    } else {
      print('No place_id available, using basic prediction data');
    }

    _drawRoute();
  }

  void _getFare() {
    // We will implement this next
    print("Getting fare for ${_stops.length} stops");
  }

  Future<void> _fetchAvailableDrivers(LatLng pickupLocation) async {
    print(
      'Pickup location: ${pickupLocation.latitude}, ${pickupLocation.longitude}',
    ); // Debug print
    final response = await http.get(
      Uri.parse('http://192.168.10.60:8000/api/drivers'),
    );
    if (response.statusCode == 200) {
      final List drivers = jsonDecode(response.body);
      List<Map<String, dynamic>> driversWithDistance = [];

      for (var driver in drivers) {
        final lat = driver['latitude'];
        final lng = driver['longitude'];
        if (lat == null || lng == null) continue;
        final driverLat = lat is String ? double.tryParse(lat) : lat;
        final driverLng = lng is String ? double.tryParse(lng) : lng;
        if (driverLat == null || driverLng == null) continue;

        final distance = _calculateDistance(
          pickupLocation.latitude,
          pickupLocation.longitude,
          driverLat,
          driverLng,
        );

        print('Driver: ${driver['name']}, Lat: $driverLat, Lng: $driverLng');
        print('Distance to pickup: $distance km');

        // Add distance to driver data
        Map<String, dynamic> driverWithDistance = Map<String, dynamic>.from(
          driver,
        );
        driverWithDistance['distance'] = distance;
        driversWithDistance.add(driverWithDistance);
      }

      // Sort drivers by distance (closest to farthest)
      driversWithDistance.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      print('Sorted drivers by distance: $driversWithDistance'); // Debug print
      setState(() {
        _availableDrivers = driversWithDistance;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  void _showDriverSelectionDialog() async {
    if (_availableDrivers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No drivers available.')));
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Driver'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableDrivers.length,
              itemBuilder: (context, index) {
                final driver = _availableDrivers[index];
                final distance = driver['distance'] as double?;
                final isTooFar = distance != null && distance >= 3.0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isTooFar
                            ? Colors.orange
                            : (index == 0 ? Colors.green : Colors.blue),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    driver['name'] ?? 'Unknown',
                    style: TextStyle(
                      color: isTooFar ? Colors.orange[800] : null,
                      fontWeight: isTooFar ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone: ${driver['phone']}',
                        style: TextStyle(
                          color: isTooFar ? Colors.orange[600] : null,
                        ),
                      ),
                      if (distance != null)
                        Text(
                          isTooFar
                              ? 'Distance: ${distance.toStringAsFixed(2)} km - Far away (selectable)'
                              : 'Distance: ${distance.toStringAsFixed(2)} km',
                          style: TextStyle(
                            color:
                                isTooFar
                                    ? Colors.orange
                                    : (index == 0
                                        ? Colors.green
                                        : Colors.grey[600]),
                            fontWeight:
                                isTooFar
                                    ? FontWeight.bold
                                    : (index == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal),
                          ),
                        ),
                    ],
                  ),
                  onTap:
                      () => Navigator.of(
                        context,
                      ).pop(driver), // Allow selecting any driver
                );
              },
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _selectedDriver = selected;
      });
    }
  }

  // Call _showDriverSelectionDialog before booking a ride, and require _selectedDriver to be set.

  Future<void> _bookRide() async {
    print('Book ride function called');

    // Check if we have valid locations first
    if (_stops.isEmpty || _stops.first.prediction == null) {
      print('Returning early: No pickup location selected!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location.')),
      );
      return;
    }

    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and dropoff locations.'),
        ),
      );
      return;
    }

    // Validate scheduled time if set
    if (_scheduledTime != null) {
      final now = DateTime.now();
      if (_scheduledTime!.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot schedule rides for past times. Please select a future time.',
            ),
          ),
        );
        return;
      }

      // Check if it's at least 15 minutes in the future
      final minimumTime = now.add(const Duration(minutes: 15));
      if (_scheduledTime!.isBefore(minimumTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please schedule rides at least 15 minutes in advance.',
            ),
          ),
        );
        return;
      }
    }

    final pickup = _stops.first.prediction;
    final dropoff = _stops.last.prediction;
    print('=== BOOKING DEBUG ===');
    print('Number of stops: ${_stops.length}');
    print('Pickup prediction: $pickup');
    print('Dropoff prediction: $dropoff');
    print('Pickup description: "${pickup?.description}"');
    print('Dropoff description: "${dropoff?.description}"');
    print('Pickup lat/lng: ${pickup?.lat}/${pickup?.lng}');
    print('Dropoff lat/lng: ${dropoff?.lat}/${dropoff?.lng}');

    if (pickup == null || dropoff == null) {
      print('Returning early: Pickup or dropoff prediction is null.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid locations.')),
      );
      return;
    }

    // Ensure we have valid location strings
    final pickupLocation = pickup.description?.trim();
    final dropoffLocation = dropoff.description?.trim();

    print('Trimmed pickup location: "$pickupLocation"');
    print('Trimmed dropoff location: "$dropoffLocation"');

    // Fallback: use controller text if prediction description is empty
    final finalPickupLocation =
        (pickupLocation == null || pickupLocation.isEmpty)
            ? _controllers[0].text.trim()
            : pickupLocation;
    final finalDropoffLocation =
        (dropoffLocation == null || dropoffLocation.isEmpty)
            ? _controllers[1].text.trim()
            : dropoffLocation;

    print('Final pickup location: "$finalPickupLocation"');
    print('Final dropoff location: "$finalDropoffLocation"');

    if (finalPickupLocation.isEmpty || finalDropoffLocation.isEmpty) {
      print('Returning early: Final pickup or dropoff location is empty.');
      print('Final pickup location empty: ${finalPickupLocation.isEmpty}');
      print('Final dropoff location empty: ${finalDropoffLocation.isEmpty}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid locations with proper addresses.'),
        ),
      );
      return;
    }

    final stops =
        _stops
            .sublist(1, _stops.length - 1)
            .where((s) => s.prediction != null)
            .map(
              (s) => {
                'latitude': double.parse(s.prediction!.lat!),
                'longitude': double.parse(s.prediction!.lng!),
              },
            )
            .toList();

    // Convert scheduled time to UTC before sending
    // Since we're in UTC+3, we need to subtract 3 hours to get UTC time
    final scheduledTimeUTC = _scheduledTime?.subtract(
      Duration(hours: DateTime.now().timeZoneOffset.inHours),
    );
    print('DEBUG - Original scheduled time (local): ${_scheduledTime}');
    print('DEBUG - Converted to UTC: ${scheduledTimeUTC}');

    final body = {
      'pickup_location': finalPickupLocation,
      'dropoff_location': finalDropoffLocation,
      'scheduled_at': scheduledTimeUTC?.toIso8601String(), // UTC time
      'current_time': DateTime.now().toUtc().toIso8601String(), // UTC time
      'timezone_offset':
          DateTime.now().timeZoneOffset.inHours, // Send timezone offset
      'vehicle_type': 'standard', // Or let user choose
      'payment_method': 'cash', // Or let user choose
      'stops': stops,
      // Remove driver_id - let driver accept the request instead
    };

    print('Sending booking request with body: ${jsonEncode(body)}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('DEBUG - Token: ${token != null ? "Present" : "Missing"}');

    final response = await http.post(
      Uri.parse('http://192.168.10.60:8000/api/ride/book'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('DEBUG - Response status: ${response.statusCode}');
    print('DEBUG - Response body: ${response.body}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request created! Drivers will be notified.'),
        ),
      );
      // Clear the selected driver since we're not assigning one immediately
      setState(() {
        _selectedDriver = null;
      });
    } else if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route not found. Please check your connection.'),
        ),
      );
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please login again.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create ride request: ${response.body}'),
        ),
      );
    }
  }

  Future<void> _drawRoute() async {
    _markers.clear();
    _polylines.clear();
    List<LatLng> routePoints = [];

    print('--- Drawing Markers ---');
    for (int i = 0; i < _stops.length; i++) {
      print(
        'Stop $i: ${_stops[i].prediction?.description} | lat: ${_stops[i].prediction?.lat} | lng: ${_stops[i].prediction?.lng}',
      );
      var stop = _stops[i];
      if (stop.prediction != null &&
          stop.prediction!.lat != null &&
          stop.prediction!.lng != null) {
        var lat = double.tryParse(stop.prediction!.lat!);
        var lng = double.tryParse(stop.prediction!.lng!);
        if (lat != null && lng != null) {
          routePoints.add(LatLng(lat, lng));
          BitmapDescriptor icon;
          if (i == 0) {
            icon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ); // Pickup
          } else if (i == _stops.length - 1) {
            icon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ); // Dropoff
          } else {
            icon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ); // Stop
          }
          _markers.add(
            Marker(
              markerId: MarkerId(stop.id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: stop.prediction!.description),
              icon: icon,
            ),
          );
        }
      }
    }

    if (routePoints.length > 1) {
      // Try as named parameter
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(
            routePoints.first.latitude,
            routePoints.first.longitude,
          ),
          destination: PointLatLng(
            routePoints.last.latitude,
            routePoints.last.longitude,
          ),
          mode: TravelMode.driving,
          wayPoints:
              routePoints.length > 2
                  ? routePoints
                      .sublist(1, routePoints.length - 1)
                      .map(
                        (p) => PolylineWayPoint(
                          location: "${p.latitude},${p.longitude}",
                        ),
                      )
                      .toList()
                  : [],
        ),
      );
      // If the above fails, try as positional argument:
      // PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      //   PolylineRequest(
      //     origin: PointLatLng(routePoints.first.latitude, routePoints.first.longitude),
      //     destination: PointLatLng(routePoints.last.latitude, routePoints.last.longitude),
      //     mode: TravelMode.driving,
      //   ),
      // );
      print('PolylineResult status: ${result.status}');
      print('PolylineResult errorMessage: ${result.errorMessage}');
      print('PolylineResult points: ${result.points}');

      if (result.points.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blueAccent,
            points:
                result.points
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
            width: 6,
          ),
        );
      }

      final GoogleMapController controller = await _controller.future;
      LatLngBounds bounds = _boundsFromLatLngList(routePoints);
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
    } else if (routePoints.length == 1) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(routePoints.first, 15),
      );
    }
    setState(() {});
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.motorcycle,
              color: Color(0xFF3498DB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'SpeedGo',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/profile'),
          icon: const Icon(Icons.person, color: Color(0xFF3498DB), size: 20),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _showLogoutDialog,
          icon: const Icon(Icons.logout, color: Color(0xFFE74C3C), size: 20),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Logout',
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

  void _logout() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // Map
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          initialCameraPosition: _kGooglePlex,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        // Ride Booking Panel
        SlidingUpPanel(
          controller: _panelController,
          minHeight: 100,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          backdropEnabled: true,
          backdropOpacity: 0.3,
          backdropColor: const Color(0xFF2C3E50),
          panel: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Panel Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Panel Content
                Expanded(
                  child: RideBookingPanel(
                    stops: _stops,
                    controllers: _controllers,
                    onStopSelected: _onStopSelected,
                    onAddStop: _addStop,
                    onGetFare: _getFare,
                    onBookRide: _bookRide,
                    onScheduledTimeChanged: (time) {
                      setState(() {
                        _scheduledTime = time;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // My Location Button
        Positioned(
          bottom: 120,
          right: 16,
          child: FloatingActionButton(
            onPressed: _determinePosition,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Color(0xFF3498DB)),
          ),
        ),
      ],
    );
  }
}
