import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_app/api/firebase_travel_api.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravelTrackerProvider with ChangeNotifier {
  late Stream<QuerySnapshot> _travelsStream;
  FirebaseTravelAPI? firebaseService; 
  String? currentUserId;

  TravelTrackerProvider() {
    // really empty
  }

  void setUser(String? userId) {
    currentUserId = userId;

    // Initialize firebaseService when user is set
    if (userId != null) {
      firebaseService = FirebaseTravelAPI();
      fetchTravels(); // Fetch travels after initializing  user
    } else {
      firebaseService = null;
      _travelsStream = Stream.empty(); // Empty stream when no user
    }
    
    notifyListeners();
  }

  // Fetch stream from Firestore for the current user
  void fetchTravels() {
    if (currentUserId == null || firebaseService == null) {
      return;
    }

    _travelsStream = FirebaseFirestore.instance
        .collection('travel')
        .where('uid', isEqualTo: currentUserId)
        .snapshots();
    
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

  void clearUser() {
    currentUserId = null;
    firebaseService = null;
    _travelsStream = Stream.empty();
    notifyListeners();
  }

  // // Add travel
  // Future<void> addTravel(Travel item) async {
  //   if (currentUserId == null || firebaseService == null) {
  //     print("ERROR: Cannot add travel, user is not set.");
  //     return;
  //   }

  //   item.uid = currentUserId!;
  //   String message = await firebaseService!.addTravel(item.toJson());
  //   print(message);
  //   notifyListeners();
  // }

  // // Edit travel
  // Future<void> editTravel(String id, String name, String description, String category, double amount, bool isPaid) async {
  //   try {
  //     await FirebaseFirestore.instance.collection('travel').doc(id).update({
  //       'name': name,
  //       'description': description,
  //       'category': category,
  //       'amount': amount,
  //       'isPaid': isPaid,
  //       'uid': currentUserId,
  //     });
  //     notifyListeners();
  //   } catch (e) {
  //     print("Error updating travel: $e");
  //   }
  // }

  // // Delete travel
  // Future<void> deleteTravel(String id) async {
  //   if (firebaseService == null) return;

  //   String message = await firebaseService!.deleteTravel(id);
  //   print(message);
  //   notifyListeners();
  // }

  // // Toggle paid status
  // Future<void> toggleStatus(String id, bool status) async {
  //   if (firebaseService == null) return;

  //   String message = await firebaseService!.toggleStatus(id, status);
  //   print(message);
  //   notifyListeners();
  // }

  // // --- Derived Calculations for Dashboard ---

  // // Calculate total travels from a snapshot
  // double getTotalTravels(List<QueryDocumentSnapshot> docs) {
  //   return docs.fold(0.0, (sum, doc) => sum + (doc['amount']));
  // }

  // // Calculate total paid
  // double getPaidTravels(List<QueryDocumentSnapshot> docs) {
  //   return docs.where((doc) => doc['isPaid']).fold(0.0, (sum, doc) => sum + (doc['amount']));
  // }

  // // Calculate total unpaid
  // double getUnpaidTravels(List<QueryDocumentSnapshot> docs) {
  //   return docs.where((doc) => !doc['isPaid']).fold(0.0, (sum, doc) => sum + (doc['amount']));
  // }

  // // Get category-wise total
  // Map<String, double> getCategoryTotals(List<QueryDocumentSnapshot> docs) {
  //   final Map<String, double> map = {};
  //   for (var d in docs) {
  //     map[d['category']] = (map[d['category']] ?? 0.0) + (d['amount']);
  //   }
  //   return map;
  // }
}
