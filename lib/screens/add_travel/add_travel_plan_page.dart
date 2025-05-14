import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/api/firebase_travel_api.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:travel_app/screens/add_travel/scan_qr_page.dart';
import 'package:travel_app/utils/constants.dart';
import 'package:travel_app/screens/add_travel/trip_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTravelPlanPage extends StatefulWidget {
  @override
  _AddTravelPlanPageState createState() => _AddTravelPlanPageState();
}

class _AddTravelPlanPageState extends State<AddTravelPlanPage> {
  Timer? _debounce;
  List<Prediction> _predictions = [];
  bool _isSearching = false;

  final _formKey = GlobalKey<FormState>();
  final FirebaseTravelAPI _firebaseTravelAPI = FirebaseTravelAPI();
  late String _name, _location;
  DateTime? _startDate, _endDate;
  String? _flightDetails, _accommodation, _notes;
  List<String> _checklist = [];
  List<Activity>? _activities = [];

  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _flightController = TextEditingController();
  final _accommodationController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  final places = GoogleMapsPlaces(apiKey: apiKey);

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _flightController.dispose();
    _accommodationController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Create New Trip',
          style: TextStyle(color: backgroundColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    'Trip Info',
                    trailing: TextButton.icon(
                      icon: Icon(Icons.qr_code_scanner, color: primaryColor),
                      label: Text(
                        "or scan QR",
                        style: TextStyle(color: primaryColor),
                      ),
                      onPressed: _scanQRCode,
                    ),
                  ),
                  _buildTextField(
                    'Trip Name',
                    _nameController,
                    (value) => value!.isEmpty ? 'Enter a name' : null,
                    onSaved: (v) => _name = v!,
                  ),

