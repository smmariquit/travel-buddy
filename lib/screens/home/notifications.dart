import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/utils/notification_service.dart'; 
import 'package:travel_app/models/travel_notification_model.dart';
import 'package:travel_app/screens/add_travel/trip_details.dart';
import 'package:travel_app/models/travel_plan_model.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  AppUser? _currentUser;
  List<AppUser> _requestUsers = [];
  List<TravelNotification> _travelNotifications = []; // New list to store travel notifications
  bool _isLoading = true;
  String? _errorMessage;
  TabController? _tabController;
  final NotificationService _notificationService = NotificationService(); // Instance of our service

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize notification service
    _notificationService.initialize().then((_) {
      // Schedule daily check for upcoming travel
      _notificationService.scheduleUpcomingTripChecks();
    });
    _fetchCurrentUserAndRequests();
    _fetchTravelNotifications(); // New method to fetch travel notifications
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

  // Fetch travel notifications 
  Future<void> _fetchTravelNotifications() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final notifications = <TravelNotification>[];

    // Query travels where user is owner
    final ownerSnapshot = await FirebaseFirestore.instance
        .collection('travel')
        .where('uid', isEqualTo: userId)
        .get();

    // Query travels where user is in sharedWith
    final sharedSnapshot = await FirebaseFirestore.instance
        .collection('travel')
        .where('sharedWith', arrayContains: userId)
        .get();

    // Combine both query results
    final allDocs = [...ownerSnapshot.docs, ...sharedSnapshot.docs];

    for (var doc in allDocs) {
      final data = doc.data();
      final startDateTimestamp = data['startDate'] as Timestamp?;
      if (startDateTimestamp == null) continue;

      final startDate = startDateTimestamp.toDate();
      final daysUntilTrip = startDate.difference(now).inDays;

      // If trip starts within next 5 days, add notification and send push notification
      if (daysUntilTrip <= 5 && daysUntilTrip >= 0) {
        notifications.add(
          TravelNotification(
            tripId: doc.id,
            tripName: data['name'] ?? 'Unnamed Trip',
            destination: data['destination'] ?? 'Unknown',
            startDate: startDate,
            daysUntil: daysUntilTrip,
          ),
        );

        // Send push notification to current user for the trip starting soon
        // Get current user's FCM token
        final currentUserDoc = await FirebaseFirestore.instance.collection('appUsers').doc(userId).get();
        final currentUser = AppUser.fromJson(currentUserDoc.data()!);
        if (currentUser.fcmToken != null && currentUser.fcmToken!.isNotEmpty) {
          await sendPushNotification(
            fcmToken: currentUser.fcmToken!,
            title: 'Upcoming Trip Reminder',
            body: 'Your trip "${data['name'] ?? 'Unnamed Trip'}" starts in $daysUntilTrip day(s)!',
          );
        }
      }
    }

    setState(() {
      _travelNotifications = notifications;
    });
  } catch (e) {
    print('Error fetching travel notifications: $e');
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

      // Send push notification to the other user
      if (otherUser.fcmToken != null && otherUser.fcmToken!.isNotEmpty) {
        await sendPushNotification(
          fcmToken: otherUser.fcmToken!,
          title: 'Friend Request Accepted',
          body: '${_currentUser!.firstName} accepted your friend request!',
        );
      }

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

      // Send push notification to the other user
      if (otherUser.fcmToken != null && otherUser.fcmToken!.isNotEmpty) {
        await sendPushNotification(
          fcmToken: otherUser.fcmToken!,
          title: 'Friend Request Rejected',
          body: '${_currentUser!.firstName} rejected your friend request.',
        );
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

  // Updated travel tab with actual notifications
  Widget _buildTravelTab() {
    if (_travelNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.airplanemode_inactive,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No travel notifications yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll receive notifications 5 days before your travel',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Refresh', style: GoogleFonts.poppins()),
              onPressed: _fetchTravelNotifications,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _travelNotifications.length,
      itemBuilder: (context, index) {
        final notification = _travelNotifications[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.flight_takeoff,
                color: Colors.blue[800],
              ),
            ),
            title: Text(
              notification.tripName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'Destination: ${notification.destination}',
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 4),
                Text(
                  notification.daysUntil == 0
                      ? 'Your trip starts today!'
                      : 'Starting in ${notification.daysUntil} day${notification.daysUntil > 1 ? "s" : ""}',
                  style: GoogleFonts.poppins(
                    color: notification.daysUntil <= 1 ? Colors.red : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Date: ${_formatDate(notification.startDate)}',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () async {
                try {
                  // Fetch the full travel document from Firestore by tripId
                  final doc = await FirebaseFirestore.instance
                      .collection('travel')
                      .doc(notification.tripId)
                      .get();

                  if (!doc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Trip details not found'),
                      ),
                    );
                    return;
                  }

                  // Parse the document into a Travel instance
                  final travelData = doc.data()!;
                  final travel = Travel.fromJson(travelData, doc.id);

                  // Navigate to TripDetails page with the Travel instance
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TripDetails(travel: travel),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading trip details: $e'),
                    ),
                  );
                }
              },
            ),

          ),
        );
      },
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Update tab bar to show notification count badges
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: Text('Notifications', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _fetchCurrentUserAndRequests();
              _fetchTravelNotifications();
            },
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
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Travel'),
                  if (_travelNotifications.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _travelNotifications.length.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Friend Requests'),
                  if (_requestUsers.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _requestUsers.length.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
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

// // Model class for travel notifications
// class TravelNotification {
//   final String tripId;
//   final String tripName;
//   final String destination;
//   final DateTime startDate;
//   final int daysUntil;

//   TravelNotification({
//     required this.tripId,
//     required this.tripName,
//     required this.destination,
//     required this.startDate,
//     required this.daysUntil,
//   });
// }