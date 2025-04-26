import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';


class Travel {
  String? id;
  String uid;
  final String name;
  final String description;
  final String category;
  final double amount;
  final bool isPaid;
  final DateTime createdOn;

  Travel({
    this.id,
    required this.uid,
    required this.name,
    required this.description,
    required this.category,
    required this.amount,
    required this.isPaid,
    required this.createdOn,
  });

  // Factory constructor to instantiate object from json format
  factory Travel.fromJson(Map<String, dynamic> json) {
    //Convert json to Expense object 
    return Travel(
      id: json['id'],
      uid: json['uid'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      isPaid: json['isPaid'],
      createdOn: (json['createdOn'] as Timestamp).toDate(),
    );
  }

  static List<Travel> fromJsonArray(String jsonData) {
    final Iterable<dynamic> data = jsonDecode(jsonData);
    return data.map<Travel>((dynamic d) => Travel.fromJson(d)).toList();
  }

  //from json to Expense
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'description': description, 
      'category': category,
      'amount': amount, 
      'isPaid': isPaid,
      'createdOn': createdOn,
      };
  }
}