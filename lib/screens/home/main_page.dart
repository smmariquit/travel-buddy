// Flutter & Material
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/utils/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // For ImageFilter.blur

// Firebase & External Services
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/models/travel_notification_model.dart';

// App-specific
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/home/notifications.dart';
import 'package:travel_app/utils/responsive_layout.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'package:travel_app/widgets/travel_plan_card.dart';
import '../auth/signin_page.dart';
import '../add_travel/add_travel_plan_page.dart';
import 'package:travel_app/utils/constants.dart';

/// Holds constants for the [MainPage].
class MainPageConstants {
  static const double rowSpacing = 20.0;
  static const double sectionSpacing = 16.0;
  static const double cardSpacing = 4.0;
  static const double bottomSpacing = 32.0;
  static const double greetingFontSize = 18.0;
  static const double mainTitleFontSize = 28.0;
  static const double headerFontSize = 14.0;
  static const Color mainTitleColor = Color(0xFF1B1E28);
  static const Color viewAllColor = Color(0xFFFF7029);
  static const FontWeight boldWeight = FontWeight.w600;
  static const ShapeBorder fabShape = CircleBorder();
  static const Color fabColor = Colors.green;
  static const int numTravelPlans = 5;
  static const Color paddingColor = Color(0xFFE0E0E0); // Light gray for padding
  static const double greetingBorderRadius =
      12.0; // Border radius for GreetingRow
  static const double greetingBlurSigma = 5.0; // Blur strength for GreetingRow
  static const Color greetingBackgroundColor =
      Colors.white; // Base color for blur
  static const double greetingBackgroundOpacity =
      0.7; // Opacity for frosted effect
}

/// The main page of the app, displaying travel plans and navigation options.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

/// Create the state for the main page
class _MainPageState extends State<MainPage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Travel> _travelPlans = [];
  bool _isLoading = true;
  List<AppUser> _requestUsers = [];
  List<TravelNotification> _travelNotifications = [];
  String? _errorMessage;
  late final TravelTrackerProvider _travelProvider;
  late final AppUserProvider _userProvider;
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _travelProvider = context.read<TravelTrackerProvider>();
    _userProvider = context.read<AppUserProvider>();
    _initializeNotificationsOnce();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted || _isInitialized) return;
    _isInitialized = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _travelProvider.setUser(user.uid);
      _userProvider.fetchUserForCurrentUser();
      try {
        final plans = await _travelProvider.getTravelPlans();
        if (mounted) {
          setState(() {
            _travelPlans = plans;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeNotificationsOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final hasInitialized =
        prefs.getBool('hasInitializedNotifications') ?? false;

    await _notificationService.init();

    NotificationHelper.fetchTravelNotifications(
      context,
      (notifications) => setState(() => _travelNotifications = notifications),
      (error) => debugPrint(error),
      _notificationService,
    );

    if (!hasInitialized) {
      await prefs.setBool('hasInitializedNotifications', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Travel? newTravelPlan = args is Travel ? args : null;
    if (newTravelPlan != null &&
        !_travelPlans.any((plan) => plan.id == newTravelPlan.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _travelPlans.add(newTravelPlan));
      });
    }

    return StreamBuilder<User?>(
      stream: _userProvider.userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong.")),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (!snapshot.hasData) {
          return const SignInPage();
        }

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFAED581), Colors.white],
                      stops: [0.0, 0.3],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ResponsiveLayout(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  color: MainPageConstants.paddingColor,
                                  child: const SizedBox(
                                    height: MainPageConstants.rowSpacing,
                                  ),
                                ),
                                FutureBuilder<int>(
                                  future: FirebaseFirestore.instance
                                      .collection('appUsers')
                                      .doc(
                                        FirebaseAuth.instance.currentUser!.uid,
                                      )
                                      .collection('notifications')
                                      .where('read', isEqualTo: false)
                                      .get()
                                      .then((value) => value.docs.length),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data ?? 0;
                                    return _GreetingRow(
                                      userProvider: _userProvider,
                                      notificationCount: count,
                                    );
                                  },
                                ),
                                Container(
                                  color: MainPageConstants.paddingColor,
                                  child: const SizedBox(
                                    height: MainPageConstants.rowSpacing,
                                  ),
                                ),
                                _MainTitle(userProvider: _userProvider),
                                Container(
                                  color: MainPageConstants.paddingColor,
                                  child: const SizedBox(
                                    height: MainPageConstants.sectionSpacing,
                                  ),
                                ),
                                _PlansHeader(),
                                Container(
                                  color: MainPageConstants.paddingColor,
                                  child: const SizedBox(
                                    height: MainPageConstants.rowSpacing,
                                  ),
                                ),
                                _TravelPlansList(
                                  isLoading: _isLoading,
                                  travelPlans: _travelPlans,
                                ),
                                Container(
                                  color: MainPageConstants.paddingColor,
                                  child: const SizedBox(
                                    height: MainPageConstants.rowSpacing,
                                  ),
                                ),
                                _SharedPlansHeader(),
                                Container(
                                  color: MainPageConstants.paddingColor,
                                  child: const SizedBox(
                                    height: MainPageConstants.rowSpacing,
                                  ),
                                ),
                                _SharedTravelPlansList(
                                  travelProvider: _travelProvider,
                                ),
                                Container(
                                  color: MainPageConstants.paddingColor,
                                  child: const SizedBox(
                                    height: MainPageConstants.bottomSpacing,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(selectedIndex: 0),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: primaryColor,
            shape: MainPageConstants.fabShape,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTravelPlanPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _GreetingRow extends StatelessWidget {
  final AppUserProvider userProvider;
  final int notificationCount;

  const _GreetingRow({
    required this.userProvider,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          MainPageConstants.greetingBorderRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          MainPageConstants.greetingBorderRadius,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: MainPageConstants.greetingBlurSigma,
            sigmaY: MainPageConstants.greetingBlurSigma,
          ),
          child: Container(
            color: MainPageConstants.greetingBackgroundColor.withOpacity(
              MainPageConstants.greetingBackgroundOpacity,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 5.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 8.0,
                    ), // Move "Travel Buddy" to the right
                    child: Text(
                      'Travel Buddy',
                      style: TextStyle(
                        fontSize: MainPageConstants.greetingFontSize,
                        fontWeight: MainPageConstants.boldWeight,
                        color: MainPageConstants.mainTitleColor,
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(),
                            ),
                          );
                        },
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notificationCount > 99
                                  ? '99+'
                                  : notificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainTitle extends StatelessWidget {
  final AppUserProvider userProvider;
  const _MainTitle({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final name = userProvider.firstName ?? '';
    return RichText(
      text: TextSpan(
        text: 'Up for a journey, ',
        style: const TextStyle(
          color: MainPageConstants.mainTitleColor,
          fontSize: MainPageConstants.mainTitleFontSize,
          fontWeight: MainPageConstants.boldWeight,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: name,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: '?'),
        ],
      ),
    );
  }
}

class _PlansHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Your Plans',
          style: TextStyle(
            fontSize: MainPageConstants.headerFontSize,
            fontWeight: MainPageConstants.boldWeight,
          ),
        ),
      ],
    );
  }
}

