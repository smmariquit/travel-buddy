/// This page allows the user to pick a location on the map, particularly when adding a travel plan.
/// It uses the Google Places API to autocompleting locations.

// Flutter & Material
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
// Firebase & External Services
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart'
    as places; // Google Places API for autocompleting locations

class MapPickerPage extends StatefulWidget {
  /// The function to call when a location is selected.
  final Function(String) onLocationSelected;

  MapPickerPage({required this.onLocationSelected});

  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late GoogleMapController _mapController;
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(
      37.7749,
      -122.4194,
    ); // Default location (San Francisco)
  }

  /// Store the map controller once the map is created.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// When the Select Location button is tapped, save the location.
  void _onTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  /// When the Select Location button is tapped, retrieve a location via the Google Maps Places API.
  void _confirmSelection() async {
    final googleMapsPlaces = places.GoogleMapsPlaces(
      apiKey: "AIzaSyDEBqD6XjeQ23H-XB0LOkcL73oy931VAYE",
    );
    final response = await googleMapsPlaces.searchByText(
      'place',
      location: places.Location(
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
      ),
    );

    if (response.status == "OK" && response.results.isNotEmpty) {
      final place =
          response
              .results
              .first; // You can choose the best result or modify as needed
      widget.onLocationSelected(place.formattedAddress!);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to retrieve place details")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Select a Location'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 14.0,
              ),
              onTap: _onTap,
              markers: {
                Marker(
                  markerId: MarkerId("selected-location"),
                  position: _selectedLocation,
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _confirmSelection,
              child: Text("Confirm Location"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
