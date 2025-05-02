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

  
    await FirebaseFirestore.instance.collection('appUsers').doc(user.uid).set({
      'uid': user.uid,
      'firstName': firstName,
      'middleName': middleName,  
      'lastName': lastName,
      'username': username,      
      'phoneNumber': phoneNumber, 
      'isPrivate': false,       
      'email': email,
    });
  }

  notifyListeners();
  return message;
}


Future<String?> signInWithGoogle() async {
  String? message = await authService.signInWithGoogle();
  User? user = FirebaseAuth.instance.currentUser;

  if (message == null && user != null) {
    _uid = user.uid;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'firstName': user.displayName?.split(' ').first ?? '',
        'lastName': user.displayName!.split(' ').length > 1
            ? user.displayName!.split(' ').sublist(1).join(' ')
            : '',
        'email': user.email,
        'createdAt': Timestamp.now(),
        'uid': user.uid,
      });
    }
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

