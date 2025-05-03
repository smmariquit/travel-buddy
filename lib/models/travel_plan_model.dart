import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Travel {
  String? id;
  String uid;
  final String name;
  DateTime? startDate;
  DateTime? endDate;
  final String location;
  final LatLng? locationLatLng;
  final String? flightDetails;
  final String? accommodation;
  final String? notes;
  final List<String>? checklist;
  final List<Map<String, dynamic>>? itinerary;
  final List<String>? sharedWith;
  final DateTime createdOn;

  Travel({
    this.id,
    required this.uid,
    required this.name,
    this.startDate,
    this.endDate,
    required this.location,
    this.locationLatLng,
    this.flightDetails,
    this.accommodation,
    this.notes,
    this.checklist,
    this.itinerary,
    this.sharedWith,
    required this.createdOn,
  });

  factory Travel.fromJson(Map<String, dynamic> json, [String? id]) {
    return Travel(
      id: id ?? json['id'],
      uid: json['uid'],
      name: json['name'],
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      location: json['location'],
      locationLatLng: json['locationLatLng'] != null
          ? LatLng(
              json['locationLatLng']['lat'],
              json['locationLatLng']['lng'],
            )
          : null,
      flightDetails: json['flightDetails'],
      accommodation: json['accommodation'],
      notes: json['notes'],
      checklist: List<String>.from(json['checklist'] ?? []),
      itinerary: (json['itinerary'] as List?)?.cast<Map<String, dynamic>>(),
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
      createdOn: (json['createdOn'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'locationLatLng': locationLatLng != null
          ? {'lat': locationLatLng!.latitude, 'lng': locationLatLng!.longitude}
          : null,
      'flightDetails': flightDetails,
      'accommodation': accommodation,
      'notes': notes,
      'checklist': checklist,
      'itinerary': itinerary,
      'sharedWith': sharedWith,
      'createdOn': createdOn,
    };
  }
}
