import 'package:flutter/material.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:speedgo_customer_app/features/home/models/stop_model.dart';

class RideBookingPanel extends StatefulWidget {
  final List<Stop> stops;
  final List<TextEditingController> controllers;
  final Function(int, Prediction) onStopSelected;
  final VoidCallback onAddStop;
  final VoidCallback onGetFare;
  final VoidCallback onBookRide;
  final Function(DateTime?) onScheduledTimeChanged;

  const RideBookingPanel({
    super.key,
    required this.stops,
    required this.controllers,
    required this.onStopSelected,
    required this.onAddStop,
    required this.onGetFare,
    required this.onBookRide,
    required this.onScheduledTimeChanged,
  });

  @override
  State<RideBookingPanel> createState() => _RideBookingPanelState();
}

class _RideBookingPanelState extends State<RideBookingPanel> {
  bool _isScheduled = false;
  DateTime? _scheduledTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Book a Ride',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.stops.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        index == 0
                            ? Icons.my_location
                            : index == widget.stops.length - 1
                            ? Icons.location_on
                            : Icons.flag,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GooglePlacesAutoCompleteTextFormField(
                          textEditingController: widget.controllers[index],
                          googleAPIKey:
                              "AIzaSyDUAPMhKz0uqqwkVoWTdwpb0U9QSlpYHqE",
                          debounceTime: 400,
                          countries: const [],
                          fetchCoordinates: true,
                          onSuggestionClicked: (prediction) {
                            print(
                              'Selected prediction: ${prediction.description}',
                            );
                            widget.controllers[index].text =
                                prediction.description!;
                            widget.onStopSelected(index, prediction);
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
              onPressed: widget.onAddStop,
              icon: const Icon(Icons.add),
              label: const Text('Add Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Scheduled Ride Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Schedule for Later',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isScheduled,
                      onChanged: (value) {
                        setState(() {
                          _isScheduled = value;
                          if (!value) {
                            _scheduledTime = null;
                            widget.onScheduledTimeChanged(null);
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_isScheduled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(hours: 1),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              final TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _scheduledTime = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                                widget.onScheduledTimeChanged(_scheduledTime);
                              }
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _scheduledTime != null
                                ? '${_scheduledTime!.day}/${_scheduledTime!.month}/${_scheduledTime!.year} ${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                                : 'Pick Date & Time',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onGetFare,
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
                widget.onBookRide();
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
