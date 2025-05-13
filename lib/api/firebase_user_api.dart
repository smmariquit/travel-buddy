import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAppUserApi {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String _collection = 'appUsers';

  Stream<QuerySnapshot> getAllAppUsers() {
    return db.collection('appUsers').snapshots();
  }

  Stream<QuerySnapshot> getAppUserByUID(String uid) {
    return db.collection('appUsers').where('uid', isEqualTo: uid).snapshots();
  }

  Future<String> addAppUser(Map<String, dynamic> appUser) async {
    try {
      await db.collection('appUsers').add(appUser);
      return "Successfully added user!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> deleteAppUser(String uid) async {
    try {
      await db.collection('appUsers').doc(uid).delete();
      return "Successfully deleted user!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserFirstName(String uid, String firstName) async {
    try {
      await db.collection('appUsers').doc(uid).update({'firstName': firstName});
      return "Successfully edited first name!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserMiddleName(String uid, String middleName) async {
    try {
      await db.collection('appUsers').doc(uid).update({
        'middleName': middleName,
      });
      return "Successfully edited middle name!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserLastName(String uid, String lastName) async {
    try {
      await db.collection('appUsers').doc(uid).update({'lastName': lastName});
      return "Successfully edited last name!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserEmail(String uid, String email) async {
    try {
      await db.collection('appUsers').doc(uid).update({'email': email});
      return "Successfully edited email!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserAvatar(String uid, String avatar) async {
    try {
      await db.collection('appUsers').doc(uid).update({'avatar': avatar});
      return "Successfully edited avatar!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserPhoneNumber(String uid, String phoneNumber) async {
    try {
      await db.collection('appUsers').doc(uid).update({
        'phoneNumber': phoneNumber,
      });
      return "Successfully edited phone number!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserPrivacyStatus(String uid, bool isPrivate) async {
    try {
      await db.collection('appUsers').doc(uid).update({'isPrivate': isPrivate});
      return "Successfully updated privacy status!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  Future<String> editAppUserLocation(String uid, String location) async {
    try {
      await db.collection('appUsers').doc(uid).update({'location': location});
      return "Successfully updated location!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }

  // Generic update field method
  Future<String> updateAppUserField(
    String uid,
    String field,
    dynamic value,
  ) async {
    try {
      await db.collection(_collection).doc(uid).update({field: value});
      return "Successfully updated $field!";
    } on FirebaseException catch (e) {
      return "Error on ${e.code}: ${e.message}";
    }
  }
}
