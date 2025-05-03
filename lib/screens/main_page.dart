import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/screens/find_similar_people.dart';
import 'package:travel_app/screens/profile_screen.dart';
import 'signin_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/interests_page.dart';
import 'package:travel_app/screens/notifications.dart';
import 'add_travel_plan_page.dart';

class MainPage extends StatelessWidget {
   const MainPage({super.key});
 
   @override
   Widget build(BuildContext context) {
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
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          margin: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1EB3BCC8),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    // image: const DecorationImage(
                                    //   image: NetworkImage("https://placeholder.co/240x286"),
                                    //   fit: BoxFit.fill,
                                    // ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Opacity(
                                    opacity: 0.20,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8.0),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B1E28),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.home, color: Colors.green),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.map, color: Colors.grey),
                  onPressed: () {
                    // TODO: Replace with Plans page
                  },
                ),
                const SizedBox(width: 48), // space for FAB
                IconButton(
                  icon: Icon(Icons.handshake, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FindSimilarPeople()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
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
 
  //  void _showSignOutDialog(BuildContext context) {
  //    showDialog(
  //      context: context,
  //      builder: (BuildContext context) {
  //        return AlertDialog(
  //          title: const Text('Are you sure you want to sign out?'),
  //          actions: <Widget>[
  //            TextButton(
  //              onPressed: () {
  //                Navigator.of(context).pop();
  //              },
  //              child: const Text('Cancel'),
  //            ),
  //            TextButton(
  //              onPressed: () async {
  //                await FirebaseAuth.instance.signOut();
  //                Navigator.of(context).pop();
  //                Navigator.pushReplacementNamed(context, '/signin');
  //              },
  //              child: const Text('Sign Out'),
  //            ),
  //          ],
  //        );
  //      },
  //    );
  //  }
 }