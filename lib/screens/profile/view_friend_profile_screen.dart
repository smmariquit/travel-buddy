import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/models/user_model.dart';

class ViewFriendProfileScreen extends StatelessWidget {
  final String friendUID;

  const ViewFriendProfileScreen({
    Key? key,
    required this.friendUID,
  }) : super(key: key);

  Future<AppUser?> _fetchFriendData() async {
    final doc = await FirebaseFirestore.instance
        .collection('appUsers')
        .doc(friendUID)
        .get();

    if (doc.exists) {
      return AppUser.fromJson(doc.data()!);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _fetchFriendData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Failed to load profile')),
          );
        }

        final friend = snapshot.data;

        if (friend == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            title: Text(
              "${friend.firstName}'s Profile",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: friend.profileImageUrl != null
                            ? NetworkImage(friend.profileImageUrl!)
                            : null,
                        child: friend.profileImageUrl == null
                            ? Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Full name
                      Text(
                        '${friend.firstName} ${friend.lastName}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Username
                      if (friend.username != null) ...[
                        const SizedBox(height: 6),
                        Text('@${friend.username}',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey)),
                      ],

                      const SizedBox(height: 20),

                      // Location
                      if (friend.location != null &&
                          friend.location!.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(friend.location!,
                                style: GoogleFonts.poppins(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Interests
                      if (friend.interests != null &&
                          friend.interests!.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Interests:',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: friend.interests!
                              .map((interest) => Chip(
                                    label: Text(
                                      interest,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Travel Styles
                      if (friend.travelStyles != null &&
                          friend.travelStyles!.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Travel Styles:',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: friend.travelStyles!
                              .map((style) => Chip(
                                    label: Text(style,
                                        style: GoogleFonts.poppins()),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
