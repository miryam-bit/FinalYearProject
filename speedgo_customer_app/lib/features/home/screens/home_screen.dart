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
  PolylinePoints polylinePoints = PolylinePoints(apiKey: "AIzaSyDUAPMhKz0uqqwkVoWTdwpb0U9QSlpYHqE");

  List<Stop> _stops = [];
  List<TextEditingController> _controllers = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _availableDrivers = [];
  Map<String, dynamic>? _selectedDriver;

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
  
  void _setMarkerIcons() async {
    _pickupMarker = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(48, 48)), 'assets/pickup_marker.png');
    _stopMarker = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(48, 48)), 'assets/stop_marker.png');
    _dropoffMarker = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(48, 48)), 'assets/dropoff_marker.png');
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
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    )));

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
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
    final url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
        };
      }
    }
    return null;
  }

  void _onStopSelected(int index, Prediction prediction) async {
    final details = await getPlaceDetails(prediction.placeId!);
    if (details != null) {
      setState(() {
        _stops[index].prediction = Prediction.fromJson({
          "description": prediction.description,
          "place_id": prediction.placeId,
          "lat": details['lat'].toString(),
          "lng": details['lng'].toString(),
          "types": [],
        });
      });
      _drawRoute();
    }
  }
  
  void _getFare() {
    // We will implement this next
    print("Getting fare for ${_stops.length} stops");
  }

  Future<void> _fetchAvailableDrivers(LatLng pickupLocation) async {
    print('Pickup location: ${pickupLocation.latitude}, ${pickupLocation.longitude}'); // Debug print
    final response = await http.get(Uri.parse('http://192.168.10.81:8000/api/drivers'));
    if (response.statusCode == 200) {
      final List drivers = jsonDecode(response.body);
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
      }
      // Filter drivers by proximity (e.g., within 5km)
      final filtered = drivers.where((driver) {
        final lat = driver['latitude'];
        final lng = driver['longitude'];
        if (lat == null || lng == null) return false;
        final driverLat = lat is String ? double.tryParse(lat) : lat;
        final driverLng = lng is String ? double.tryParse(lng) : lng;
        if (driverLat == null || driverLng == null) return false;
        final distance = _calculateDistance(
          pickupLocation.latitude,
          pickupLocation.longitude,
          driverLat,
          driverLng,
        );
        return distance <= 5.0; // 5 km radius
      }).toList();
      print('Filtered drivers: $filtered'); // Debug print
      setState(() {
        _availableDrivers = List<Map<String, dynamic>>.from(filtered);
      });
      // Removed automatic dialog here
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  void _showDriverSelectionDialog() async {
    if (_availableDrivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No drivers nearby.')));
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Driver'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableDrivers.length,
              itemBuilder: (context, index) {
                final driver = _availableDrivers[index];
                return ListTile(
                  title: Text(driver['name'] ?? 'Unknown'),
                  subtitle: Text('Phone: ${driver['phone']}'),
                  onTap: () => Navigator.of(context).pop(driver),
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
    if (_selectedDriver == null) {
      print('No driver selected, fetching drivers...');
      if (_stops.isEmpty || _stops.first.prediction == null) {
        print('Returning early: No pickup location selected!');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a pickup location.')));
        return;
      }
      final pickupLat = double.tryParse(_stops.first.prediction!.lat ?? '');
      final pickupLng = double.tryParse(_stops.first.prediction!.lng ?? '');
      if (pickupLat == null || pickupLng == null) {
        print('Returning early: Invalid pickup coordinates!');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid pickup location.')));
        return;
      }
      await _fetchAvailableDrivers(LatLng(pickupLat, pickupLng));
      if (_availableDrivers.isEmpty) {
        print('Returning early: No drivers nearby after fetch.');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No drivers nearby.')));
        return;
      }
      print('Showing driver selection dialog with ${_availableDrivers.length} drivers');
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select a Driver'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableDrivers.length,
                itemBuilder: (context, index) {
                  final driver = _availableDrivers[index];
                  return ListTile(
                    title: Text(driver['name'] ?? 'Unknown'),
                    subtitle: Text('Phone: ${driver['phone']}'),
                    onTap: () => Navigator.of(context).pop(driver),
                  );
                },
              ),
            ),
          );
        },
      );
      print('Dialog closed, selected: $selected');
      if (selected != null) {
        setState(() {
          _selectedDriver = selected;
        });
        // Immediately continue booking after selecting driver
        await _bookRide();
        return;
      } else {
        print('Returning early: User cancelled driver selection.');
        return;
      }
    }
    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select pickup and dropoff locations.')));
      return;
    }
    final pickup = _stops.first.prediction;
    final dropoff = _stops.last.prediction;
    print('Pickup prediction: $pickup');
    print('Dropoff prediction: $dropoff');
    print('Pickup description: ${pickup?.description}');
    print('Dropoff description: ${dropoff?.description}');
    if (pickup == null || dropoff == null) {
      print('Returning early: Pickup or dropoff prediction is null.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select valid locations.')));
      return;
    }
    final stops = _stops.sublist(1, _stops.length - 1).where((s) => s.prediction != null).map((s) => {
      'latitude': double.parse(s.prediction!.lat!),
      'longitude': double.parse(s.prediction!.lng!),
    }).toList();
    final body = {
      'pickup_location': pickup.description,
      'dropoff_location': dropoff.description,
      'scheduled_at': null, // Add scheduling if needed
      'vehicle_type': 'standard', // Or let user choose
      'payment_method': 'cash', // Or let user choose
      'stops': stops,
      'driver_id': _selectedDriver!['id'],
    };
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('http://192.168.10.81:8000/api/ride/book'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride booked successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to book ride: ${response.body}')));
    }
  }

  Future<void> _drawRoute() async {
    _markers.clear();
    _polylines.clear();
    List<LatLng> routePoints = [];

    print('--- Drawing Markers ---');
    for (int i = 0; i < _stops.length; i++) {
      print('Stop $i: ${_stops[i].prediction?.description} | lat: ${_stops[i].prediction?.lat} | lng: ${_stops[i].prediction?.lng}');
      var stop = _stops[i];
      if (stop.prediction != null && stop.prediction!.lat != null && stop.prediction!.lng != null) {
        var lat = double.tryParse(stop.prediction!.lat!);
        var lng = double.tryParse(stop.prediction!.lng!);
        if (lat != null && lng != null) {
          routePoints.add(LatLng(lat, lng));
          BitmapDescriptor icon;
          if (i == 0) {
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen); // Pickup
          } else if (i == _stops.length - 1) {
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed); // Dropoff
          } else {
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow); // Stop
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
          origin: PointLatLng(routePoints.first.latitude, routePoints.first.longitude),
          destination: PointLatLng(routePoints.last.latitude, routePoints.last.longitude),
          mode: TravelMode.driving,
          wayPoints: routePoints.length > 2
              ? routePoints.sublist(1, routePoints.length - 1).map(
                  (p) => PolylineWayPoint(location: "${p.latitude},${p.longitude}")
                ).toList()
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
            points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            width: 6,
          ),
        );
      }

      final GoogleMapController controller = await _controller.future;
      LatLngBounds bounds = _boundsFromLatLngList(routePoints);
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
    } else if (routePoints.length == 1) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(routePoints.first, 15));
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
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          )
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        },
        child: SlidingUpPanel(
          panel: RideBookingPanel(
            stops: _stops,
            controllers: _controllers,
            onStopSelected: _onStopSelected,
            onAddStop: _addStop,
            onGetFare: _getFare,
            onBookRide: _bookRide,
          ),
          body: GoogleMap(
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Use our own button if needed
            markers: _markers,
            polylines: _polylines,
          ),
        ),
      ),
    );
  }
} 