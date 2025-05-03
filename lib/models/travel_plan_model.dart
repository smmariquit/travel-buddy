import 'package:cloud_firestore/cloud_firestore.dart';

class TravelPlan {
  String? id;
  final String uid;
  final String name;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdOn;

  TravelPlan({
    this.id,
    required this.uid,
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.createdOn,
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json, String docId) {
    return TravelPlan(
      id: docId,
      uid: json['uid'],
      name: json['name'],
      location: json['location'],
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      createdOn: (json['createdOn'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'createdOn': createdOn,
    };
  }
}
