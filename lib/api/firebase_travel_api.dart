/// Since this travel app uses Cloud Firestore, this file serves as an interface to the document database.
/// Here, we retrieve, add, edit, delete, and share travel records.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_app/models/travel_plan_model.dart';
// TODO: Correct the comments
/// Encapsulate the functionality of Cloud Firestore
class FirebaseTravelAPI {
  /// A static instance of the Firestore database
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Retrieves a stream of travel records created by or shared with the user.
  ///
  /// Parameters:
  /// - [uid]: The user ID to filter the travel records.
  ///
  /// Returns:
  /// - A [Stream] of [QuerySnapshot] containing the user's travel records.
  Stream<QuerySnapshot> getUserTravels(String uid) {
    return db
        .collection('travel')
        .where('sharedWith', arrayContains: uid) // Includes shared travels
        .orderBy('createdOn', descending: true)
        .snapshots();
  }

  /// Adds a new travel record to the Firestore database.
  ///
  /// Parameters:
  /// - [travel]: A map containing the travel details to be added.
  ///
  /// Required fields: name, date (can be range), location, uid, createdOn  
  /// Optional fields: flightDetails, accommodation, notes, checklist (List), itinerary (List or Map), sharedWith (List)
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> addTravel(Travel travel) async {
  try {
    final docRef = await db.collection('travel').add(travel.toJson());
    return docRef.id; 
  } on FirebaseException catch (e) {
    return "Error on ${e.message}";
  }
}


  /// Deletes a travel record from the Firestore database.
  ///
  /// Parameters:
  /// - [id]: The document ID of the travel record to be deleted.
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> deleteTravel(String id) async {
    try {
      await db.collection('travel').doc(id).delete();
      return "Successfully deleted";
    } on FirebaseException catch (e) {
      return "Error on ${e.message}";
    }
  }

  /// Edits an existing travel record in the Firestore database.
  ///
  /// Only the owner (creator) should be allowed to perform this action.
  ///
  /// Parameters:
  /// - [id]: The document ID of the travel record to be updated.
  /// - [newData]: A map containing the updated fields and values.
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> editTravel(String id, Travel updatedTravel) async {
    try {
      await db.collection('travel').doc(id).update(updatedTravel.toJson());
      return "Travel updated!";
    } on FirebaseException catch (e) {
      return "Error updating travel: $e";
    }
  }

  /// Toggles the payment status of a travel record in the Firestore database.
  ///
  /// Parameters:
  /// - [id]: The document ID of the travel record to be updated.
  /// - [isPaid]: The new payment status to be set.
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> toggleStatus(String id, bool isPaid) async {
    try {
      await db.collection('travel').doc(id).update({'isPaid': isPaid});
      return "Success";
    } on FirebaseException catch (e) {
      return "Error on ${e.message}";
    }
  }

  /// Shares a travel plan with another user by adding their UID to `sharedWith`.
  ///
  /// Parameters:
  /// - [id]: The document ID of the travel record.
  /// - [friendUid]: The UID of the user to share the plan with.
  ///
  /// Returns:
  /// - A [String] message indicating success or failure.
  Future<String> shareTravelWithUser(String travelId, String friendUid) async {
    try {
      await db.collection('travel').doc(travelId).update({
        'sharedWith': FieldValue.arrayUnion([friendUid]),
      });
      return "Shared successfully";
    } on FirebaseException catch (e) {
      return "Error: ${e.message}";
    }
  }

  /// Removes a user from a shared travel plan.
  ///
  /// Parameters:
  /// - [id]: The travel plan document ID.
  /// - [uidToRemove]: The UID to remove from the sharedWith array.
  ///
  /// Returns:
  /// - A [String] message indicating success or error.
  Future<String> removeSharedUser(String travelId, String friendUid) async {
    try {
      await db.collection('travel').doc(travelId).update({
        'sharedWith': FieldValue.arrayRemove([friendUid]),
      });
      return "User removed";
    } on FirebaseException catch (e) {
      return "Error: ${e.message}";
    }
  }

  /// Adds or updates the itinerary for a travel plan.
  ///
  /// Parameters:
  /// - [id]: The travel plan document ID.
  /// - [itinerary]: A list or map of itinerary details (e.g., daily plans or time-based schedule).
  ///
  /// Returns:
  /// - A [String] message indicating success or error.
  Future<String> updateItinerary(String id, dynamic itinerary) async {
    try {
      await db.collection('travel').doc(id).update({
        'itinerary': itinerary,
      });
      return "Itinerary updated";
    } on FirebaseException catch (e) {
      return "Error updating itinerary: ${e.message}";
    }
  }

  /// Generates a shareable QR code string for a travel plan ID.
  ///
  /// Parameters:
  /// - [id]: The travel plan ID to encode.
  ///
  /// Returns:
  /// - A [String] representing the encoded QR value (usually just the ID or link).
  String generateQRCodeValue(String id) {
    return "travelplan:$id"; // Could be just the ID, or a deep link format
  }
}


