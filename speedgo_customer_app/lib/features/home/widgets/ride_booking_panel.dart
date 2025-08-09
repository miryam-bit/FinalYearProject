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

  Widget _buildLocationField(int index) {
    final isPickup = index == 0;
    final isDropoff = index == widget.stops.length - 1;

    String labelText = 'Stop ${index}';
    if (isPickup) labelText = 'Pickup Location';
    if (isDropoff) labelText = 'Destination';

    String hintText = 'Enter a location';
    if (isPickup) hintText = 'Where to pick you up?';
    if (isDropoff) hintText = 'Where to drop you off?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPickup
                    ? Icons.my_location
                    : (isDropoff ? Icons.location_on : Icons.flag),
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GooglePlacesAutoCompleteTextFormField(
              textEditingController: widget.controllers[index],
              googleAPIKey: "AIzaSyDUAPMhKz0uqqwkVoWTdwpb0U9QSlpYHqE",
              debounceTime: 400,
              countries: const [],
              fetchCoordinates: true,
              onSuggestionClicked: (prediction) {
                widget.controllers[index].text = prediction.description!;
                widget.onStopSelected(index, prediction);
              },
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStopButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add_location_alt, size: 18),
        label: const Text('Add Stop'),
        onPressed: widget.onAddStop,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildScheduledRideSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Schedule for Later',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _scheduledTime != null
                      ? '${_scheduledTime!.day}/${_scheduledTime!.month}/${_scheduledTime!.year} at ${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                      : 'Pick Date & Time',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final minimumTime = now.add(const Duration(minutes: 15));

                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 30)),
                  );

                  if (pickedDate == null) return;

                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(minimumTime),
                  );

                  if (pickedTime == null) return;

                  final selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  if (selectedDateTime.isBefore(minimumTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select a time at least 15 minutes in the future.',
                        ),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _scheduledTime = selectedDateTime;
                  });
                  widget.onScheduledTimeChanged(_scheduledTime);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onGetFare,
            child: const Text('Get Fare Estimate'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onBookRide,
            child: const Text('Book Ride Now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Book Your Ride',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Where would you like to go today?',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              widget.stops.length,
              (index) => _buildLocationField(index),
            ),
            if (widget.stops.length < 5) _buildAddStopButton(),

            _buildScheduledRideSection(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