                  // Location TextField with Auto-Suggestion and Map Picker
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleLocationAutocomplete,
                          child: _buildLocationFieldWithAutocomplete(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.map, color: primaryColor),
                        onPressed: _openMapPicker,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          'Start Date',
                          _startDateController,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          'End Date',
                          _endDateController,
                          false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHeader('Additional Info'),
                  _buildTextField(
                    'Flight Details',
                    _flightController,
                    null,
                    onSaved: (v) => _flightDetails = v,
                  ),
                  _buildTextField(
                    'Accommodation',
                    _accommodationController,
                    null,
                    onSaved: (v) => _accommodation = v,
                  ),
                  _buildTextField(
                    'Notes',
                    _notesController,
                    null,
                    maxLines: 3,
                    onSaved: (v) => _notes = v,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: backgroundColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _submitForm,
                      child: const Text("Save & Continue"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String? Function(String?)? validator, {
    int maxLines = 1,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    bool isStart,
  ) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: Icon(Icons.calendar_today, color: primaryColor),
      ),
      onTap: () => _selectDate(context, isStart),
      validator: (value) {
        if (isStart && (value == null || value.isEmpty)) {
          return 'Please select a start date';
        }
        // No validation for end date
        return null;
      },
    );
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if end date is before start date if both are present
      if (_endDate != null &&
          _startDate != null &&
          _endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "End date can't be before start date",
              style: TextStyle(color: backgroundColor),
            ),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      _formKey.currentState!.save();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User not logged in")));
        return;
      }

      // Create initial travel object with a temporary placeholder ID
      // The actual ID will be set by the FirebaseTravelAPI.addTravel method
      final travel = Travel(
        id: 'temp_id', // This will be replaced by Firebase
        uid: currentUser.uid,
        name: _name,
        startDate: _startDate,
        endDate: _endDate,
        location: _location,
        flightDetails: _flightDetails,
        accommodation: _accommodation,
        notes: _notes,
        checklist: _checklist,
        activities: _activities,
        createdOn: DateTime.now(),
      );
      String travelId = await _firebaseTravelAPI.addTravel(travel);

      if (travelId.isNotEmpty && !travelId.startsWith("Error")) {
        // Use the travelId returned from Firestore
        showQR(travelId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              travelId.startsWith("Error")
                  ? travelId
                  : "Failed to save travel plan",
            ),
          ),
        );
      }
    }
  }

  void showQR(String travelId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              "Share Your Trip",
              style: TextStyle(color: primaryColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replace Expanded with SizedBox to give the QR code a defined size
                SizedBox(
                  height: 200.0, // Set height as needed
                  width: 200.0, // Set width as needed
                  child: QrImageView(
                    data: _firebaseTravelAPI.generateQRCodeValue(travelId),
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Scan or share this QR to invite others",
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Continue", style: TextStyle(color: primaryColor)),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the QR dialog

                  // Fetch travel data from Firestore using the travelId
                  final doc =
                      await FirebaseFirestore.instance
                          .collection('travel')
                          .doc(travelId)
                          .get();

                  if (doc.exists) {
                    final travel = Travel.fromJson(doc.data()!, doc.id);

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TripDetails(travel: travel),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Travel plan not found.")),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _handleLocationAutocomplete() async {
    print("Location input: ${_locationController.text}");

    final response = await places.autocomplete(_locationController.text);
    if (response.isOkay) {
      if (response.predictions.isNotEmpty) {
        final prediction = response.predictions.first;
        print("Prediction found: ${prediction.description}");

        final placeId = prediction.placeId;
        final details = await places.getDetailsByPlaceId(placeId!);

        final location =
            details.result.formattedAddress ?? prediction.description;

        setState(() {
          _locationController.text = location!;
        });
      } else {
        // If no predictions, allow manual input and show message
        print("No predictions found");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No location suggestions found, please enter manually.",
            ),
          ),
        );
      }
    } else {
      // Handle API error response
      print("Failed to get autocomplete suggestions: ${response.errorMessage}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location suggestions")),
      );
    }
  }

  Future<void> _openMapPicker() async {
    LatLng selectedLatLng = LatLng(14.5995, 120.9842); // Default to Manila

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: selectedLatLng,
                        zoom: 10,
                      ),
                      onTap: (LatLng latLng) {
                        selectedLatLng = latLng;
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId("picked"),
                          position: selectedLatLng,
                        ),
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();

                      setState(() {
                        _locationController.text =
                            "Lat: ${selectedLatLng.latitude}, Lng: ${selectedLatLng.longitude}";
                      });
                    },
                    child: Text(
                      "Select Location",
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLocationFieldWithAutocomplete() {
    return Column(
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            labelStyle: TextStyle(color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            suffixIcon: Icon(Icons.location_on, color: primaryColor),
          ),
          validator: (value) => value!.isEmpty ? 'Enter a location' : null,
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () async {
              if (value.isNotEmpty) {
                final response = await places.autocomplete(value);
                if (response.isOkay) {
                  setState(() {
                    _predictions = response.predictions;
                    _isSearching = true;
                  });
                }
              } else {
                setState(() {
                  _predictions = [];
                  _isSearching = false;
                });
              }
            });
          },
          onSaved: (v) => _location = v!,
        ),
        if (_isSearching && _predictions.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: primaryColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.description ?? ''),
                  onTap: () async {
                    final placeId = prediction.placeId!;
                    final details = await places.getDetailsByPlaceId(placeId);
                    final selectedLocation =
                        details.result.formattedAddress ??
                        prediction.description;

                    setState(() {
                      _locationController.text = selectedLocation!;
                      _isSearching = false;
                      _predictions.clear();
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _scanQRCode() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => QRScanPage()));

    if (result != null && result is String) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final message = await _firebaseTravelAPI.shareTravelWithUser(
          result,
          currentUser.uid,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        // Fetch the travel data using the scanned travel ID
        final doc =
            await FirebaseFirestore.instance
                .collection('travel')
                .doc(result)
                .get();

        if (doc.exists) {
          final travel = Travel.fromJson(doc.data()!, doc.id);

          // Navigate to TripDetails page
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TripDetails(travel: travel)),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Travel plan not found.")));
        }
      }
    }
  }
}
