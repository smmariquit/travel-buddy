import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/travel_app_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_page.dart';
import '../providers/auth_provider.dart';
import 'package:travel_app/screens/interests_page.dart';
import 'main_page.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final userStream = context.watch<UserAuthProvider>().userStream;

    // return StreamBuilder<User?>(
    //   stream: userStream,
    //   builder: (context, snapshot) {
    //     if (snapshot.hasError) {
    //       return Scaffold(
    //         body: Center(child: Text("Error: ${snapshot.error}")),
    //       );
    //     } else if (snapshot.connectionState == ConnectionState.waiting) {
    //       return const Scaffold(
    //         body: Center(child: CircularProgressIndicator()),
    //       );
    //     } else if (!snapshot.hasData) {
    //       return const SignInPage();
    //     }
        
    //     final user = snapshot.data!;
    //     final provider = Provider.of<TravelTrackerProvider>(context, listen: false);
    //     provider.setUser(user.uid);
    //     // final provider = Provider.of<TravelTrackerProvider>(context);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Travel App", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
              icon: const Icon(Icons.exit_to_app),
              color: Colors.red,
              onPressed: () async {
                _showSignOutDialog(context);
                Provider.of<TravelTrackerProvider>(context, listen: false).clearUser();
              },
              ),
            ],
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InterestsPage()),
                    );
                  },
                  child: const Text('Button 1'),
                ),
                const SizedBox(height: 20), // Add spacing between buttons
                ElevatedButton(
                  onPressed: () {
                    // Add functionality for Button 2
                  },
                  child: const Text('Button 2'),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              ),
              BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
              ),
              BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
              ),
            ],
            onTap: (index) {
              // Handle navigation based on the selected index
              switch (index) {
              case 0:
                // Navigate to Home
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                break;
              case 1:
                // Navigate to Search
                break;
              case 2:
                // Navigate to Profile
                break;
              }
            },
            ),
          );
      }
      // );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('Cancel'),  
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/signin'); 
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
// }
