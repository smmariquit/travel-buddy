import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:latlong2/latlong.dart';

class Activity {
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  Activity({
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'],
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

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
  final List<Activity>? activities;

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
    this.activities,
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
      activities: (json['activities'] as List<dynamic>?)
          ?.map((activity) => Activity.fromJson(activity))
          .toList(),
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
      'activities': activities?.map((activity) => activity.toJson()).toList(),
    };
  }
}
