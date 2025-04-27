/// Since this travel app uses Cloud Firestore, this file serves as an interface to the document database.
/// Here, we retrieve, add, and edit, and delete travel records.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Encapsulate the functionality of Cloud Firestore
class FirebaseTravelAPI {
  /// A static instance of the Firestore database
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Retrieves a stream of travel records for a specific user.
  ///
  /// This method queries the `travel` collection in Firestore. We filter by the `uid`
  /// and order the results in descending order of the `createdOn` variable. This is similar to a
  /// SQL query except this is a document database which is really cool actually
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
  /// - [travel]: A map containing the travel details to be added.
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> addtravel(Map<String, dynamic> travel) async {
    try {
      await db.collection('travel').add(travel);
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
  /// - [newCategory]: The new category of the travel record.
  /// - [newAmount]: The new amount associated with the travel record.
  /// - [newIsPaid]: The new payment status of the travel record.
  ///
  /// Returns:
  /// - A [String] message indicating success or the error encountered.
  Future<String> editTravel(
    String? id,
    String newName,
    String newDesc,
    String newCategory,
    double newAmount,
    bool newIsPaid,
  ) async {
    try {
      await db.collection('travel').doc(id).update({
        'name': newName,
        'description': newDesc,
        'category': newCategory,
        'amount': newAmount,
        'isPaid': newIsPaid,
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
}
