import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/api/firebase_travel_api.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:travel_app/utils/responsive_layout.dart';


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
  List<Map<String, dynamic>> _itinerary = [];

  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _flightController = TextEditingController();
  final _accommodationController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  final Color primaryColor = const Color(0xFF004225);
  final Color accentColor = const Color(0xFFb7fdfe);
  final Color backgroundColor = const Color(0xFFFFFFFF);
  final Color errorColor = const Color(0xFFe06666);
  final Color highlightColor = const Color(0xFFf6b26b);
  final Color textColor = const Color(0xFF000000);

  final places = GoogleMapsPlaces(apiKey: "AIzaSyDEBqD6XjeQ23H-XB0LOkcL73oy931VAYE");


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
        title: Text('Create New Trip', style: TextStyle(color: backgroundColor)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('Trip Info'),
                  _buildTextField('Trip Name', _nameController, (value) => value!.isEmpty ? 'Enter a name' : null, onSaved: (v) => _name = v!),
                  
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
                      Expanded(child: _buildDateField('Start Date', _startDateController, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateField('End Date', _endDateController, false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHeader('Additional Info'),
                  _buildTextField('Flight Details', _flightController, null, onSaved: (v) => _flightDetails = v),
                  _buildTextField('Accommodation', _accommodationController, null, onSaved: (v) => _accommodation = v),
                  _buildTextField('Notes', _notesController, null, maxLines: 3, onSaved: (v) => _notes = v),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: backgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _submitForm,
                      child: const Text("Save & Continue"),
                    ),
                  )
                ],
              ),
            ),
          ), 
        
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String? Function(String?)? validator,
      {int maxLines = 1, void Function(String?)? onSaved}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, bool isStart) {
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
        if (value!.isEmpty) {
          return 'Please select a date';
        }
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
      // Check if both start and end dates are provided
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please select both start and end dates", style: TextStyle(color: backgroundColor)),
          backgroundColor: errorColor,
        ));
        return;
      }

      // Check if the end date is before the start date
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("End date can't be before start date", style: TextStyle(color: backgroundColor)),
          backgroundColor: errorColor,
        ));
        return;
      }

      _formKey.currentState!.save();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not logged in")));
        return;
      }

      final travel = Travel(
        uid: currentUser.uid,
        name: _name,
        startDate: _startDate,
        endDate: _endDate,
        location: _location,
        flightDetails: _flightDetails,
        accommodation: _accommodation,
        notes: _notes,
        checklist: _checklist,
        itinerary: _itinerary,
        createdOn: DateTime.now(),
      );

      String message = await _firebaseTravelAPI.addTravel(travel);

      if (message.isNotEmpty) {
        showQR(message);

        // // Pass the new travel plan back to the main page
        // Navigator.pushReplacementNamed(
        //   context,
        //   '/main',
        //   arguments: travel, // Pass the travel object as an argument
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save travel plan")));
      }
    }
  }


  void showQR(String travelId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Share Your Trip", style: TextStyle(color: primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replace Expanded with SizedBox to give the QR code a defined size
            SizedBox(
              height: 200.0, // Set height as needed
              width: 200.0,  // Set width as needed
              child: QrImageView(
                data: _firebaseTravelAPI.generateQRCodeValue(travelId),
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text("Scan or share this QR to invite others", style: TextStyle(color: textColor)),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Continue", style: TextStyle(color: primaryColor)),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Placeholder(), // Replace with TripDetailsPage
              ));
            },
          )
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

        final location = details.result.formattedAddress ?? prediction.description;

        setState(() {
          _locationController.text = location!;
        });
      } else {
        // If no predictions, allow manual input and show message
        print("No predictions found");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No location suggestions found, please enter manually.")),
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
      builder: (context) => Dialog(
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
                child: Text("Select Location", style: TextStyle(color: primaryColor)),
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
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
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
                  final selectedLocation = details.result.formattedAddress ?? prediction.description;

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

}
