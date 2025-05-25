// Flutter & Material
// (none in this file)

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';

// State Management
// (none in this file)

// App-specific
// (none in this file)

/// Activity is the itinerary item for a travel plan
class Activity {
  final String title;
  final DateTime startDate;
  DateTime? endDate;
  final String? place;
  final String? time; // Can be stored as a formatted string like "10:00 AM"
  final String? notes;
  String? imageUrl; // Base64 or Firebase Storage URL
  List<Map<String, dynamic>>? checklist;

  Activity({
    required this.title,
    required this.startDate,
    this.endDate,
    this.place,
    this.time,
    this.notes,
    this.imageUrl,
    this.checklist,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'],
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate:
          json['endDate'] != null
              ? (json['endDate'] as Timestamp).toDate()
              : null,
      place: json['place'],
      time: json['time'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      checklist:
          json['checklist'] != null
              ? List<Map<String, dynamic>>.from(
                json['checklist'].map(
                  (item) =>
                      item is String ? {'text': item, 'checked': false} : item,
                ),
              )
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'place': place,
      'time': time,
      'notes': notes,
      'imageUrl': imageUrl,
      'checklist': checklist,
    };
  }
}

class Travel {
  final String id; // Non-nullable, required
  final String uid;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String location;
  final String? flightDetails;
  final String? accommodation;
  final String? notes;
  final List<Map<String, dynamic>>? checklist;
  late final List<String>? sharedWith;
  final DateTime createdOn;
  List<Activity>? activities;
  String? imageUrl;
  final int notificationDays;

  Travel({
    required this.id, // Required parameter
    required this.uid,
    required this.name,
    this.startDate,
    this.endDate,
    required this.location,
    this.flightDetails,
    this.accommodation,
    this.notes,
    this.checklist,
    this.sharedWith,
    required this.createdOn,
    this.activities,
    this.imageUrl,
    // Default to 5 days for existing records
    this.notificationDays = 5,
  });

  /// Creates a Travel object from a JSON map, using the document ID if provided
  factory Travel.fromJson(Map<String, dynamic> json, String docId) {
    // Use docId if provided, otherwise use id from json, or generate an error
    final id = docId;

    // Validate ID to ensure it's never null or empty
    if (id.isEmpty) {
      throw ArgumentError('Travel ID cannot be null or empty');
    }

    return Travel(
      id: id,
      uid: json['uid'],
      name: json['name'],
      startDate:
          json['startDate'] != null
              ? (json['startDate'] as Timestamp).toDate()
              : null,
      endDate:
          json['endDate'] != null
              ? (json['endDate'] as Timestamp).toDate()
              : null,
      location: json['location'],
      flightDetails: json['flightDetails'],
      accommodation: json['accommodation'],
      notes: json['notes'],
      checklist:
          json['checklist'] != null
              ? List<Map<String, dynamic>>.from(
                json['checklist'].map(
                  (item) =>
                      item is String ? {'text': item, 'checked': false} : item,
                ),
              )
              : [],
      sharedWith:
          json['sharedWith'] != null
              ? List<String>.from(json['sharedWith'])
              : [],
      createdOn:
          json['createdOn'] != null
              ? (json['createdOn'] as Timestamp).toDate()
              : DateTime.now(),
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map((activity) => Activity.fromJson(activity))
              .toList(),
      imageUrl: json['imageUrl'],
      notificationDays: json['notificationDays'] ?? 5,
    );
  }

  /// Converts the Travel object to a JSON map, including the ID
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include ID in the JSON
      'uid': uid,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'flightDetails': flightDetails,
      'accommodation': accommodation,
      'notes': notes,
      'checklist': checklist,
      'sharedWith': sharedWith,
      'createdOn': createdOn,
      'activities': activities?.map((activity) => activity.toJson()).toList(),
      'imageUrl': imageUrl,
      'notificationDays': notificationDays,
    };
  }

  /// Creates a copy of this Travel object but with the specified fields replaced
  Travel copyWith({
    String? id,
    String? uid,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? flightDetails,
    String? accommodation,
    String? notes,
    List<Map<String, dynamic>>? checklist,
    List<String>? sharedWith,
    DateTime? createdOn,
    List<Activity>? activities,
    String? imageUrl,
    int? notificationDays,
  }) {
    return Travel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      flightDetails: flightDetails ?? this.flightDetails,
      accommodation: accommodation ?? this.accommodation,
      notes: notes ?? this.notes,
      checklist: checklist ?? this.checklist,
      sharedWith: sharedWith ?? this.sharedWith,
      createdOn: createdOn ?? this.createdOn,
      activities: activities ?? this.activities,
      imageUrl: imageUrl ?? this.imageUrl,
      notificationDays: notificationDays ?? this.notificationDays,
    );
  }
}
