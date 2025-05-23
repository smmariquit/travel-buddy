// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// State Management

// App-specific
import 'package:travel_app/screens/home/main_page.dart';
import 'package:google_fonts/google_fonts.dart';

// Interests
// reference indian guy https://www.youtube.com/watch?v=yB_ysDytI9k

class TravelStylesPage extends StatefulWidget {
  const TravelStylesPage({super.key});

  @override
  State<TravelStylesPage> createState() => _TravelStylesPageState();
}

class _TravelStylesPageState extends State<TravelStylesPage> {
  List travelStyles = [
    {"style": 'Backpacking', "selected": false, "icon": Icons.backpack},
    {"style": 'Luxury Travel', "selected": false, "icon": Icons.diamond},
    {"style": 'Solo Travel', "selected": false, "icon": Icons.person},
    {
      "style": 'Family Vacation',
      "selected": false,
      "icon": Icons.family_restroom,
    },
    {"style": 'Cruise', "selected": false, "icon": Icons.directions_boat},
    {"style": 'Road Trip', "selected": false, "icon": Icons.directions_car},
    {"style": 'Eco-Tourism', "selected": false, "icon": Icons.eco},
    {"style": 'Adventure Travel', "selected": false, "icon": Icons.terrain},
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTravelStyles() async {
    User? user = _auth.currentUser;

    if (user != null) {
      List<String> selectedStyles =
          travelStyles
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    "How do you travel?",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Select your preferred travel styles",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  interestChips,
                ],
              ),
              saveOrSkipButton,
            ],
          ),
        ),
      ),
    );
  }

  Widget get saveOrSkipButton => Container(
    margin: EdgeInsets.only(bottom: 16),
    child: ElevatedButton(
      onPressed: () async {
        if (travelStyles.any((style) => style['selected'])) {
          await saveTravelStyles();
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      child: Text(
        travelStyles.any((style) => style['selected']) ? "Continue" : "Skip",
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget get interestChips => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.start,
    children: List.generate(travelStyles.length, (index) {
      return FilterChip(
        label: Text(
          travelStyles[index]['style'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color:
                travelStyles[index]['selected'] ? Colors.white : Colors.black87,
          ),
        ),
        avatar: Icon(
          travelStyles[index]['icon'],
          size: 16,
          color:
              travelStyles[index]['selected']
                  ? Colors.white
                  : Colors.green.shade700,
        ),
        selected: travelStyles[index]['selected'],
        onSelected: (bool selected) {
          setState(() {
            travelStyles[index]['selected'] = selected;
          });
        },
        selectedColor: Colors.green.shade700,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                travelStyles[index]['selected']
                    ? Colors.green.shade700
                    : Colors.grey.shade300,
            width: 1,
          ),
        ),
      );
    }),
  );
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
