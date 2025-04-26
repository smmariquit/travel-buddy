import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/travel_app_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_page.dart';
import '../providers/auth_provider.dart';

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
        final provider = Provider.of<TravelTrackerProvider>(context, listen: false);
        provider.setUser(user.uid);
        // final provider = Provider.of<TravelTrackerProvider>(context);

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
