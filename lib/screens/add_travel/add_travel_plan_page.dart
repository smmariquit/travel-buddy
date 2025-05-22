import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/api/firebase_travel_api.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:travel_app/screens/add_travel/scan_qr_page.dart';
import 'package:travel_app/utils/constants.dart';
import 'package:travel_app/screens/add_travel/trip_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:travel_app/utils/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:travel_app/screens/add_travel/map_picker_page.dart';

class AddTravelPlanPage extends StatefulWidget {
  const AddTravelPlanPage({super.key});

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
  String durationText = 'Trip Duration: Not set';
  String? _flightDetails, _accommodation, _notes;
  final List<String> _checklist = [];
  final List<Activity> _activities = [];
  bool _isOneDayTrip = false;
  LatLng? locationSelected;
  int days = 0;

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

  @override
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
                      style: TextButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: Text("Scan QR"),
                      onPressed: _showQRScanOptions,
                    ),
                  ),
                  _buildTextField(
                    label: 'Trip Name',
                    controller: _nameController,
                    validator:
                        (value) => value!.isEmpty ? 'Enter a name' : null,
                    onSaved: (v) => _name = v!,
                  ),

                  // Location TextField with Auto-Suggestion and Map Picker
                  _buildLocationFieldWithAutocomplete(),

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
                  const SizedBox(height: 8),
                  // Trip Duration Display
                  Builder(
                    builder: (context) {
                      if (_startDate != null && _endDate != null) {
                        if (days == 0) {
                          durationText = 'Trip Duration: 1 day';
                        } else if (days > 0) {
                          durationText = 'Trip Duration: ${days + 1} days';
                        } else {
                          durationText = 'Trip Duration: Invalid dates';
                        }
                      } else if (_startDate != null && _endDate == null) {
                        durationText =
                            'Trip Duration: Starts on ${DateFormat('EEEE, MMM d, yyyy').format(_startDate!)}';
                      }
                      return Card(
                        color: Colors.green[50],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time, color: primaryColor),
                              SizedBox(width: 8),
                              Text(
                                durationText,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildHeader('Additional Info'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Flight Details',
                          controller: _flightController,
                          onSaved: (v) => _flightDetails = v,
                          hint: 'e.g. Flight #, Departure Time, etc.',
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _flightController.text = 'N/A';
                          });
                        },
                        label: Text(
                          'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Accommodation',
                          controller: _accommodationController,
                          onSaved: (v) => _accommodation = v,
                          hint: 'e.g. Hotel Name, Address, etc.',
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _accommodationController.text = 'N/A';
                          });
                        },
                        label: Text(
                          'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Notes',
                          controller: _notesController,
                          maxLines: 3,
                          onSaved: (v) => _notes = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _notesController.text = 'N/A';
                          });
                        },
                        label: Text(
                          'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
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

  void _showQRScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Scan using Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _scanQRCode(); // Call your existing camera scanner
                },
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text("Upload QR Image"),
                onTap: () {
                  Navigator.pop(context);
                  _uploadQRCode(); // Call your image upload scanner
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // // Method to handle uploading QR from gallery
  Future<void> _uploadQRCode() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final barcodeScanner = BarcodeScanner();

    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isEmpty) {
        _showDialog("No QR code found in the image.");
      } else {
        final qrCode = barcodes.first.rawValue;
        if (qrCode != null) {
          _processQRResult(qrCode);
        } else {
          _showDialog("Unable to extract QR code.");
        }
      }
    } catch (e) {
      print("Error scanning QR from image: $e");
      _showDialog("Error scanning QR code.");
    } finally {
      barcodeScanner.close();
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("QR Scan Result"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to process QR result from either scanning or uploading
  void _processQRResult(String result) async {
    if (result.isNotEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        const successMessage = "Travel plan shared successfully";
        final message = await _firebaseTravelAPI.shareTravelWithUser(
          result,
          currentUser.uid,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Travel plan not found."),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.zero,
            ),
          );
        }
      }
    }
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint ?? '',
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
        // End date is optional, so no validation required here
        return null;
      },
    );
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? today : (_endDate ?? today),
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat(
            'EEEE, MMM d, yyyy',
          ).format(picked);
          if (_isOneDayTrip) {
            _endDate = picked;
            _endDateController.text = DateFormat(
              'EEEE, MMM d, yyyy',
            ).format(picked);
          }
        } else {
          // Only allow end date selection if it's not a one-day trip
          if (!_isOneDayTrip) {
            // Ensure end date is not before start date
            if (picked.isBefore(_startDate!)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "End date can't be before start date",
                    style: TextStyle(color: backgroundColor),
                  ),
                  backgroundColor: errorColor,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.zero,
                ),
              );
              return;
            }
            _endDate = picked;
            _endDateController.text = DateFormat(
              'EEEE, MMM d, yyyy',
            ).format(picked);
            setState(() {
              if (_endDate != null || _startDate != null) {
                days = picked.difference(_startDate!).inDays;
              }
              if (_endDate == null) {
                durationText =
                    'Trip Duration: Starts on ${DateFormat('EEEE, MMM d, yyyy').format(_startDate!)}';
              } else if (days == 0) {
                durationText = 'Trip Duration: 1 day';
              } else if (days > 0) {
                durationText = 'Trip Duration: ${days + 1} days';
              } else {
                durationText = 'Trip Duration: Invalid dates';
              }
            });
          }
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Validate dates
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Start date can't be empty"),
            backgroundColor: errorColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
        return;
      }

      // Get today's date without time component
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      // Get start date without time component
      final startDate = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );

      // Only validate end date if it is set
      if (_endDate != null) {
        if (_endDate!.isBefore(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("End date can't be before start date"),
              backgroundColor: errorColor,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.zero,
            ),
          );
          return;
        }
        if (_startDate!.isAfter(_endDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Start date can't be after end date"),
              backgroundColor: errorColor,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.zero,
            ),
          );
          return;
        }
      }

      // Validate required fields
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Trip name can't be empty"),
            backgroundColor: errorColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
        return;
      }

      if (_locationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Location can't be empty"),
            backgroundColor: errorColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
        return;
      }

      _formKey.currentState!.save();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User not logged in"),
            backgroundColor: errorColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
        return;
      }

      // Create travel object
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
        showQR(travelId); // Show QR first

        // Always send notification with days until trip
        final daysUntilTrip = _startDate!.difference(DateTime.now()).inDays;
        final tripName = travel.name.isNotEmpty ? travel.name : 'Unnamed Trip';

        // Fetch current user's FCM token from Firestore
        final currentUserDoc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(currentUser.uid)
                .get();

        final currentUserData = currentUserDoc.data();
        final fcmToken = currentUserData?['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await NotificationService().sendPushNotification(
            fcmToken: fcmToken,
            title: 'Upcoming Trip Reminder',
            body: 'Your trip "$tripName" starts in $daysUntilTrip day(s)!',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              travelId.startsWith("Error")
                  ? travelId
                  : "Failed to save travel plan",
            ),
            backgroundColor: errorColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
      }
    } else {
      // Show a general validation error if the form is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all required fields correctly"),
          backgroundColor: errorColor,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
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
                      SnackBar(
                        content: Text("Travel plan not found."),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.zero,
                      ),
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
        byteData.buffer.asUint8List();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code to gallery!'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
      }
    } catch (e) {
      print('Error saving QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR code.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
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
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
      }
    } else {
      // Handle API error response
      print("Failed to get autocomplete suggestions: ${response.errorMessage}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location suggestions"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permission is required to pick a place on the map.',
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
        return;
      }
    }
  }

  Future<void> _openMapPicker() async {
    await _requestLocationPermission();
    Position position = await Geolocator.getCurrentPosition();
    double lat = position.latitude;
    double long = position.longitude;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => MapPickerPage(
              initialPosition:
                  LatLng(lat, long) ??
                  (locationSelected ??
                      LatLng(14.5995, 120.9842)), // Manila as default
            ),
      ),
    );

    // Check if result is a Map containing address and location
    if (result != null && result is Map) {
      final address = result['address'] as String?;
      locationSelected = result['location'] as LatLng?;

      if (address != null && locationSelected != null) {
        setState(() {
          _locationController.text = address;
        });

        // Store the location coordinates
        final double latitude = locationSelected!.latitude;
        final double longitude = locationSelected!.longitude;

        // Optionally print to verify
        print("Selected location: $address ($latitude, $longitude)");
      }
    }
  }

  Widget _buildLocationFieldWithAutocomplete() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator:
                    (value) => value!.isEmpty ? 'Enter a location' : null,
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 500),
                    () async {
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
                    },
                  );
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
                          final details = await places.getDetailsByPlaceId(
                            placeId,
                          );
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
              SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: Icon(Icons.map, color: primaryColor, size: 32),
          label: Text(
            "View Map",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _openMapPicker,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Travel plan not found."),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.zero,
            ),
          );
        }
      }
    }
  }
}
