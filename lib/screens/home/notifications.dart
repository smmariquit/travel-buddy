import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/utils/notification_service.dart';
import 'package:travel_app/models/travel_notification_model.dart';
import 'package:travel_app/screens/add_travel/trip_details.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  AppUser? _currentUser;
  List<AppUser> _requestUsers = [];
  List<Map<String, dynamic>> _travelNotifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  TabController? _tabController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize notification service
    _notificationService.init().then((_) {
      _fetchCurrentUserAndRequests();
      _fetchTravelNotifications();
    });
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
      final currentUserDoc =
          await FirebaseFirestore.instance
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

      // Save FCM token to Firestore if user exists
      if (_currentUser != null && _notificationService.fcmToken != null) {
        await _notificationService.saveTokenToFirestore(_currentUser!.uid);
      }

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
        final userDoc =
            await FirebaseFirestore.instance
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final notifications = await _notificationService.getUserNotifications(
        userId,
      );

      setState(() {
        _travelNotifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading notifications: $e';
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
      final otherUserDoc =
          await FirebaseFirestore.instance
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

      // Send notification to the other user
      final otherUserFcmToken = otherUser.fcmToken;
      if (otherUserFcmToken != null && otherUserFcmToken.isNotEmpty) {
        await _notificationService.showTripReminderNotification(
          title: 'Friend Request Accepted',
          body: '${_currentUser!.firstName} accepted your friend request!',
        );
        // if (otherUserFcmToken != null && otherUserFcmToken.isNotEmpty) {
        //   await sendPushNotification(
        //     fcmToken: otherUserFcmToken,
        //     title: 'Friend Request Accepted',
        //     body: '${_currentUser!.firstName} accepted your friend request!',
        //   );
      }
      // }

      // Show local notification that the friend request was accepted
      await _notificationService.showFriendRequestAcceptedNotification(
        friendName: user.firstName,
        friendId: user.uid,
      );

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
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error accepting request: $e',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    }
  }

  // Delete friend request (similar to reject but with different UI)
  Future<void> _deleteFriendRequest(AppUser user) async {
    await _rejectFriendRequest(user);
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
      final otherUserDoc =
          await FirebaseFirestore.instance
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

      // Send rejection notification
      final otherUserFcmToken = otherUser.fcmToken;
      if (otherUserFcmToken != null && otherUserFcmToken.isNotEmpty) {
        await _notificationService.showTripReminderNotification(
          title: 'Friend Request Update',
          body:
              '${_currentUser!.firstName} has responded to your friend request',
        );
      }

      //   if (otherUserFcmToken != null && otherUserFcmToken.isNotEmpty) {
      //     await sendPushNotification(
      //       fcmToken: otherUserFcmToken,
      //       title: 'Friend Request Update',
      //       body: '${_currentUser!.firstName} has responded to your friend request',
      //     );
      // }

      // Show local notification that the friend request was rejected
      await _notificationService.showFriendRequestRejectedNotification(
        friendName: user.firstName,
        friendId: user.uid,
      );

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
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error rejecting request: $e',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
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
            'No friend requests received so far',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        )
        : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _requestUsers.length,
          itemBuilder: (context, index) {
            final user = _requestUsers[index];
            return Dismissible(
              key: Key(user.uid),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _deleteFriendRequest(user);
              },
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
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
                                    icon: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Accept',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () => _acceptFriendRequest(user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Reject',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () => _rejectFriendRequest(user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Delete button
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteFriendRequest(user),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  // Updated travel tab with delete buttons
  Widget _buildTravelTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
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
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll receive notifications based on your trip settings',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
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
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text('Delete All', style: GoogleFonts.poppins()),
                onPressed: _deleteAllTravelNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.check, color: Colors.white),
                label: Text('Mark All as Read'),
                onPressed: _markAllTravelNotificationsAsRead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        ..._travelNotifications.asMap().entries.map((entry) {
          final index = entry.key;
          final notification = entry.value;
          final isRead = notification['read'] ?? false;
          return Dismissible(
            key: Key(notification['id']),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              // Remove from local state first
              setState(() {
                _travelNotifications.removeAt(index);
              });

              // Then update Firestore
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                _notificationService
                    .markNotificationAsRead(
                      userId: userId,
                      notificationId: notification['id'],
                    )
                    .catchError((error) {
                      debugPrint('Error marking notification as read: $error');
                      // Optionally restore the notification if the Firestore update fails
                      setState(() {
                        _travelNotifications.insert(index, notification);
                      });
                    });
              }
            },
            child: Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Icon(
                  isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  notification['title'] ?? 'Notification',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isRead ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Text(
                  notification['body'] ?? '',
                  style: GoogleFonts.poppins(
                    color: isRead ? Colors.grey : Colors.black,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () async {
                    try {
                      // Fetch the full travel document from Firestore by tripId
                      final doc =
                          await FirebaseFirestore.instance
                              .collection('travel')
                              .doc(notification['id'])
                              .get();

                      if (!doc.exists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Trip details not found')),
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
                onTap: () async {
                  if (!isRead) {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      try {
                        await _notificationService.markNotificationAsRead(
                          userId: userId,
                          notificationId: notification['id'],
                        );
                        if (mounted) {
                          setState(() {
                            _travelNotifications[index]['read'] = true;
                          });
                        }
                      } catch (e) {
                        debugPrint('Error marking notification as read: $e');
                      }
                    }
                  }
                },
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _deleteAllTravelNotifications() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete All Notifications'),
            content: Text('Are you sure you want to delete all notifications?'),
          ),
    );
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('appUsers')
          .doc(userId)
          .collection('notifications')
          .get()
          .then((snapshot) {
            snapshot.docs.forEach((doc) => doc.reference.delete());
          });
      setState(() {
        _travelNotifications = [];
      });
    }
  }

  Future<void> _markAllTravelNotificationsAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(userId)
          .collection('notifications')
          .get()
          .then((snapshot) {
            snapshot.docs.forEach(
              (doc) => doc.reference.update({'read': true}),
            );
          });
      setState(() {
        _travelNotifications.forEach(
          (notification) => notification['read'] = true,
        );
      });
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMM d, yyyy').format(date);
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
                        _travelNotifications
                            .where((notification) => !notification['read'])
                            .length
                            .toString(),
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
        children: [_buildTravelTab(), _buildFriendRequestsTab()],
      ),
    );
  }
}

