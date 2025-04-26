import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/api/firebase_auth_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAuthProvider with ChangeNotifier {
  late FirebaseAuthAPI authService;
  late Stream<User?> userStream;
  String? _uid;

  UserAuthProvider(){
    authService = FirebaseAuthAPI();
    userStream = authService.getUserStream();
  }

  String? get uid => _uid;

  void setUser(String? userId) {
    _uid = userId;
    notifyListeners();
  }

  Future<String> signIn(String email, String password) async {
  String message = await authService.signIn(email, password);
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) _uid = user.uid;
  notifyListeners();
  return message;
}

Future<String?> signUp(String firstName, String lastName, String email, String password) async {
  String? message = await authService.signUp(email, password);
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    _uid = user.uid;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'createdAt': Timestamp.now(),
      'uid': user.uid,
    });
  }
  notifyListeners();
  return message;
}


  Future<void> signOut() async {
    await authService.signOut();
    _uid = null;
    notifyListeners();
  }
}

