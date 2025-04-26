import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTravelAPI {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getUserTravels(String uid) {
  return db
    .collection('travel')
    .where('uid', isEqualTo: uid)
    .orderBy('createdOn', descending: true)
    .snapshots();
}

  Future<String> addtravel(Map<String, dynamic> travel) async { 
    try {
      await db.collection('travel').add(travel);

      return "Success";
    } on FirebaseException catch (e){
      return "Error on ${e.message}";
    }
  }

    Future<String> deleteTravel(String id) async { 
    try {
      await db.collection('travel').doc(id).delete();

      return "Successfully deleted";
    } on FirebaseException catch (e){
      return "Error on ${e.message}";
    }
  }

  Future<String> editTravel(String? id, String newName, String newDesc, String newCategory, double newAmount, bool newIsPaid) async {
  try {
    await db.collection('travel').doc(id).update({
      'name': newName,
      'description': newDesc,
      'category': newCategory,
      'amount': newAmount,
      'isPaid': newIsPaid});

    return "Travel updated!";
  } on FirebaseException catch (e) {
    return "Error updating travel: $e";
  }
}


  Future<String> toggleStatus(String id, bool isPaid) async { 
    try {
      await db.collection('travel').doc(id).update({'isPaid': isPaid});

      return "Success";
    } on FirebaseException catch (e){
      return "Error on ${e.message}";
    }
  }
}