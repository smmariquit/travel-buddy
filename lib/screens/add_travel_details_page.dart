import 'package:flutter/material.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/screens/signin_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';

class TravelDetailsPage extends StatefulWidget {
  
  @override
  _TravelDetailsPageState createState() => _TravelDetailsPageState();
}

class _TravelDetailsPageState extends State<TravelDetailsPage> {
    
  final Color primaryColor = const Color(0xFF004225);
  final Color accentColor = const Color(0xFFb7fdfe);
  final Color backgroundColor = const Color(0xFFFFFFFF);
  final Color errorColor = const Color(0xFFe06666);
  final Color highlightColor = const Color(0xFFf6b26b);
  final Color textColor = const Color(0xFF000000);


  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  AppUser? _currentUserData;

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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('Create New Trip'),
        centerTitle: true,
      ),
    );
       }
     );
  }
}