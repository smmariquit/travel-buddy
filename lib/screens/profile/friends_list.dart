import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/screens/profile/view_friend_profile_screen.dart';

class FriendsListScreen extends StatefulWidget {
  final List<String> friendUIDs;
  final String currentUserID;

  const FriendsListScreen({
    Key? key,
    required this.friendUIDs,
    required this.currentUserID,
  }) : super(key: key);

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  bool _isLoading = true;
  List<AppUser> _friends = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshots = await Future.wait(
        widget.friendUIDs.map((uid) {
          return FirebaseFirestore.instance
              .collection('appUsers')
              .doc(uid)
              .get();
        }),
      );

      final loadedFriends =
          snapshots
              .where((doc) => doc.exists)
              .map((doc) => AppUser.fromJson(doc.data()!))
              .toList();

      loadedFriends.sort((a, b) => a.firstName.compareTo(b.firstName));

      setState(() {
        _friends = loadedFriends;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friends: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load friends', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFriend(String friendUID) async {
    try {
      final confirm =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Remove Friend', style: GoogleFonts.poppins()),
                  content: Text(
                    'Are you sure you want to remove this friend?',
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel', style: GoogleFonts.poppins()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Remove',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirm) return;

      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(widget.currentUserID)
          .update({
            'friendUIDs': FieldValue.arrayRemove([friendUID]),
          });

      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(friendUID)
          .update({
            'friendUIDs': FieldValue.arrayRemove([widget.currentUserID]),
          });

      setState(() {
        _friends.removeWhere((friend) => friend.uid == friendUID);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend removed', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    } catch (e) {
      print('Error removing friend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove friend',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    }
  }

  List<AppUser> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;

    return _friends.where((friend) {
      final fullName = '${friend.firstName} ${friend.lastName}'.toLowerCase();
      final username = (friend.username ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return fullName.contains(query) || username.contains(query);
    }).toList();
  }

  Widget _buildFriendTile(AppUser friend) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              friend.profileImageUrl != null
                  ? NetworkImage(friend.profileImageUrl!)
                  : null,
          child:
              friend.profileImageUrl == null
                  ? Icon(Icons.person, color: Colors.grey.shade600)
                  : null,
        ),
        title: Text(
          '${friend.firstName} ${friend.lastName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle:
            friend.username != null
                ? Text('@${friend.username}', style: GoogleFonts.poppins())
                : null,
        trailing: IconButton(
          icon: Icon(Icons.person_remove, color: Colors.red),
          onPressed: () => _removeFriend(friend.uid),
        ),
        onTap: () {
          showFriendProfileBottomSheet(context, friend.uid);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friends',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends',
                hintStyle: GoogleFonts.poppins(),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              style: GoogleFonts.poppins(),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _friends.isEmpty
                    ? Center(
                      child: Text(
                        'No friends yet',
                        style: GoogleFonts.poppins(),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadFriends,
                      child:
                          _filteredFriends.isEmpty
                              ? ListView(
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        'No matching friends found',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                itemCount: _filteredFriends.length,
                                itemBuilder: (context, index) {
                                  return _buildFriendTile(
                                    _filteredFriends[index],
                                  );
                                },
                              ),
                    ),
          ),
        ],
      ),
    );
  }
}
