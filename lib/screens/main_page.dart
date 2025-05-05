import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/screens/find_similar_people.dart';
import 'package:travel_app/screens/profile_screen.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'package:travel_app/widgets/travel_plan_card.dart';
import 'signin_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/interests_page.dart';
import 'package:travel_app/screens/notifications.dart';
import 'add_travel_plan_page.dart';

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
      setState(() {
        _travelPlans.add(newTravelPlan); // Add the new travel plan to the list
      });
    }

    final userStream = context.watch<AppUserProvider>().userStream;

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
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

        // Load user data once
        travelProvider.setUser(user.uid);
        userProvider.fetchUserForCurrentUser();

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👤 First name row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          userProvider.firstName ?? 'Traveler', // safely handle null
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                      ],
                    ),
                    // Notification button 
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        // Navigator.push(
                        //   // context,
                        //   // MaterialPageRoute(builder: (context) => const NotificationPage()),
                        // );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Up for a journey, ${userProvider.firstName}?',
                        style: TextStyle(
                          color: Color(0xFF1B1E28),
                          fontSize: 35,
                          fontFamily: 'SF UI Display',
                          fontWeight: FontWeight.w600,
                          height: 1.40,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Your Plans',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFF1B1E28),
                          fontSize: 14,
                          // fontFamily: 'SF UI Display',
                          fontWeight: FontWeight.w600,
                          // height: 1.40,
                        ),
                      ),
                    ),
                    // "View All" Button
                    TextButton(
                      onPressed: () {
                        // Navigate to another page 
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFFFF7029), // Orange color
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Featured box
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FutureBuilder<List<Travel>>(
                        future: travelProvider.getTravelPlans(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No travel plans available.');
                          } else {
                            return Row(
                              children: snapshot.data!.map((travel) {
                                return TravelPlanCard(
                                  uid: travel.uid,
                                  name: travel.name,
                                  startDate: travel.startDate ?? DateTime.now(),
                                  endDate: travel.endDate ?? DateTime.now(),
                                  image: 'assets/sample_image.jpg', // Corrected image initialization
                                  location: travel.location,
                                  createdOn: travel.createdOn,
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                )
              ],
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