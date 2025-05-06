import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/providers/user_provider.dart';

class FindSimilarPeopleScreen extends StatefulWidget {
  const FindSimilarPeopleScreen({super.key});

  @override
  _FindSimilarPeopleScreenState createState() => _FindSimilarPeopleScreenState();
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
          final doc = await FirebaseFirestore.instance.collection('appUsers').doc(uid).get();

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
              _errorMessage = "User profile not found. Please complete your profile first.";
            });
          }
        }
      });
    });
  }
// method pangkuha ng user/s na may similar interests/travel styles
Future<void> _fetchSimilarUsers() async {
  if (_currentUser == null) return;

  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    // store the interests and travel styles of the user
    final List<String> currentUserInterests = _currentUser!.interests ?? [];
    final List<String> currentUserTravelStyles = _currentUser!.travelStyles ?? [];

    if (currentUserInterests.isEmpty && currentUserTravelStyles.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No Interests or Travel Styles.";
      });
      return;
    }

    final Map<String, AppUser> usersMap = {};

    if (currentUserInterests.isNotEmpty) {
      // get all the appUsers with the same intersets
      final interestsSnapshot = await FirebaseFirestore.instance
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
      final travelStylesSnapshot = await FirebaseFirestore.instance
          .collection('appUsers')
          .where('travelStyles', arrayContainsAny: currentUserTravelStyles)
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


  Future<void> _addFriend(AppUser user) async {
    try {
      List<String> currentFriends = _currentUser!.friendUIDs ?? [];
      currentFriends.add(user.uid);

      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(_currentUser!.uid)
          .update({'friendUIDs': currentFriends});

      setState(() {
        _currentUser = _currentUser!.copyWith(friendUIDs: currentFriends);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${user.firstName} added as friend!", style: GoogleFonts.poppins())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding friend: ${e.toString()}", style: GoogleFonts.poppins())),
      );
    }
  }

  void _showUserDetails(AppUser user) {
    if (_currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : AssetImage('default_avatar.jpg') as ImageProvider,
                        child: user.profileImageUrl == null
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
                                  Text(user.location!, style: GoogleFonts.poppins()),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  if (!user.isPrivate && user.interests != null && user.interests!.isNotEmpty) ...[
                    Text("Interests", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests!.map((interest) {
                        final isCommon = _currentUser!.interests?.contains(interest) ?? false;
                        return Chip(
                          label: Text(interest, style: GoogleFonts.poppins()),
                          backgroundColor: isCommon ? Colors.green[100] : Colors.grey[200],
                          labelStyle: TextStyle(color: isCommon ? Colors.green[800] : Colors.black),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],
                  if (!user.isPrivate && user.travelStyles != null && user.travelStyles!.isNotEmpty) ...[
                    Text("Travel Styles", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.travelStyles!.map((style) {
                        final isCommon = _currentUser!.travelStyles?.contains(style) ?? false;
                        return Chip(
                          label: Text(style, style: GoogleFonts.poppins()),
                          backgroundColor: isCommon ? Colors.green[100] : Colors.grey[200],
                          labelStyle: TextStyle(color: isCommon ? Colors.green[800] : Colors.black),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon:Icon(Icons.person_add),
                      label: Text(
                        _currentUser!.friendUIDs?.contains(user.uid) ?? false
                            ? "Friends"
                            : "Add Friend",
                        style: GoogleFonts.poppins(),
                      ),
                      onPressed: _currentUser!.friendUIDs?.contains(user.uid) ?? false
                          ? null
                          : () {
                              _addFriend(user);
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: Text("Similar People", style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchSimilarUsers,
          ),
        ],
      ),
      body: _isLoading
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
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchSimilarUsers,
                          child: Text("Reload", style: GoogleFonts.poppins()),
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
                          onAddFriend: () => _addFriend(user),
                        );
                      },
                    ),
    );
  }
}

class SimilarUserCard extends StatelessWidget {
  final AppUser user;
  final AppUser currentUser;
  final VoidCallback onTap;
  final VoidCallback onAddFriend;

  const SimilarUserCard({
    super.key,
    required this.user,
    required this.currentUser,
    required this.onTap,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFriend = currentUser.friendUIDs?.contains(user.uid) ?? false;

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
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : AssetImage('default_avatar.jpg') as ImageProvider,
                child: user.profileImageUrl == null
                    ? Text(
                        "${user.firstName[0].toUpperCase()}${user.lastName[0].toUpperCase()}",
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
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "@${user.username}",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isFriend ? Icons.check_circle : Icons.person_add,
                  color: isFriend ? Colors.green : Colors.blue,
                ),
                onPressed: onAddFriend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

