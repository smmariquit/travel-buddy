import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/models/user_model.dart';

Future<void> showFriendProfileBottomSheet(BuildContext context, String friendUID) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return FutureBuilder<AppUser?>(
        future: _fetchFriendData(friendUID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('Failed to load profile')),
            );
          }

          final friend = snapshot.data!;

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top drag handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Title
                  Text(
                    "${friend.firstName}'s Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
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
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
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
                                const Icon(Icons.location_on, color: Colors.grey),
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
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<AppUser?> _fetchFriendData(String uid) async {
  final doc = await FirebaseFirestore.instance.collection('appUsers').doc(uid).get();
  if (doc.exists) {
    return AppUser.fromJson(doc.data()!);
  } else {
    return null;
  }
}
