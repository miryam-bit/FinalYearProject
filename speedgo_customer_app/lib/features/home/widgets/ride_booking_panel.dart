import 'package:flutter/material.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:speedgo_customer_app/features/home/models/stop_model.dart';

class RideBookingPanel extends StatelessWidget {
  final List<Stop> stops;
  final List<TextEditingController> controllers;
  final Function(int, Prediction) onStopSelected;
  final VoidCallback onAddStop;
  final VoidCallback onGetFare;
  final VoidCallback onBookRide;

  const RideBookingPanel({
    super.key,
    required this.stops,
    required this.controllers,
    required this.onStopSelected,
    required this.onAddStop,
    required this.onGetFare,
    required this.onBookRide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Book a Ride', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: stops.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        index == 0
                            ? Icons.my_location
                            : index == stops.length - 1
                                ? Icons.location_on
                                : Icons.flag,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GooglePlacesAutoCompleteTextFormField(
                          textEditingController: controllers[index],
                          googleAPIKey: "AIzaSyDUAPMhKz0uqqwkVoWTdwpb0U9QSlpYHqE",
                          debounceTime: 400,
                          countries: const [],
                          fetchCoordinates: true,
                          onSuggestionClicked: (prediction) {
                            print('Selected prediction: ${prediction.description}');
                            controllers[index].text = prediction.description!;
                            onStopSelected(index, prediction);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddStop,
              icon: const Icon(Icons.add),
              label: const Text('Add Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGetFare,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Get Fare Estimate'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                print('Book Ride button pressed');
                onBookRide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Book Ride'),
            ),
          ),
        ],
      ),
    );
  }
} 