class _TravelPlansList extends StatelessWidget {
  final bool isLoading;
  final List<Travel> travelPlans;
  const _TravelPlansList({required this.isLoading, required this.travelPlans});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (travelPlans.isEmpty) {
      return const Text('No travel plans available.');
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Row(
          children:
              travelPlans
                  .map(
                    (travel) => Row(
                      children: [
                        TravelPlanCard(
                          travelId: travel.id,
                          uid: travel.uid,
                          name: travel.name,
                          startDate: travel.startDate ?? DateTime.now(),
                          endDate: travel.endDate,
                          image:
                              travel.imageUrl?.isNotEmpty == true
                                  ? travel.imageUrl!
                                  : 'assets/sample_image.jpg',
                          location: travel.location,
                          createdOn: travel.createdOn,
                        ),
                        const SizedBox(width: MainPageConstants.cardSpacing),
                      ],
                    ),
                  )
                  .take(MainPageConstants.numTravelPlans)
                  .toList(),
        ),
      );
    }
  }
}

class _SharedPlansHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Shared With You',
      style: TextStyle(
        fontSize: MainPageConstants.headerFontSize,
        fontWeight: MainPageConstants.boldWeight,
      ),
    );
  }
}

class _SharedTravelPlansList extends StatelessWidget {
  final TravelTrackerProvider travelProvider;
  const _SharedTravelPlansList({required this.travelProvider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Travel>>(
      stream: travelProvider.getSharedTravelPlans(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No shared travel plans.');
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children:
                  snapshot.data!
                      .map(
                        (travel) => Row(
                          children: [
                            TravelPlanCard(
                              travelId: travel.id,
                              uid: travel.uid,
                              name: travel.name,
                              startDate: travel.startDate ?? DateTime.now(),
                              endDate: travel.endDate ?? DateTime.now(),
                              image:
                                  travel.imageUrl?.isNotEmpty == true
                                      ? travel.imageUrl!
                                      : 'assets/sample_image.jpg',
                              location: travel.location,
                              createdOn: travel.createdOn,
                            ),
                            const SizedBox(
                              width: MainPageConstants.cardSpacing,
                            ),
                          ],
                        ),
                      )
                      .take(MainPageConstants.numTravelPlans)
                      .toList(),
            ),
          );
        }
      },
    );
  }
}
