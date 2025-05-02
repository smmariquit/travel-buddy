import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/travel_app_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/screens/find_similar_people.dart';
import 'package:travel_app/screens/profile_screen.dart';
import 'signin_page.dart';
import '../providers/auth_provider.dart';
import 'package:travel_app/screens/interests_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userStream = context.watch<UserAuthProvider>().userStream;

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
        final provider = Provider.of<TravelTrackerProvider>(
          context,
          listen: false,
        );
        provider.setUser(user.uid);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              "Travel App",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                color: Colors.red,
                onPressed: () async {
                  _showSignOutDialog(context);
                  Provider.of<TravelTrackerProvider>(
                    context,
                    listen: false,
                  ).clearUser();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.person),
                    const Icon(Icons.notifications_active),
                  ],
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore destinations around the world!',
                      style: TextStyle(
                        color: Color(0xFF1B1E28),
                        fontSize: 20,
                        fontFamily: 'SF UI Display',
                        fontWeight: FontWeight.w600,
                        height: 1.40,
                      ),
                    ),
                    const Text(
                      'View all',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFFFF7029),
                        fontSize: 14,
                        fontFamily: 'SF UI Display',
                        fontWeight: FontWeight.w400,
                        height: 1.14,
                      ),
                    ),
                  ],
                ),
              ),
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
                                  image: const DecorationImage(
                                    image: NetworkImage("https://placehold.co/240x286"),
                                    fit: BoxFit.fill,
                                  ),
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
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.handshake),
                label: 'Connect',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onTap: (index) {
              print('Selected index: $index');
              // Handle navigation based on the selected index
              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindSimilarPeople()),
                  );
                  // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FindSimilarPeople()));
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile()));
                  break;
              }
            },
          ),
        );
      },
    );
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
}
