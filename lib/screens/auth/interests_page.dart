// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';

// State Management

// App-specific
import 'package:travel_app/screens/auth/travel_styles_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({super.key});

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  List interests = [
    {"interest": 'Adventure', "selected": false, "icon": Icons.hiking},
    {"interest": 'Culture', "selected": false, "icon": Icons.museum},
    {"interest": 'Food', "selected": false, "icon": Icons.restaurant},
    {"interest": 'Nature', "selected": false, "icon": Icons.landscape},
    {"interest": 'Relaxation', "selected": false, "icon": Icons.spa},
    {"interest": 'Shopping', "selected": false, "icon": Icons.shopping_bag},
    {"interest": 'Sightseeing', "selected": false, "icon": Icons.visibility},
    {"interest": 'Sports', "selected": false, "icon": Icons.sports_soccer},
  ];

  // Firebase Authentication and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to save selected interests to Firebase
  Future<void> saveInterests() async {
    User? user = _auth.currentUser;

    if (user != null) {
      List<String> selectedInterests =
          interests
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
        automaticallyImplyLeading: false,
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
                    "What interests you?",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Select your interests to help us personalize your experience",
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
        if (interests.any((interest) => interest['selected'])) {
          await saveInterests();
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TravelStylesPage()),
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
        interests.any((interest) => interest['selected']) ? "Continue" : "Skip",
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget get interestChips => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.start,
    children: List.generate(interests.length, (index) {
      return FilterChip(
        label: Text(
          interests[index]['interest'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: interests[index]['selected'] ? Colors.white : Colors.black87,
          ),
        ),
        avatar: Icon(
          interests[index]['icon'],
          size: 16,
          color:
              interests[index]['selected']
                  ? Colors.white
                  : Colors.green.shade700,
        ),
        selected: interests[index]['selected'],
        onSelected: (bool selected) {
          setState(() {
            interests[index]['selected'] = selected;
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
                interests[index]['selected']
                    ? Colors.green.shade700
                    : Colors.grey.shade300,
            width: 1,
          ),
        ),
      );
    }),
  );
}
