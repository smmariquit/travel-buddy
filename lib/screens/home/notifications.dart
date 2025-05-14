import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/models/user_model.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  AppUser? _currentUser;
  List<AppUser> _requestUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCurrentUserAndRequests();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserAndRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (!currentUserDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User profile not found';
        });
        return;
      }

      final currentUser = AppUser.fromJson(currentUserDoc.data()!);
      setState(() {
        _currentUser = currentUser;
      });

      // Get friend requests
      final receivedRequests = currentUser.receivedFriendRequests ?? [];
      if (receivedRequests.isEmpty) {
        setState(() {
          _requestUsers = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch users who sent friend requests
      final users = <AppUser>[];
      for (var uid in receivedRequests) {
        final userDoc = await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(uid)
            .get();
        if (userDoc.exists) {
          users.add(AppUser.fromJson(userDoc.data()!));
        }
      }

      setState(() {
        _requestUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading friend requests: $e';
      });
    }
  }

  Future<void> _acceptFriendRequest(AppUser user) async {
    try {
      if (_currentUser == null) return;

      // Update current user's data
      List<String> currentReceivedRequests =
          _currentUser!.receivedFriendRequests ?? [];
      List<String> currentFriends = _currentUser!.friendUIDs ?? [];

      if (!currentReceivedRequests.contains(user.uid)) return;

      currentFriends.add(user.uid);
      currentReceivedRequests.remove(user.uid);

      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(_currentUser!.uid)
          .update({
        'friendUIDs': currentFriends,
        'receivedFriendRequests': currentReceivedRequests,
      });

      // Update other user's data
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(user.uid)
          .get();
      final otherUser = AppUser.fromJson(otherUserDoc.data()!);
      List<String> otherUserSentRequests = otherUser.sentFriendRequests ?? [];
      List<String> otherUserFriends = otherUser.friendUIDs ?? [];

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
        _requestUsers.removeWhere((u) => u.uid == user.uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request from ${user.firstName} accepted!',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error accepting request: $e',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(AppUser user) async {
    try {
      if (_currentUser == null) return;

      // Update current user's data
      List<String> currentReceivedRequests =
          _currentUser!.receivedFriendRequests ?? [];

      if (!currentReceivedRequests.contains(user.uid)) return;

      currentReceivedRequests.remove(user.uid);

      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(_currentUser!.uid)
          .update({'receivedFriendRequests': currentReceivedRequests});

      // Update other user's sent requests
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(user.uid)
          .get();
      final otherUser = AppUser.fromJson(otherUserDoc.data()!);
      List<String> otherUserSentRequests = otherUser.sentFriendRequests ?? [];

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
        _requestUsers.removeWhere((u) => u.uid == user.uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request rejected',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error rejecting request: $e',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  Widget _buildFriendRequestsTab() {
    return _isLoading
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
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchCurrentUserAndRequests,
                        child: Text('Reload', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ),
              )
            : _requestUsers.isEmpty
                ? Center(
                    child: Text(
                      'No pending friend requests',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _requestUsers.length,
                    itemBuilder: (context, index) {
                      final user = _requestUsers[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : AssetImage('assets/default_avatar.jpg')
                                        as ImageProvider,
                                child: user.profileImageUrl == null
                                    ? Text(
                                        '${user.firstName[0]}${user.lastName[0]}',
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
                                      '${user.firstName} ${user.lastName}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '@${user.username}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: Icon(Icons.check, color: Colors.white),
                                            label: Text(
                                              'Accept',
                                              style: GoogleFonts.poppins(color: Colors.white),
                                            ),
                                            onPressed: () => _acceptFriendRequest(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: Icon(Icons.close, color: Colors.white),
                                            label: Text(
                                              'Reject',
                                              style: GoogleFonts.poppins(color: Colors.white),
                                            ),
                                            onPressed: () => _rejectFriendRequest(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                            ),
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
                      );
                    },
                  );
  }

  Widget _buildTravelTab() {
    return Center(
      child: Text(
        'No travel notifications yet',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: Colors.grey[600]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: Text('Notifications', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchCurrentUserAndRequests,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(),
          indicatorColor: Colors.green,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[600],
          tabs: [
            Tab(text: 'Travel'),
            Tab(text: 'Friend Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTravelTab(),
          _buildFriendRequestsTab(),
        ],
      ),
    );
  }
}