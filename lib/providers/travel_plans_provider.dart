import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_app/api/firebase_travel_api.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';
import 'package:travel_app/models/travel_plan_model.dart';

class TravelTrackerProvider with ChangeNotifier {
  late Stream<QuerySnapshot> _travelsStream;
  FirebaseTravelAPI? firebaseService;
  String? currentUserId;

  TravelTrackerProvider() {
    // Constructor is empty for now
  }

  void setUser(String? userId) {
    currentUserId = userId;

    // Initialize firebaseService when user is set
    if (userId != null) {
      firebaseService = FirebaseTravelAPI();
      fetchTravels(); // Fetch travels after initializing user
    } else {
      firebaseService = null;
      _travelsStream = Stream.empty(); // Empty stream when no user
    }
    notifyListeners();
  }

  /// Fetch stream of travel plans (created or shared with the user)
  void fetchTravels() {
    if (currentUserId == null || firebaseService == null) {
      return;
    }

    var ownTravelsStream = FirebaseFirestore.instance
        .collection('travel')
        .where('uid', isEqualTo: currentUserId) // User's own travels
        .snapshots();

    var sharedTravelsStream = FirebaseFirestore.instance
        .collection('travel')
        .where('sharedWith', arrayContains: currentUserId) // Shared travels
        .snapshots();

    _travelsStream = StreamGroup.merge([ownTravelsStream, sharedTravelsStream]);

    notifyListeners();
  }

  Stream<QuerySnapshot> get travelStream => _travelsStream;

  // Method to fetch travels by category
  Stream<QuerySnapshot> getTravelsByCategory(String category) {
    return FirebaseFirestore.instance
        .collection('travel')
        .where('uid', isEqualTo: currentUserId)
        .where('category', isEqualTo: category)
        .snapshots();
  }

  // Method to add a new travel plan
  Future<String> addTravel(Map<String, dynamic> travelData) async {
    try {
      // Adding the travel plan to the 'travel' collection
      await FirebaseFirestore.instance.collection('travel').add(travelData);

      return 'Travel plan added successfully';
    } catch (e) {
      print("Error adding travel: $e");
      return 'Failed to add travel plan';
    }
  }

  // Method to edit an existing travel plan
  Future<void> updateTravel(String id, Travel updatedTravel) async {
    if (currentUserId == null || firebaseService == null) {
      print("ERROR: Cannot update travel, user is not set.");
      return;
    }

    try {
      await firebaseService!.editTravel(id, updatedTravel);
      notifyListeners();
    } catch (e) {
      print("Error updating travel: $e");
    }
  }

  // Method to delete a travel plan
  Future<void> deleteTravel(String id) async {
    if (firebaseService == null) {
      return;
    }

    try {
      await firebaseService!.deleteTravel(id);
      notifyListeners();
    } catch (e) {
      print("Error deleting travel: $e");
    }
  }

  // Method to share a travel plan with another user
  Future<void> shareTravelWithUser(String travelId, String userId) async {
    if (firebaseService == null || currentUserId == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('travel').doc(travelId).update({
        'sharedWith': FieldValue.arrayUnion([userId]),
      });
      notifyListeners();
    } catch (e) {
      print("Error sharing travel: $e");
    }
  }

  // Method to unshare a travel plan with another user
  Future<void> unshareTravelWithUser(String travelId, String userId) async {
    if (firebaseService == null || currentUserId == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('travel').doc(travelId).update({
        'sharedWith': FieldValue.arrayRemove([userId]),
      });
      notifyListeners();
    } catch (e) {
      print("Error unsharing travel: $e");
    }
  }

  // Helper to clear the user context and reset stream
  void clearUser() {
    currentUserId = null;
    firebaseService = null;
    _travelsStream = Stream.empty();
    notifyListeners();
  }
}
