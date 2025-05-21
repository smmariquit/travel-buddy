// import 'package:cloud_firestore/cloud_firestore.dart';

// class TravelNotification {
//   final String id;
//   final String title;
//   final String body;
//   final String type;
//   final String recipientUid;
//   final String? senderUid;
//   final String? senderName; // Added later from sender's user profile
//   final String? senderProfileImage;
//   final bool read;
//   final DateTime timestamp;
//   final String? tripId; // Optional reference to a specific trip
//   final String? locationId; // Optional reference to a location
//   final Map<String, dynamic>? additionalData; // For any extra data

//   TravelNotification({
//     required this.id,
//     required this.title,
//     required this.body,
//     required this.type,
//     required this.recipientUid,
//     this.senderUid,
//     this.senderName,
//     this.senderProfileImage,
//     required this.read,
//     required this.timestamp,
//     this.tripId,
//     this.locationId,
//     this.additionalData,
//   });

//   // Create from Firestore data
//   factory TravelNotification.fromJson(Map<String, dynamic> json) {
//     return TravelNotification(
//       id: json['id'] ?? '',
//       title: json['title'] ?? '',
//       body: json['body'] ?? '',
//       type: json['type'] ?? 'general',
//       recipientUid: json['recipientUid'] ?? '',
//       senderUid: json['senderUid'],
//       senderName: json['senderName'],
//       senderProfileImage: json['senderProfileImage'],
//       read: json['read'] ?? false,
//       timestamp: json['timestamp'] != null 
//           ? (json['timestamp'] as Timestamp).toDate() 
//           : DateTime.now(),
//       tripId: json['tripId'],
//       locationId: json['locationId'],
//       additionalData: json['additionalData'],
//     );
//   }

//   // Convert to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title, 
//       'body': body,
//       'type': type,
//       'recipientUid': recipientUid,
//       'senderUid': senderUid,
//       'senderName': senderName,
//       'senderProfileImage': senderProfileImage,
//       'read': read,
//       'timestamp': timestamp,
//       'tripId': tripId,
//       'locationId': locationId,
//       'additionalData': additionalData,
//     };
//   }

//   // Create a copy with some fields changed
//   TravelNotification copyWith({
//     String? id,
//     String? title,
//     String? body,
//     String? type,
//     String? recipientUid,
//     String? senderUid,
//     String? senderName,
//     String? senderProfileImage,
//     bool? read,
//     DateTime? timestamp,
//     String? tripId,
//     String? locationId,
//     Map<String, dynamic>? additionalData,
//   }) {
//     return TravelNotification(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       body: body ?? this.body,
//       type: type ?? this.type,
//       recipientUid: recipientUid ?? this.recipientUid,
//       senderUid: senderUid ?? this.senderUid,
//       senderName: senderName ?? this.senderName,
//       senderProfileImage: senderProfileImage ?? this.senderProfileImage,
//       read: read ?? this.read,
//       timestamp: timestamp ?? this.timestamp,
//       tripId: tripId ?? this.tripId,
//       locationId: locationId ?? this.locationId,
//       additionalData: additionalData ?? this.additionalData,
//     );
//   }
// }

//  Model class for travel notifications
class TravelNotification {
  final String tripId;
  final String tripName;
  final String destination;
  final DateTime startDate;
  final int daysUntil;
  final int notificationDays;

  TravelNotification({
    required this.tripId,
    required this.tripName,
    required this.destination,
    required this.startDate,
    required this.daysUntil,
    required this.notificationDays, 
  });
}