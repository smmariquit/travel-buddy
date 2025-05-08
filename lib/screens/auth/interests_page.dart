// Interests
// reference indian guy https://www.youtube.com/watch?v=yB_ysDytI9k
import 'package:flutter/material.dart';
import 'package:travel_app/screens/auth/travel_styles_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({super.key});

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  List interests = [
    {"interest": 'Adventure', "selected": false},
    {"interest": 'Culture', "selected": false},
    {"interest": 'Food', "selected": false},
    {"interest": 'Nature', "selected": false},
    {"interest": 'Relaxation', "selected": false},
    {"interest": 'Shopping', "selected": false},
    {"interest": 'Sightseeing', "selected": false},
    {"interest": 'Sports', "selected": false}
  ];

  // Firebase Authentication and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to save selected interests to Firebase
  Future<void> saveInterests() async {
  User? user = _auth.currentUser;

  if (user != null) {
    List<String> selectedInterests = interests
        .where((interest) => interest['selected'])
        .map<String>((interest) => interest['interest'] as String)
        .toList();

    try {
      await _firestore.collection('appUsers').doc(user.uid).update({
        'interests': selectedInterests,
      });
    } catch (e) {
      print("Failed to save interests: $e");
    }
  } else {
    print("No user is currently signed in.");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text("Help us know you better.", style: TextStyle(fontSize: 25)),
                const SizedBox(height: 10),
                Text("Select your interests", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 15),
                interestChips,
              ],
            ),
            saveOrSkipButton,
          ]
        )
      )
    );
  }

  Widget get saveOrSkipButton => ElevatedButton(
      onPressed: () async {
      if (interests.any((interest) => interest['selected'])) {
        await saveInterests();  // Save to Firestore
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TravelStylesPage()),
      );
    },

      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50), // Full-width button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        interests.any((interest) => interest['selected']) ? "Save" : "Skip",
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Colors.black),
      ),
    );

  Widget get interestChips => Wrap(
          spacing: 10,
          children: List.generate(interests.length, (index){
            return InputChip(
              label: Text(interests[index]['interest']),
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              selected: interests[index]['selected'],
              onPressed: (){
                interests[index]['selected'] = !interests[index]['selected'];
                setState(() {
                });
              },
              selectedColor: Colors.blue,
            );
          }));
      //   child: Container(
      //     margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      //     child: Form(
      //       key: _formKey,
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         children: [
      //           heading,
      //           const SizedBox(height: 10),
      //           subtitle,
      //           const SizedBox(height: 40),
      //           firstNameField,
      //           lastNameField,
      //           emailField,
      //           passwordField,
      //           submitButton,
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
}
