import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_plan_model.dart';  // Import the TravelPlan model

/// Encapsulate the functionality of Cloud Firestore
class FirebaseTravelAPI {
  /// A static instance of the Firestore database
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Retrieves a stream of travel records for a specific user.
  ///
  /// This method queries the `travel` collection in Firestore. We filter by the `uid`
  /// and order the results in descending order of the `createdOn` variable.
  ///
  /// Parameters:
  /// - [uid]: The user ID to filter the travel records.
  ///
  /// Returns:
  /// - A [Stream] of [QuerySnapshot] containing the user's travel records.
  Stream<QuerySnapshot> getUserTravels(String uid) {
    return db
        .collection('travel')
        .where('uid', isEqualTo: uid)
        .orderBy('createdOn', descending: true)
        .snapshots();
  }

  /// Adds a new travel record to the Firestore database.
  ///
  /// Parameters:
  /// - [travelPlan]: A [TravelPlan] object containing the travel details to be added.
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> addTravelPlan(TravelPlan travelPlan) async {
    try {
      await db.collection('travel').add(travelPlan.toJson());
      return "Success";
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
  /// Parameters:
  /// - [id]: The document ID of the travel record to be updated.
  /// - [newName]: The new name of the travel record.
  /// - [newDesc]: The new description of the travel record.
  /// - [newLocation]: The new location of the travel record.
  /// - [newStartDate]: The new start date for the travel record.
  /// - [newEndDate]: The new end date for the travel record.
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> editTravel(
    String id,
    String newName,
    String newDesc,
    String newLocation,
    DateTime newStartDate,
    DateTime newEndDate,
  ) async {
    try {
      await db.collection('travel').doc(id).update({
        'name': newName,
        'description': newDesc,
        'location': newLocation,
        'startDate': newStartDate,
        'endDate': newEndDate,
      });

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

  /// Retrieves a stream of travel records for a specific user, mapped to TravelPlan.
  ///
  /// This method queries the `travel` collection in Firestore. We filter by the `uid`
  /// and order the results in descending order of the `createdOn` variable, then map
  /// the query snapshots to [TravelPlan] objects.
  ///
  /// Parameters:
  /// - [uid]: The user ID to filter the travel records.
  ///
  /// Returns:
  /// - A [Stream] of a list of [TravelPlan] objects.
  Stream<List<TravelPlan>> getUserTravelPlans(String uid) {
    return db
        .collection('travel')
        .where('uid', isEqualTo: uid)
        .orderBy('createdOn', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TravelPlan.fromJson(doc.data(), doc.id)).toList());
  }
}
