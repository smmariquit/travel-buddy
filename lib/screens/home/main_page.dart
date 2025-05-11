import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'package:travel_app/widgets/travel_plan_card.dart';
import '../auth/signin_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import '../add_travel/add_travel_plan_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Travel>? _travelPlans;
  bool _isLoading = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !_hasInitialized) {
        final travelProvider = Provider.of<TravelTrackerProvider>(context, listen: false);
        travelProvider.setUser(user.uid);

        final userProvider = Provider.of<AppUserProvider>(context, listen: false);
        await userProvider.fetchUserForCurrentUser();

        await _loadTravelPlans();
        if (mounted) {
          setState(() {
            _hasInitialized = true;
          });
        }
      }
    });
  }

  Future<void> _loadTravelPlans() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final travelProvider = Provider.of<TravelTrackerProvider>(context, listen: false);
      final plans = await travelProvider.getTravelPlans();
       print("Plans loaded: ${plans.length}");

      if (mounted) {
        setState(() {
          _travelPlans = plans;
        });
      }
    } catch (e) {
      print('Error loading travel plans: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading travel plans: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _maybeAddNewTravelPlan() {
    final newTravelPlan = ModalRoute.of(context)?.settings.arguments as Travel?;
    if (newTravelPlan != null && _travelPlans != null) {
      final exists = _travelPlans!.any((plan) => plan.id == newTravelPlan.id);
      if (!exists) {
        setState(() {
          _travelPlans!.add(newTravelPlan);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStream = context.watch<AppUserProvider>().userStream;

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("Something went wrong.")));
        }

        if (!snapshot.hasData) {
          return const SignInPage();
        }

        // Called only after successful sign-in
        if (_hasInitialized) _maybeAddNewTravelPlan();

        final userProvider = Provider.of<AppUserProvider>(context);

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _loadTravelPlans,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 28),
                                    const SizedBox(width: 8),
                                    Text(
                                      userProvider.firstName ?? 'Traveler',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.notifications),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Up for a journey, ${userProvider.firstName ?? ''}?',
                              style: const TextStyle(
                                color: Color(0xFF1B1E28),
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Plans',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      color: Color(0xFFFF7029),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _travelPlans == null || _travelPlans!.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Text(
                                            'No travel plans available.\nTap the + button to create one!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: _travelPlans!.map((travel) {
                                            final imageUrl = travel.imageUrl?.isNotEmpty == true
                                                ? travel.imageUrl!
                                                : 'assets/sample_image.jpg';
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 16.0),
                                              child: TravelPlanCard(
                                                travelId: travel.id!,
                                                uid: travel.uid,
                                                name: travel.name,
                                                startDate: travel.startDate!,
                                                endDate: travel.endDate!,
                                                createdOn: travel.createdOn,
                                                location: travel.location,
                                                image: imageUrl,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: BottomNavBar(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            shape: const CircleBorder(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddTravelPlanPage()),
              ).then((_) => _loadTravelPlans());
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}