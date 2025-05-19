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
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:travel_app/screens/home/map_picker_page.dart';

class AddTravelPlanPage extends StatefulWidget {
  @override
  _AddTravelPlanPageState createState() => _AddTravelPlanPageState();
}

class _AddTravelPlanPageState extends State<AddTravelPlanPage> {
  Timer? _debounce;
  List<Prediction> _predictions = [];
  bool _isSearching = false;

  final _formKey = GlobalKey<FormState>();
  final GlobalKey qrKey = GlobalKey();
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
                RepaintBoundary(
                  key: qrKey, // Needed for capturing the QR image
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: QrImageView(
                      data: _firebaseTravelAPI.generateQRCodeValue(travelId),
                      version: QrVersions.auto,
                      size: 200,
                    ),
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
                onPressed: () async {
                  await saveQRToGalleryPlus();
                },
                child: Text("Save QR", style: TextStyle(color: primaryColor)),
              ),
              TextButton(
                child: Text("Continue", style: TextStyle(color: primaryColor)),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the dialog

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

  Future<void> saveQRToGalleryPlus() async {
    try {
      await Permission.storage.request();
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the QR widget as image
      ui.Image qrImage = await boundary.toImage(pixelRatio: 3.0);

      // Create a new picture recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Paint white background
      final paint = Paint()..color = ui.Color(0xFFFFFFFF); // White color
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          qrImage.width.toDouble(),
          qrImage.height.toDouble(),
        ),
        paint,
      );

      // Draw the QR image on top of white background
      canvas.drawImage(qrImage, Offset.zero, Paint());

      // End recording and create final image
      final picture = recorder.endRecording();
      final imgWithWhiteBg = await picture.toImage(
        qrImage.width,
        qrImage.height,
      );

      // Convert to bytes
      final byteData = await imgWithWhiteBg.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();

        final result = await ImageGallerySaverPlus.saveImage(
          pngBytes,
          quality: 100,
          name: "qr_code_white_bg_${DateTime.now().millisecondsSinceEpoch}",
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR Code to gallery!')));
      }
    } catch (e) {
      print('Error saving QR code: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save QR code.')));
    }
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
    print('[DEBUG] Opening map picker');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerPage(
              onLocationSelected: (String location) {
                print('[DEBUG] Location selected: $location');
                setState(() {
                  _locationController.text = location;
                });
              },
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
    const successMessage = "Travel plan shared successfully";
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

        if (message != successMessage) {
          return;
        }

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
