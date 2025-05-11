import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/screens/friends/find_similar_people.dart';
import 'package:travel_app/screens/profile/profile_screen.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'package:travel_app/widgets/travel_plan_card.dart';
import '../auth/signin_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/auth/interests_page.dart';
import 'package:travel_app/screens/home/notifications.dart';
import '../add_travel/add_travel_plan_page.dart';

final NUM_PLANS = 5;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Travel> _travelPlans = [];

  @override
  Widget build(BuildContext context) {
    final newTravelPlan = ModalRoute.of(context)?.settings.arguments as Travel?;
    if (newTravelPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _travelPlans.add(newTravelPlan);
        });
      });
    }

    final userStream = context.watch<AppUserProvider>().userStream;

    return StreamBuilder<User?>(
      stream: userStream,
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
        final travelProvider = Provider.of<TravelTrackerProvider>(context, listen: false);
        final userProvider = Provider.of<AppUserProvider>(context, listen: false);

        travelProvider.setUser(user.uid);
        userProvider.fetchUserForCurrentUser();

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          /// Greeting Row
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

                          /// "Your Plans" Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your Plans',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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

                          /// Horizontal scroll for Travel Plans
                          FutureBuilder<List<Travel>>(
                            future: travelProvider.getTravelPlans(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text('No travel plans available.');
                              } else {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: snapshot.data!.map((travel) {
                                      final imageUrl = travel.imageUrl != null && travel.imageUrl!.isNotEmpty
                                        ? travel.imageUrl!
                                        : 'assets/sample_image.jpg';
                                      return TravelPlanCard(
                                        uid: travel.uid,
                                        name: travel.name,
                                        startDate: travel.startDate ?? DateTime.now(),
                                        endDate: travel.endDate ?? DateTime.now(),
                                        image: imageUrl,
                                        location: travel.location,
                                        createdOn: travel.createdOn,
                                      );
                                    }).toList(),
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 32),
                        ],
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