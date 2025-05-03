import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/api/firebase_auth_api.dart';
import 'package:travel_app/models/user_model.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

Stream<QuerySnapshot>? _userStream;

class AppUserProvider with ChangeNotifier {
  final FirebaseAuthAPI authService = FirebaseAuthAPI();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _uid;
  String? _firstName;
  Stream<User?> get userStream => _auth.authStateChanges();

  String? get uid => _uid;
  String? get firstName => _firstName; 

  AppUserProvider() {
    AppUserProvider();
  }

  void setUser(String? userId) {
    _uid = userId;
    notifyListeners();
  }

  void fetchUserForCurrentUser() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _uid = currentUser.uid;
      _userStream = FirebaseFirestore.instance
          .collection('appUsers')
          .where('uid', isEqualTo: currentUser.uid)
          .snapshots();

      // Fetch user's data from Firestore
      FirebaseFirestore.instance
          .collection('appUsers')
          .doc(currentUser.uid)
          .get()
          .then((userDoc) {
        if (userDoc.exists) {
          _firstName = userDoc['firstName'];
          // notifyListeners(); // Notify listeners to update the UI
        }
      });
    } else {
      _userStream = Stream.empty();
    }
    notifyListeners();
  }

  Future<String> signIn(String username, String password) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('appUsers')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (userDoc.docs.isEmpty) {
      return "No user found for that username";
    }

    final email = userDoc.docs.first['email'];
    String message = await authService.signIn(email, password);

    User? user = _auth.currentUser;
    if (user != null) {
      _uid = user.uid;
      fetchUserForCurrentUser();
    }

    return message;
  }

  Future<String?> signUp(
    String firstName,
    String lastName,
    String email,
    String password,
    String? middleName,
    String? username,
    String? phoneNumber,
  ) async {
    String? message = await authService.signUp(email, password);
    User? user = _auth.currentUser;

    if (user != null) {
      _uid = user.uid;

      await FirebaseFirestore.instance.collection('appUsers').doc(user.uid).set({
        'uid': user.uid,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'username': username,
        'phoneNumber': phoneNumber,
        'isPrivate': false,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      fetchUserForCurrentUser();
    }

    return message;
  }

  Future<String?> signInWithGoogle() async {
    String? message = await authService.signInWithGoogle();
    User? user = _auth.currentUser;

    if (message == null && user != null) {
      _uid = user.uid;

      final userDoc = FirebaseFirestore.instance.collection('appUsers').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'firstName': user.displayName?.split(' ').first ?? '',
          'lastName': user.displayName!.split(' ').length > 1
              ? user.displayName!.split(' ').sublist(1).join(' ')
              : '',
          'middleName': '',
          'username': user.email?.split('@')[0],
          'phoneNumber': user.phoneNumber,
          'isPrivate': false,
          'email': user.email,
          'createdAt': Timestamp.now(),
        });
      }

      fetchUserForCurrentUser();
    }

    return message;
  }

  Future<void> signOut() async {
    await authService.signOut();
    _uid = null;
    _firstName = null; 
    _userStream = Stream.empty();
    notifyListeners();
  }

  // Edit Profile Methods
  Future<void> updateField(String uid, String field, dynamic value) async {
    await FirebaseFirestore.instance
        .collection('appUsers')
        .doc(uid)
        .update({field: value});
    notifyListeners();
  }

  Future<void> editFirstName(String uid, String firstName) => updateField(uid, 'firstName', firstName);
  Future<void> editMiddleName(String uid, String middleName) => updateField(uid, 'middleName', middleName);
  Future<void> editLastName(String uid, String lastName) => updateField(uid, 'lastName', lastName);
  Future<void> editEmail(String uid, String email) => updateField(uid, 'email', email);
  Future<void> editAvatar(String uid, String avatar) => updateField(uid, 'avatar', avatar);
  Future<void> editPhoneNumber(String uid, String phoneNumber) => updateField(uid, 'phoneNumber', phoneNumber);
  Future<void> editPrivacyStatus(String uid, bool isPrivate) => updateField(uid, 'isPrivate', isPrivate);
  Future<void> editLocation(String uid, String location) => updateField(uid, 'location', location);
}
