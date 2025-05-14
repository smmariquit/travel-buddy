/// main_page.dart
///
/// The main landing page for the TravelBuddy app. This screen displays the user's travel plans,
/// shared travel plans, and provides navigation to other parts of the app. It also handles
/// authentication state and updates the UI accordingly.
///
/// # Features
/// - Displays greeting and user info
/// - Shows user's travel plans and shared plans
/// - Handles authentication state and redirects to sign-in if needed
/// - Provides navigation via a bottom navigation bar and a floating action button
///
/// # See Also
/// - [TravelPlanCard]
/// - [BottomNavBar]
/// - [AddTravelPlanPage]
/// - [SignInPage]

// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:firebase_auth/firebase_auth.dart';

// State Management
import 'package:provider/provider.dart';

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
}

/// The main page of the app, displaying travel plans and navigation options.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

/// Create the state for the main page
class _MainPageState extends State<MainPage> {
  List<Travel> _travelPlans = [];
  bool _isLoading = true;
  late final TravelTrackerProvider _travelProvider;
  late final AppUserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _travelProvider = context.read<TravelTrackerProvider>();
    _userProvider = context.read<AppUserProvider>();

    // Initialize providers after the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _travelProvider.setUser(user.uid);
        _userProvider.fetchUserForCurrentUser();

        // Fetch travel plans
        try {
          final plans = await _travelProvider.getTravelPlans();
          if (mounted) {
            setState(() {
              _travelPlans = plans;
              _isLoading = false;
            });
          }
        } catch (e) {
          print('Error fetching travel plans: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  /// Builds the main page UI, including travel plans, shared plans, and navigation.
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)
            ?.settings
            .arguments; // Gets any arguments passed to the page via navigation. Cast to Travel?. It relies on the argument being the correct type, else, the line below will return null.
    final Travel? newTravelPlan = args is Travel ? args : null;
    if (newTravelPlan != null) {
      // If merong new travel plan, add it to the list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // addPostFrameCallback is used to ensure that the state is updated after the widget is built. This makes sure that you don't cause recursion.
        setState(() {
          _travelPlans.add(newTravelPlan);
        });
      });
    }

    // Get the user stream
    final userStream = _userProvider.userStream;

    //
    return StreamBuilder<User?>(
      stream: userStream,
      // initialData: data - this returns the data if the stream is not yet ready.
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

        final user = snapshot.data!;
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ResponsiveLayout(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: MainPageConstants.rowSpacing,
                            ),

                            _GreetingRow(userProvider: _userProvider),

                            const SizedBox(
                              height: MainPageConstants.rowSpacing,
                            ),

                            _MainTitle(userProvider: _userProvider),

                            const SizedBox(
                              height: MainPageConstants.sectionSpacing,
                            ),

                            _PlansHeader(),

                            const SizedBox(
                              height: MainPageConstants.rowSpacing,
                            ),

                            _TravelPlansList(
                              isLoading: _isLoading,
                              travelPlans: _travelPlans,
                            ),

                            const SizedBox(
                              height: MainPageConstants.rowSpacing,
                            ),

                            _SharedPlansHeader(),

                            const SizedBox(
                              height: MainPageConstants.rowSpacing,
                            ),

                            _SharedTravelPlansList(
                              travelProvider: _travelProvider,
                            ),

                            const SizedBox(
                              height: MainPageConstants.bottomSpacing,
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
          bottomNavigationBar: BottomNavBar(selectedIndex: 0),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: MainPageConstants.fabColor,
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
}

/// Displays the greeting row with the user's name and notification icon.
class _GreetingRow extends StatelessWidget {
  final AppUserProvider userProvider;
  const _GreetingRow({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.person, size: 28),
            const SizedBox(width: 8),
            Text(
              userProvider.firstName ?? 'Traveler',
              style: const TextStyle(
                fontWeight: MainPageConstants.boldWeight,
                fontSize: MainPageConstants.greetingFontSize,
              ),
            ),
          ],
        ),
        IconButton(icon: const Icon(Icons.notifications),
        onPressed: () {
          Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
        }),
      ],
    );
  }
}

/// Displays the main greeting/title.
class _MainTitle extends StatelessWidget {
  final AppUserProvider userProvider;
  const _MainTitle({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Up for a journey, ${userProvider.firstName ?? ''}?',
      style: const TextStyle(
        color: MainPageConstants.mainTitleColor,
        fontSize: MainPageConstants.mainTitleFontSize,
        fontWeight: MainPageConstants.boldWeight,
        height: 1.4,
      ),
    );
  }
}

/// Displays the "Your Plans" header row.
class _PlansHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
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

/// Displays the user's travel plans as a horizontal list.
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
        child: Row(
          children:
              travelPlans
                  .map((travel) {
                    final imageUrl =
                        travel.imageUrl != null && travel.imageUrl!.isNotEmpty
                            ? travel.imageUrl!
                            : 'assets/sample_image.jpg';
                    return Row(
                      children: [
                        TravelPlanCard(
                          travelId: travel.id,
                          uid: travel.uid,
                          name: travel.name,
                          startDate: travel.startDate ?? DateTime.now(),
                          endDate: travel.endDate ?? DateTime.now(),
                          image: imageUrl,
                          location: travel.location,
                          createdOn: travel.createdOn,
                        ),
                        SizedBox(width: MainPageConstants.cardSpacing),
                      ],
                    );
                  })
                  .take(MainPageConstants.numTravelPlans)
                  .toList(),
        ),
      );
    }
  }
}

/// Displays the "Shared With You" header row.
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

/// Displays the shared travel plans as a horizontal list.
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
            child: Row(
              children:
                  snapshot.data!
                      .map((travel) {
                        final imageUrl =
                            travel.imageUrl != null &&
                                    travel.imageUrl!.isNotEmpty
                                ? travel.imageUrl!
                                : 'assets/sample_image.jpg';
                        return Row(
                          children: [
                            TravelPlanCard(
                              travelId: travel.id,
                              uid: travel.uid,
                              name: travel.name,
                              startDate: travel.startDate ?? DateTime.now(),
                              endDate: travel.endDate ?? DateTime.now(),
                              image: imageUrl,
                              location: travel.location,
                              createdOn: travel.createdOn,
                            ),
                            SizedBox(width: MainPageConstants.cardSpacing),
                          ],
                        );
                      })
                      .take(MainPageConstants.numTravelPlans)
                      .toList(),
            ),
          );
        }
      },
    );
  }
}
