import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/api/firebase_user_api.dart';
import 'package:travel_app/models/user_model.dart';

class AppUserProvider with ChangeNotifier {
  late Stream<QuerySnapshot> _userStream;

  final FirebaseAppUserApi firebaseService = FirebaseAppUserApi();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> get userStream => _userStream;

  AppUserProvider() {
    fetchUserForCurrentUser();
  }

  void fetchUserForCurrentUser() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _userStream = firebaseService.getAppUserByUID(currentUser.uid);
    } else {
      _userStream = Stream.empty();
    }
    notifyListeners();
  }

  Future<void> addAppUser(AppUser user) async {
    String message = await firebaseService.addAppUser(user.toJson());
    print(message);
    notifyListeners();
  }

  Future<void> deleteAppUser(String uid) async {
    String message = await firebaseService.deleteAppUser(uid);
    print(message);
    notifyListeners();
  }

  Future<void> editFirstName(String uid, String firstName) async {
    String message = await firebaseService.editAppUserFirstName(uid, firstName);
    print(message);
    notifyListeners();
  }

  Future<void> editMiddleName(String uid, String middleName) async {
    String message = await firebaseService.editAppUserMiddleName(uid, middleName);
    print(message);
    notifyListeners();
  }

  Future<void> editLastName(String uid, String lastName) async {
    String message = await firebaseService.editAppUserLastName(uid, lastName);
    print(message);
    notifyListeners();
  }

  Future<void> editEmail(String uid, String email) async {
    String message = await firebaseService.editAppUserEmail(uid, email);
    print(message);
    notifyListeners();
  }

  Future<void> editAvatar(String uid, String avatar) async {
    String message = await firebaseService.editAppUserAvatar(uid, avatar);
    print(message);
    notifyListeners();
  }

  Future<void> editPhoneNumber(String uid, String phoneNumber) async {
    String message = await firebaseService.editAppUserPhoneNumber(uid, phoneNumber);
    print(message);
    notifyListeners();
  }

  Future<void> editPrivacyStatus(String uid, bool isPrivate) async {
    String message = await firebaseService.editAppUserPrivacyStatus(uid, isPrivate);
    print(message);
    notifyListeners();
  }

  Future<void> editLocation(String uid, String location) async {
    String message = await firebaseService.editAppUserLocation(uid, location);
    print(message);
    notifyListeners();
  }
}
