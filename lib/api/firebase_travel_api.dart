import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_app/models/travel_plan_model.dart';

/// Firebase service class for managing travel plans.
class FirebaseTravelAPI {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Adds a new travel plan and returns its document ID.
  Future<String> addTravel(Travel travel) async {
    try {
      final docRef = _db.collection('travel').doc();
      final updatedTravel = travel.copyWith(id: docRef.id);
      await docRef.set(updatedTravel.toJson());
      return docRef.id;
    } catch (e) {
      return "Error adding travel: $e";
    }
  }

  /// Updates an existing travel plan.
  Future<String> updateTravel(Travel travel) async {
    try {
      if (travel.id.isEmpty) {
        return "Travel ID is empty";
      }
      await _db.collection('travel').doc(travel.id).update(travel.toJson());
      return "Travel updated!";
    } catch (e) {
      return "Error updating travel: $e";
    }
  }

  /// Deletes a travel plan by ID.
  Future<String> deleteTravel(String id) async {
    try {
      await _db.collection('travel').doc(id).delete();
      return "Successfully deleted";
    } catch (e) {
      return "Error deleting travel: $e";
    }
  }

  /// Gets travel plans created by the user.
  Stream<List<Travel>> getTravelsForUser(String userId) {
    return _db
        .collection('travel')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdOn', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Travel.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Gets travel plans shared with the user.
  Stream<List<Travel>> getSharedTravels(String userId) {
    return _db
        .collection('travel')
        .where('sharedWith', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Travel.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Gets a travel plan by ID.
  Future<Travel?> getTravelById(String travelId) async {
    try {
      final doc = await _db.collection('travel').doc(travelId).get();
      if (doc.exists && doc.data() != null) {
        return Travel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Shares a travel plan with another user.
  Future<String> shareTravelWithUser(String travelId, String friendUid) async {
    const successMessage = "Travel plan shared successfully";
    try {
      final doc = await _db.collection('travel').doc(travelId).get();
      if (!doc.exists) return "Travel plan not found";

      final travel = Travel.fromJson(doc.data()!, doc.id);
      if (travel.uid == friendUid) {
        return "Cannot share travel plan with yourself";
      }

      final sharedWith = travel.sharedWith ?? [];

      if (sharedWith.contains(friendUid)) return "Already shared with user";

      sharedWith.add(friendUid);

      await _db.collection('travel').doc(travelId).update({
        'sharedWith': sharedWith,
      });

      return successMessage;
    } catch (e) {
      return "Failed to share travel plan";
    }
  }

  /// Removes a user from the sharedWith list.
  Future<String> removeSharedUser(String travelId, String friendUid) async {
    try {
      await _db.collection('travel').doc(travelId).update({
        'sharedWith': FieldValue.arrayRemove([friendUid]),
      });
      return "User removed";
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Updates itinerary field of a travel plan.
  Future<String> updateItinerary(String id, dynamic itinerary) async {
    try {
      await _db.collection('travel').doc(id).update({'itinerary': itinerary});
      return "Itinerary updated";
    } catch (e) {
      return "Error updating itinerary: $e";
    }
  }

  /// Updates activities field of a travel plan.
  Future<String> updateActivities(
    String travelId,
    List<Activity> activities,
  ) async {
    try {
      final activityData = activities.map((a) => a.toJson()).toList();
      await _db.collection('travel').doc(travelId).update({
        'activities': activityData,
      });
      return "Activities updated";
    } catch (e) {
      return "Error updating activities: $e";
    }
  }

  /// Generates a QR code value (usually just the travel ID).
  String generateQRCodeValue(String travelId) {
    return travelId;
  }
}
