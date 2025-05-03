// Interests
// reference indian guy https://www.youtube.com/watch?v=yB_ysDytI9k
import 'package:flutter/material.dart';
import 'package:travel_app/screens/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelStylesPage extends StatefulWidget {
  const TravelStylesPage({super.key});

  @override
  State<TravelStylesPage> createState() => _TravelStylesPageState();
}

class _TravelStylesPageState extends State<TravelStylesPage> {
  List travelStyles = [
    {"style": 'Backpacking', "selected": false},
    {"style": 'Luxury Travel', "selected": false},
    {"style": 'Solo Travel', "selected": false},
    {"style": 'Family Vacation', "selected": false},
    {"style": 'Cruise', "selected": false},
    {"style": 'Road Trip', "selected": false},
    {"style": 'Eco-Tourism', "selected": false},
    {"style": 'Adventure Travel', "selected": false}
  ];

 final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTravelStyles() async {
    User? user = _auth.currentUser;

    if (user != null) {
      List<String> selectedStyles = travelStyles
          .where((style) => style['selected'])
          .map<String>((style) => style['style'] as String)
          .toList();

      try {
        await _firestore.collection('appUsers').doc(user.uid).update({
          'travelStyles': selectedStyles,
        });
      } catch (e) {
        print("Error saving travel styles: $e");
      }
    } else {
      print("No signed-in user found.");
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
                Text("Select your travel styles", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 10),
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
        if (travelStyles.any((style) => style['selected'])) {
            await saveTravelStyles(); // Save travel styles
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50), // Full-width button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        travelStyles.any((interest) => interest['selected']) ? "Save" : "Skip",
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Colors.black),
      ),
    );

  Widget get interestChips => Wrap(
          spacing: 10,
          children: List.generate(travelStyles.length, (index){
            return InputChip(
              label: Text(travelStyles[index]['style']),
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              selected: travelStyles[index]['selected'],
              onPressed: (){
                travelStyles[index]['selected'] = !travelStyles[index]['selected'];
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
