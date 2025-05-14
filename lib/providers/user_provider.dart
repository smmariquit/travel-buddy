// Flutter & Material
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

// State Management
// (none in this file)

// App-specific
import 'package:travel_app/api/firebase_auth_api.dart';
import 'dart:io';
import 'dart:convert';

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
    fetchUserForCurrentUser();
  }

  void setUser(String? userId) {
    _uid = userId;
    notifyListeners();
  }

  fetchUserForCurrentUser() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _uid = currentUser.uid;
      _userStream =
          FirebaseFirestore.instance
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
    final userDoc =
        await FirebaseFirestore.instance
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
    String imageUrl, // changed from base64Image to imageUrl
  ) async {
    // Check if username already exists
    final existing =
        await FirebaseFirestore.instance
            .collection('appUsers')
            .where('username', isEqualTo: username)
            .get();

    if (existing.docs.isNotEmpty) {
      return "Username already taken";
    }

    // Get current user (already created before this function is called)
    User? user = _auth.currentUser;

    if (user != null) {
      _uid = user.uid;

      // Store user data in Firestore
      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'firstName': firstName,
            'middleName': middleName,
            'lastName': lastName,
            'username': username,
            'phoneNumber': phoneNumber,
            'isPrivate': false,
            'email': email,
            'profileImageUrl': imageUrl,
            'createdAt': Timestamp.now(),
          });

      fetchUserForCurrentUser();
    }

    return null;
  }

  signInWithGoogle() async {
    try {
      // Clear previous sign-in
      await signOutGoogle();

      // Attempt to sign in with Google
      await authService.signInWithGoogle();

      // Get the current user after sign-in
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _uid = user.uid;

        // Get first and last name from display name
        String firstName = '';
        String lastName = '';

        if (user.displayName != null) {
          List<String> nameParts = user.displayName!.split(' ');
          firstName = nameParts.first;
          lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        }

        // Check if user exists in users collection
        final userDoc = FirebaseFirestore.instance
            .collection('appUsers')
            .doc(user.uid);
        final docSnapshot = await userDoc.get();

        // If user document does not exist, create one
        if (!docSnapshot.exists) {
          await userDoc.set({
            'firstName': firstName,
            'lastName': lastName,
            'email': user.email,
            'createdAt': Timestamp.now(),
            'uid': user.uid,
            'username':
                user.email?.split('@').first ?? '', // Create a simple username
          });

          // Also create entry in appUsers collection for consistency
          await FirebaseFirestore.instance
              .collection('appUsers')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'firstName': firstName,
                'middleName': null,
                'lastName': lastName,
                'username': user.email?.split('@').first ?? '',
                'phoneNumber': user.phoneNumber,
                'isPrivate': false,
                'email': user.email,
              });
        }

        notifyListeners();
        return null; // Success (no error message)
      } else {
        return "Google sign-in failed";
      }
    } catch (e) {
      print("Error during Google sign-in: ${e.toString()}");
      return e.toString(); // Return error message
    }
  }

  Future<void> signOutGoogle() async {
    try {
      // Sign out from Firebase
      await authService.signOut();

      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Clear the user ID
      _uid = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  void loadUserStream(String uid) {
    _userStream =
        FirebaseFirestore.instance
            .collection('appUsers')
            .where('uid', isEqualTo: uid)
            .snapshots();
    notifyListeners();
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
    await FirebaseFirestore.instance.collection('appUsers').doc(uid).update({
      field: value,
    });
    notifyListeners();
  }

  Future<void> editFirstName(String uid, String firstName) =>
      updateField(uid, 'firstName', firstName);
  Future<void> editMiddleName(String uid, String middleName) =>
      updateField(uid, 'middleName', middleName);
  Future<void> editLastName(String uid, String lastName) =>
      updateField(uid, 'lastName', lastName);
  Future<void> editEmail(String uid, String email) =>
      updateField(uid, 'email', email);
  Future<void> editProfileImageUrl(String uid, String profileImageUrl) =>
      updateField(uid, 'profileImageUrl', profileImageUrl);
  Future<void> editPhoneNumber(String uid, String phoneNumber) =>
      updateField(uid, 'phoneNumber', phoneNumber);
  Future<void> editPrivacyStatus(String uid, bool isPrivate) =>
      updateField(uid, 'isPrivate', isPrivate);
  Future<void> editLocation(String uid, String location) =>
      updateField(uid, 'location', location);
}
