/// This page allows the user to pick a location on the map, particularly when adding a travel plan.
/// It uses the Google Places API to autocompleting locations.

// Flutter & Material
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
// Firebase & External Services
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import '../../utils/constants.dart';

void main() {
  // Require Hybrid Composition mode on Android.
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    // Force Hybrid Composition mode.
    mapsImplementation.useAndroidViewSurface = true;
  }
  // ···
}

class MapPickerPage extends StatefulWidget {
  /// The function to call when a location is selected.
  final Function(String) onLocationSelected;

  const MapPickerPage({Key? key, required this.onLocationSelected})
    : super(key: key);

  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(14.5995, 120.9842); // Manila
  bool _isLocationPermissionGranted = false;
  bool _isLoading = false;
  Set<Marker> _markers = {};
  bool _isMapCreated = false;
  bool _isMapError = false;
  String? _errorMessage;
  bool _hasInternet = false;

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
      print(
        '[DEBUG] Internet connection check: ${_hasInternet ? 'Connected' : 'Not connected'}',
      );
    } on SocketException catch (e) {
      print('[DEBUG] Internet connection error: $e');
      setState(() {
        _hasInternet = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print('[DEBUG] initState called');
    print('[DEBUG] Using API key: $apiKey');

    // Check internet connection first
    _checkInternetConnection();

    // Initialize Android map renderer
    try {
      final GoogleMapsFlutterPlatform mapsImplementation =
          GoogleMapsFlutterPlatform.instance;
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        print('[DEBUG] Setting up Android map renderer');
        mapsImplementation.useAndroidViewSurface = true;
        print('[DEBUG] Android view surface enabled');
      } else {
        print('[DEBUG] Not using Android map renderer');
      }
    } catch (e) {
      print('[DEBUG] Error initializing map renderer: $e');
    }

    _updateMarkers();
    _requestLocationPermission();

    // Add timeout for map creation
    print('[DEBUG] Starting map creation timeout timer');
    Future.delayed(const Duration(seconds: 10), () {
      if (!_isMapCreated && mounted) {
        print(
          '[DEBUG] Map creation timeout - Map was not created within 10 seconds',
        );
        print(
          '[DEBUG] Current state: isMapCreated=$_isMapCreated, isMapError=$_isMapError, hasInternet=$_hasInternet',
        );
        setState(() {
          _isMapError = true;
          _errorMessage =
              !_hasInternet
                  ? 'No internet connection. Please check your connection and try again.'
                  : 'Map failed to load within 10 seconds. Please check your internet connection and try again.';
        });
      } else {
        print('[DEBUG] Map creation successful or widget unmounted');
      }
    });
  }

  void _updateMarkers() {
    print('[DEBUG] Updating markers');
    _markers = {
      Marker(
        markerId: const MarkerId("selected-location"),
        position: _selectedLocation,
        infoWindow: InfoWindow(
          title: "Selected Location",
          snippet:
              "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}",
        ),
      ),
    };
  }

  Future<void> _requestLocationPermission() async {
    print('[DEBUG] Starting location permission request');
    try {
      var status = await Permission.location.status;
      print('[DEBUG] Initial permission status: $status');

      if (status.isDenied) {
        print('[DEBUG] Permission is denied, requesting permission');
        status = await Permission.location.request();
        print('[DEBUG] Permission request result: $status');
      }

      if (status.isGranted) {
        print('[DEBUG] Location permission granted');
        if (mounted) {
          setState(() {
            _isLocationPermissionGranted = true;
          });
        }
      } else if (status.isPermanentlyDenied) {
        print('[DEBUG] Permission is permanently denied');
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (BuildContext context) => AlertDialog(
                  title: const Text('Location Permission Required'),
                  content: const Text(
                    'Please enable location permission in app settings to use this feature.',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Open Settings'),
                      onPressed: () {
                        openAppSettings();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      print('[DEBUG] Error requesting location permission: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    print('[DEBUG] Map created successfully');
    _mapController = controller;
    setState(() {
      _isMapCreated = true;
    });
  }

  void _onTap(LatLng location) {
    print('[DEBUG] Map tapped at: ${location.latitude}, ${location.longitude}');
    setState(() {
      _selectedLocation = location;
      _updateMarkers();
    });
  }

  void _confirmSelection() async {
    print(
      '[DEBUG] Confirm selection pressed. Selected location: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}',
    );
    setState(() {
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "${place.street}, ${place.locality}, ${place.country}";
        print('[DEBUG] Address found through geocoding: $address');
        widget.onLocationSelected(address);
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      // If geocoding fails, try Places API
      final googleMapsPlaces = places.GoogleMapsPlaces(
        apiKey: 'AIzaSyACuAzPzmDxoadk9GGleOWBi-0luHFDYhs',
      );
      final response = await googleMapsPlaces.searchNearbyWithRadius(
        places.Location(
          lat: _selectedLocation.latitude,
          lng: _selectedLocation.longitude,
        ),
        100, // radius in meters
      );

      print('[DEBUG] Google Places API response status: ${response.status}');
      if (response.status == "OK" && response.results.isNotEmpty) {
        final place = response.results.first;
        print('[DEBUG] Place found: ${place.formattedAddress}');
        widget.onLocationSelected(place.formattedAddress!);
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        print('[DEBUG] No place found or response not OK');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to retrieve place details")),
          );
        }
      }
    } catch (e) {
      print('[DEBUG] Exception during place search: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error occurred: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      '[DEBUG] build called - isMapCreated: $_isMapCreated, isMapError: $_isMapError, hasInternet: $_hasInternet',
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Select Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isMapError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load map',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Please check your internet connection',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('[DEBUG] Retry button pressed');
                      _checkInternetConnection(); // Check internet again
                      setState(() {
                        _isMapError = false;
                        _isMapCreated = false;
                        _errorMessage = null;
                      });
                      // Reinitialize the map
                      final GoogleMapsFlutterPlatform mapsImplementation =
                          GoogleMapsFlutterPlatform.instance;
                      if (mapsImplementation is GoogleMapsFlutterAndroid) {
                        mapsImplementation.useAndroidViewSurface = true;
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (!_isMapCreated)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading map...'),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    key: ValueKey('AIzaSyACuAzPzmDxoadk9GGleOWBi-0luHFDYhs'),
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 14.0,
                    ),
                    onTap: _onTap,
                    markers: _markers,
                    myLocationEnabled: _isLocationPermissionGranted,
                    myLocationButtonEnabled: _isLocationPermissionGranted,
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    compassEnabled: true,
                    minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmSelection,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text("Confirm Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
