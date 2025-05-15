// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'package:travel_app/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/screens/add_travel/scan_qr_page.dart';

class FindSimilarPeopleScreen extends StatefulWidget {
  const FindSimilarPeopleScreen({super.key});

  @override
  _FindSimilarPeopleScreenState createState() =>
      _FindSimilarPeopleScreenState();
}

class _FindSimilarPeopleScreenState extends State<FindSimilarPeopleScreen> {
  List<AppUser> _similarUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppUserProvider>();
      final userStream = provider.userStream;
      // get the user
      userStream.listen((firebaseUser) async {
        if (firebaseUser != null) {
          final uid = firebaseUser.uid;
          final doc =
              await FirebaseFirestore.instance
                  .collection('appUsers')
                  .doc(uid)
                  .get();

          if (doc.exists) {
            final data = doc.data()!;
            final user = AppUser.fromJson(data);

            setState(() {
              _currentUser = user;
            });

            _fetchSimilarUsers();
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  "User profile not found. Please complete your profile first.";
            });
          }
        }
      });
    });
  }

  void _scanQRCodeToAddFriend() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => QRScanPage()));

    if (result != null && result is String) {
      try {
        // Fetch scanned user
        final doc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(result)
                .get();

        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User not found.", style: GoogleFonts.poppins()),
            ),
          );
          return;
        }

        final scannedUser = AppUser.fromJson(doc.data()!);

        // Prevent adding self
        if (scannedUser.uid == _currentUser!.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "You cannot add yourself.",
                style: GoogleFonts.poppins(),
              ),
            ),
          );
          return;
        }

        // Send friend request
        await _sendFriendRequest(scannedUser);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to add friend: $e",
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
  }

  // method to get users with similar interests/travel styles
  Future<void> _fetchSimilarUsers() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      // store the interests and travel styles of the user
      final List<String> currentUserInterests = _currentUser!.interests ?? [];
      final List<String> currentUserTravelStyles =
          _currentUser!.travelStyles ?? [];

      if (currentUserInterests.isEmpty && currentUserTravelStyles.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No Interests or Travel Styles.";
        });
        return;
      }

      final Map<String, AppUser> usersMap = {};

      if (currentUserInterests.isNotEmpty) {
        // get all the appUsers with the same interests
        final interestsSnapshot =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .where('interests', arrayContainsAny: currentUserInterests)
                .where('isPrivate', isEqualTo: false)
                .get();
        // store the user
        for (var doc in interestsSnapshot.docs) {
          final user = AppUser.fromJson(doc.data());
          if (user.uid != _currentUser!.uid) {
            usersMap[user.uid] = user;
          }
        }
      }

      // get all the appUsers with the same travel styles
      if (currentUserTravelStyles.isNotEmpty) {
        final travelStylesSnapshot =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .where(
                  'travelStyles',
                  arrayContainsAny: currentUserTravelStyles,
                )
                .where('isPrivate', isEqualTo: false)
                .get();
        // store user
        for (var doc in travelStylesSnapshot.docs) {
          final user = AppUser.fromJson(doc.data());
          if (user.uid != _currentUser!.uid) {
            usersMap[user.uid] = user;
          }
        }
      }

      setState(() {
        _similarUsers = usersMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error loading similar users: ${e.toString()}";
      });
    }
  }

  // Method to send a friend request
  Future<void> _sendFriendRequest(AppUser user) async {
    try {
      // Update current user's sentFriendRequests
      List<String> currentSentRequests = _currentUser!.sentFriendRequests ?? [];
      if (!currentSentRequests.contains(user.uid)) {
        currentSentRequests.add(user.uid);

        await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(_currentUser!.uid)
            .update({'sentFriendRequests': currentSentRequests});

        // Update the receiver's receivedFriendRequests
        List<String> receiverRequests = user.receivedFriendRequests ?? [];
        if (!receiverRequests.contains(_currentUser!.uid)) {
          receiverRequests.add(_currentUser!.uid);

          await FirebaseFirestore.instance
              .collection('appUsers')
              .doc(user.uid)
              .update({'receivedFriendRequests': receiverRequests});
        }

        // Update local state
        setState(() {
          _currentUser = _currentUser!.copyWith(
            sentFriendRequests: currentSentRequests,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Friend request sent to ${user.firstName}!",
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error sending friend request: ${e.toString()}",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  // Method to cancel a friend request
  Future<void> _cancelFriendRequest(AppUser user) async {
    try {
      // Update current user's sentFriendRequests
      List<String> currentSentRequests = _currentUser!.sentFriendRequests ?? [];
      if (currentSentRequests.contains(user.uid)) {
        currentSentRequests.remove(user.uid);

        await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(_currentUser!.uid)
            .update({'sentFriendRequests': currentSentRequests});

        // Update the receiver's receivedFriendRequests
        List<String> receiverRequests = user.receivedFriendRequests ?? [];
        if (receiverRequests.contains(_currentUser!.uid)) {
          receiverRequests.remove(_currentUser!.uid);

          await FirebaseFirestore.instance
              .collection('appUsers')
              .doc(user.uid)
              .update({'receivedFriendRequests': receiverRequests});
        }

        // Update local state
        setState(() {
          _currentUser = _currentUser!.copyWith(
            sentFriendRequests: currentSentRequests,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Friend request canceled",
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error canceling request: ${e.toString()}",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  // Method to accept a friend request
  Future<void> _acceptFriendRequest(AppUser user) async {
    try {
      // Get current data
      List<String> currentReceivedRequests =
          _currentUser!.receivedFriendRequests ?? [];
      List<String> currentFriends = _currentUser!.friendUIDs ?? [];

      // Check if request exists
      if (!currentReceivedRequests.contains(user.uid)) {
        return;
      }

      // Add to friends list for both users
      if (!currentFriends.contains(user.uid)) {
        currentFriends.add(user.uid);
      }

      // Remove from received requests
      currentReceivedRequests.remove(user.uid);

      // Update current user in Firestore
      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(_currentUser!.uid)
          .update({
            'friendUIDs': currentFriends,
            'receivedFriendRequests': currentReceivedRequests,
          });

      // Update other user
      List<String> otherUserSentRequests = user.sentFriendRequests ?? [];
      List<String> otherUserFriends = user.friendUIDs ?? [];

      if (otherUserSentRequests.contains(_currentUser!.uid)) {
        otherUserSentRequests.remove(_currentUser!.uid);
      }

      if (!otherUserFriends.contains(_currentUser!.uid)) {
        otherUserFriends.add(_currentUser!.uid);
      }

      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(user.uid)
          .update({
            'friendUIDs': otherUserFriends,
            'sentFriendRequests': otherUserSentRequests,
          });

      // Update local state
      setState(() {
        _currentUser = _currentUser!.copyWith(
          friendUIDs: currentFriends,
          receivedFriendRequests: currentReceivedRequests,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Friend request from ${user.firstName} accepted!",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error accepting request: ${e.toString()}",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  // Method to reject a friend request
  Future<void> _rejectFriendRequest(AppUser user) async {
    try {
      // Get current data
      List<String> currentReceivedRequests =
          _currentUser!.receivedFriendRequests ?? [];

      // Check if request exists
      if (!currentReceivedRequests.contains(user.uid)) {
        return;
      }

      // Remove from received requests
      currentReceivedRequests.remove(user.uid);

      // Update current user in Firestore
      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(_currentUser!.uid)
          .update({'receivedFriendRequests': currentReceivedRequests});

      // Update other user's sent requests
      List<String> otherUserSentRequests = user.sentFriendRequests ?? [];

      if (otherUserSentRequests.contains(_currentUser!.uid)) {
        otherUserSentRequests.remove(_currentUser!.uid);

        await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(user.uid)
            .update({'sentFriendRequests': otherUserSentRequests});
      }

      // Update local state
      setState(() {
        _currentUser = _currentUser!.copyWith(
          receivedFriendRequests: currentReceivedRequests,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Friend request rejected",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error rejecting request: ${e.toString()}",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  void _showUserDetails(AppUser user) {
    if (_currentUser == null) return;

    // Determine friend status
    final bool isFriend = _currentUser!.friendUIDs?.contains(user.uid) ?? false;
    final bool sentRequest =
        _currentUser!.sentFriendRequests?.contains(user.uid) ?? false;
    final bool receivedRequest =
        _currentUser!.receivedFriendRequests?.contains(user.uid) ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.8,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : AssetImage('assets/default_avatar.jpg')
                                        as ImageProvider,
                            child:
                                user.profileImageUrl == null
                                    ? Text(
                                      "${user.firstName[0]}${user.lastName[0]}",
                                      style: GoogleFonts.poppins(fontSize: 24),
                                    )
                                    : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${user.firstName} ${user.lastName}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "@${user.username}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (user.location != null)
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        user.location!,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      if (!user.isPrivate &&
                          user.interests != null &&
                          user.interests!.isNotEmpty) ...[
                        Text(
                          "Interests",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              user.interests!.map((interest) {
                                final isCommon =
                                    _currentUser!.interests?.contains(
                                      interest,
                                    ) ??
                                    false;
                                return Chip(
                                  label: Text(
                                    interest,
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor:
                                      isCommon
                                          ? Colors.green[100]
                                          : Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color:
                                        isCommon
                                            ? Colors.green[800]
                                            : Colors.black,
                                  ),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                      if (!user.isPrivate &&
                          user.travelStyles != null &&
                          user.travelStyles!.isNotEmpty) ...[
                        Text(
                          "Travel Styles",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              user.travelStyles!.map((style) {
                                final isCommon =
                                    _currentUser!.travelStyles?.contains(
                                      style,
                                    ) ??
                                    false;
                                return Chip(
                                  label: Text(
                                    style,
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor:
                                      isCommon
                                          ? Colors.green[100]
                                          : Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color:
                                        isCommon
                                            ? Colors.green[800]
                                            : Colors.black,
                                  ),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                      SizedBox(height: 24),
                      // Friend request/status buttons
                      _buildFriendActionButton(
                        context,
                        user,
                        isFriend,
                        sentRequest,
                        receivedRequest,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildFriendActionButton(
    BuildContext context,
    AppUser user,
    bool isFriend,
    bool sentRequest,
    bool receivedRequest,
  ) {
    if (isFriend) {
      // Already friends
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.check_circle),
          label: Text("Friends", style: GoogleFonts.poppins()),
          onPressed: null, // Disabled
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (sentRequest) {
      // Request sent
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.cancel_outlined, color: Colors.white),
          label: Text(
            "Cancel Request",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          onPressed: () {
            _cancelFriendRequest(user);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.orange,
          ),
        ),
      );
    } else if (receivedRequest) {
      // Request received
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.check, color: Colors.white),
              label: Text(
                "Accept",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onPressed: () {
                _acceptFriendRequest(user);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.green,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.close, color: Colors.white),
              label: Text(
                "Reject",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onPressed: () {
                _rejectFriendRequest(user);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      );
    } else {
      // Kpag di pa friends
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.person_add),
          label: Text("Send Friend Request", style: GoogleFonts.poppins()),
          onPressed: () {
            _sendFriendRequest(user);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[100],
        title: Text("Similar People", style: GoogleFonts.poppins()),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchSimilarUsers),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchSimilarUsers,
                              child: Text(
                                "Reload",
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : _similarUsers.isEmpty
                    ? Center(
                      child: Text(
                        "No similar users found. Try adding more interests or travel styles!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _similarUsers.length,
                      itemBuilder: (context, index) {
                        final user = _similarUsers[index];
                        return SimilarUserCard(
                          user: user,
                          currentUser: _currentUser!,
                          onTap: () => _showUserDetails(user),
                        );
                      },
                    ),
          ),
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: SizedBox(
          //     width: double.infinity,
          //     child: ElevatedButton.icon(
          //       onPressed: _scanQRCodeToAddFriend,
          //       icon: Icon(Icons.qr_code_scanner),
          //       label: Text("Scan to Add"),
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.green,
          //         foregroundColor: Colors.white,
          //         padding: EdgeInsets.symmetric(vertical: 16),
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 2),
      floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green.shade700,
            onPressed: _scanQRCodeToAddFriend,
            tooltip: "Scan QR to Add Friend",
            child: Icon(Icons.qr_code_scanner),
    ),
    );
  }
}

class SimilarUserCard extends StatelessWidget {
  final AppUser user;
  final AppUser currentUser;
  final VoidCallback onTap;

  const SimilarUserCard({
    super.key,
    required this.user,
    required this.currentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine friend status
    final bool isFriend = currentUser.friendUIDs?.contains(user.uid) ?? false;
    final bool sentRequest =
        currentUser.sentFriendRequests?.contains(user.uid) ?? false;
    final bool receivedRequest =
        currentUser.receivedFriendRequests?.contains(user.uid) ?? false;

    IconData relationshipIcon;
    Color iconColor;
    String relationshipText;

    if (isFriend) {
      relationshipIcon = Icons.check_circle;
      iconColor = Colors.green;
      relationshipText = "Friends";
    } else if (sentRequest) {
      relationshipIcon = Icons.schedule;
      iconColor = Colors.orange;
      relationshipText = "Request Sent";
    } else if (receivedRequest) {
      relationshipIcon = Icons.mail;
      iconColor = Colors.blue;
      relationshipText = "Respond to Request";
    } else {
      relationshipIcon = Icons.person_add;
      iconColor = Colors.blue;
      relationshipText = "Send Request";
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : AssetImage('assets/default_avatar.jpg')
                            as ImageProvider,
                child:
                    user.profileImageUrl == null
                        ? Text(
                          "${user.firstName[0].toUpperCase()}${user.lastName[0].toUpperCase()}",
                          style: GoogleFonts.poppins(fontSize: 20),
                        )
                        : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${user.firstName} ${user.lastName}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "@${user.username}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(relationshipIcon, size: 14, color: iconColor),
                        SizedBox(width: 4),
                        Text(
                          relationshipText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