class NotificationHelper {
  static Future<void> fetchCurrentUserAndRequests(
    BuildContext context,
    Function(AppUser user) onUserFetched,
    Function(List<AppUser> requestUsers) onRequestsFetched,
    Function(String error) onError,
  ) async {
    try {
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('appUsers')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

      if (!currentUserDoc.exists) {
        onError('User profile not found');
        return;
      }

      final currentUser = AppUser.fromJson(currentUserDoc.data()!);
      onUserFetched(currentUser);

      final receivedRequests = currentUser.receivedFriendRequests ?? [];
      if (receivedRequests.isEmpty) {
        onRequestsFetched([]);
        return;
      }

      final users = <AppUser>[];
      for (var uid in receivedRequests) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(uid)
                .get();
        if (userDoc.exists) {
          users.add(AppUser.fromJson(userDoc.data()!));
        }
      }

      onRequestsFetched(users);
    } catch (e) {
      onError('Error loading friend requests: $e');
    }
  }

  static Future<void> fetchTravelNotifications(
    BuildContext context,
    Function(List<TravelNotification>) onDone,
    Function(String error) onError,
    NotificationService notificationService,
  ) async {
    try {
      debugPrint('=== TRAVEL NOTIFICATIONS CHECK START ===');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user ID found, skipping notifications');
        return;
      }
      debugPrint('Processing notifications for user: $userId');

      final now = DateTime.now();
      final notifications = <TravelNotification>[];

      debugPrint('Fetching user document for SMS...');
      final userDoc =
          await FirebaseFirestore.instance
              .collection('appUsers')
              .doc(userId)
              .get();

      final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
      debugPrint('Phone number from document: $phoneNumber');

      final ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('travel')
              .where('uid', isEqualTo: userId)
              .get();

      final sharedSnapshot =
          await FirebaseFirestore.instance
              .collection('travel')
              .where('sharedWith', arrayContains: userId)
              .get();

      final allDocs = [...ownerSnapshot.docs, ...sharedSnapshot.docs];
      debugPrint('Found ${allDocs.length} trips to check');

      for (var doc in allDocs) {
        final data = doc.data();
        final startDateTimestamp = data['startDate'] as Timestamp?;
        if (startDateTimestamp == null) {
          debugPrint('Trip ${doc.id} has no start date, skipping');
          continue;
        }

        final startDate = startDateTimestamp.toDate();
        final daysUntilTrip = startDate.difference(now).inDays;
        debugPrint('Trip ${data['name']}: $daysUntilTrip days until start');

        // Get user's notification preference (default to 5 if not set)
        final notificationDays = data['notificationDays'] ?? 5;

        if (daysUntilTrip <= 5 && daysUntilTrip >= 0) {
          final tripName = data['name'] ?? 'Unnamed Trip';
          final message =
              daysUntilTrip == 0
                  ? 'Your trip "$tripName" starts today!'
                  : daysUntilTrip == 1
                  ? 'Your trip "$tripName" starts tomorrow!'
                  : 'Your trip "$tripName" starts in $daysUntilTrip day(s)!';

          final notification = TravelNotification(
            tripId: doc.id,
            tripName: tripName,
            destination: data['destination'] ?? 'Unknown',
            startDate: startDate,
            daysUntil: daysUntilTrip,
            notificationDays: notificationDays,
          );
          notifications.add(notification);

          debugPrint('Sending notifications for trip: $tripName');

          // Send local notification
          await notificationService.showTripReminderNotification(
            title: 'Upcoming Trip Reminder',
            body: message,
            payload: doc.id,
          );
          debugPrint('Local notification sent');

          // Send SMS if phone number exists
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            debugPrint('Attempting to send SMS to: $phoneNumber');
            try {
              await notificationService.sendSMS(
                phoneNumber: phoneNumber,
                message:
                    "Hey, Buddy! Here's a travel alert for you: \n$message",
              );
              debugPrint('SMS sent successfully');
            } catch (e) {
              debugPrint('Failed to send SMS: $e');
            }
          } else {
            debugPrint('No phone number available for SMS');
          }
        } else {
          debugPrint('Trip ${data['name']} is not within notification period');
        }
      }

      debugPrint('=== TRAVEL NOTIFICATIONS CHECK END ===');
      onDone(notifications);
    } catch (e) {
      debugPrint('Error in fetchTravelNotifications: $e');
      onError('Error fetching travel notifications: $e');
    }
  }
}
