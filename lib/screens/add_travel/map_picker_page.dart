import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/places.dart' as places;

class MapPickerPage extends StatefulWidget {
  final LatLng initialPosition;
  final void Function(String, LatLng)? onLocationSelected;

  const MapPickerPage({
    super.key,
    required this.initialPosition,
    this.onLocationSelected,
  });

  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _mapController;
  late LatLng _selectedLocation;

  final TextEditingController _searchController = TextEditingController();
  List<places.Prediction> _placePredictions = [];

  final String _googleApiKey = "AIzaSyACuAzPzmDxoadk9GGleOWBi-0luHFDYhs";

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialPosition;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {});
  }

  void _onTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    final autocomplete = places.GoogleMapsPlaces(apiKey: _googleApiKey);
    final response = await autocomplete.autocomplete(input);

    if (response.status == 'OK') {
      setState(() {
        _placePredictions = response.predictions;
      });
    } else {}
  }

  void _selectPrediction(places.Prediction prediction) async {
    final googleMapsPlaces = places.GoogleMapsPlaces(apiKey: _googleApiKey);
    final details = await googleMapsPlaces.getDetailsByPlaceId(
      prediction.placeId!,
    );

    if (details.status == 'OK') {
      final location = details.result.geometry!.location;

      setState(() {
        _selectedLocation = LatLng(location.lat, location.lng);
        _placePredictions = [];
        _searchController.text = details.result.name;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
    }
  }

  void _confirmSelection() async {
    final googleMapsPlaces = places.GoogleMapsPlaces(apiKey: _googleApiKey);
    final response = await googleMapsPlaces.searchByText(
      'place',
      location: places.Location(
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
      ),
    );

    if (response.status == "OK" && response.results.isNotEmpty) {
      final place = response.results.first;
      final selectedAddress = place.formattedAddress ?? 'Selected Location';

      // Call callback if provided
      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(selectedAddress, _selectedLocation);
        Navigator.pop(context);
      } else {
        // Return both address and location as a Map
        Navigator.pop(context, {
          "address": selectedAddress,
          "location": _selectedLocation,
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to retrieve place details")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Select a Location'),
      ),
      body: Column(
        children: [
          // Search Container
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a place',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.green),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.red),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _placePredictions = [];
                                  });
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                    ),
                    onChanged: _searchPlaces,
                  ),
                ),

                // Prediction list
                if (_placePredictions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _placePredictions[index];
                        return ListTile(
                          title: Text(prediction.description ?? ""),
                          leading: Icon(Icons.location_on, color: Colors.green),
                          onTap: () => _selectPrediction(prediction),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Map container
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
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
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    ),
                  },
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),

                // Confirm button
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check_circle),
                        label: Text("Confirm"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _confirmSelection,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
