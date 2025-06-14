// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// State Management

// App-specific
import 'package:travel_app/api/firebase_travel_api.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:async/async.dart';

class TravelTrackerProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseTravelAPI? _firebaseService;
  FirebaseTravelAPI get firebaseService {
    _firebaseService ??= FirebaseTravelAPI();
    return _firebaseService!;
  }

  String? _userId;
  List<Travel> _travels = [];
  bool _isLoading = false;
  late Stream<QuerySnapshot> _travelsStream;

  // Getters
  String? get userId => _userId;
  List<Travel> get travels => _travels;
  bool get isLoading => _isLoading;
  Stream<QuerySnapshot> get travelStream => _travelsStream;

  Stream<List<Travel>> getSharedTravelPlans() {
    if (_userId == null) return Stream.value([]);
    return firebaseService.getSharedTravels(_userId!);
  }

  // Set current user and initialize services/streams
  void setUser(String? uid) {
    if (_userId == uid) return; // Skip if user hasn't changed

    _userId = uid;
    bool shouldNotify = false;

    if (uid != null) {
      _firebaseService = FirebaseTravelAPI();
      fetchTravelsStream();
      shouldNotify = true;
    } else {
      _firebaseService = null;
      _travelsStream = Stream.empty();
      _travels = [];
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  // Clear context
  void clearUser() {
    _userId = null;
    _firebaseService = null;
    _travelsStream = Stream.empty();
    _travels = [];
    notifyListeners();
  }

  // Firestore stream for real-time updates
  void fetchTravelsStream() {
    if (_userId == null) return;

    final ownTravels =
        _firestore
            .collection('travel')
            .where('uid', isEqualTo: _userId!)
            .snapshots();

    final sharedTravels =
        _firestore
            .collection('travel')
            .where('sharedWith', arrayContains: _userId!)
            .snapshots();

    _travelsStream = StreamGroup.merge([ownTravels, sharedTravels]);
    notifyListeners();
  }

  // Fetch travel plans into local list
  Future<List<Travel>> getTravelPlans() async {
    if (_userId == null) return [];

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot =
          await _firestore
              .collection('travel')
              .where('uid', isEqualTo: _userId)
              .orderBy('createdOn', descending: true)
              .get();

      _travels =
          snapshot.docs
              .map((doc) => Travel.fromJson(doc.data(), doc.id))
              .toList();

      _isLoading = false;
      notifyListeners();
      return _travels;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Add a travel plan
  Future<Travel?> addTravelPlan(Travel travel) async {
    if (_userId == null) return null;

    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection('travel').add(travel.toJson());

      final newTravel = travel.copyWith(id: docRef.id);
      _travels.insert(0, newTravel);

      _isLoading = false;
      notifyListeners();
      return newTravel;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Edit a travel plan
  Future<bool> updateTravelPlan(Travel travel) async {
    if (_userId == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('travel')
          .doc(travel.id)
          .update(travel.toJson());

      final index = _travels.indexWhere((t) => t.id == travel.id);
      if (index >= 0) {
        _travels[index] = travel;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete travel plan
  Future<bool> deleteTravelPlan(String travelId) async {
    if (_userId == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('travel').doc(travelId).delete();
      _travels.removeWhere((t) => t.id == travelId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Share travel plan
  Future<void> shareTravelWithUser(String travelId, String userId) async {
    try {
      await _firestore.collection('travel').doc(travelId).update({
        'sharedWith': FieldValue.arrayUnion([userId]),
      });
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Unshare travel plan
  Future<void> unshareTravelWithUser(String travelId, String userId) async {
    try {
      await _firestore.collection('travel').doc(travelId).update({
        'sharedWith': FieldValue.arrayRemove([userId]),
      });
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update activities list in a travel plan
  Future<void> updateActivities(
    String travelId,
    List<Activity> activities,
  ) async {
    if (_userId == null) return;

    try {
      await firebaseService.updateActivities(travelId, activities);
      notifyListeners();
    } catch (e) {
      rethrow; // Rethrow to let the caller handle the error
    }
  }

  // Filtered stream by category
  Stream<QuerySnapshot> getTravelsByCategory(String category) {
    return _firestore
        .collection('travel')
        .where('uid', isEqualTo: _userId)
        .where('category', isEqualTo: category)
        .snapshots();
  }
}
