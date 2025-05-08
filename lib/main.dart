/// TravelBuddy - an all-in-one travel app in Flutter
/// 
/// This is a simple travel app that allows users to track their travel plans.
/// With Flutter and Firebase, this app was created in partial fulfillment of the requirements of CMSC 23 - Mobile Programming at the University of the Philippines - Los Baños
/// 
/// This is the entry point of the TravelBuddy app. Here, we initialize Firebase, set up the `MultiProvider`
/// for state management, and also define the main application widget.
/// 
/// For state management, this app uses `Provider`. `FirebaseAuth` is used for authentication.
/// 
/// DEVELOPERS:
/// De Ramos, Windee Rose - II BSCS
/// Mariquit, Simonee Ezekiel - II BSCS (https://linkedin.com/in/stimmie)
/// Duran, Jason - II BSCS
/// 
/// Developed May 2025
/// 
/// REFERENCES:
/// [1] Some parts of this app were made with the assistance of Large Language Models (LLMs) like Microsoft Copilot
/// [2] DartDoc https://dart.dev/tools/dart-doc

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/interests_page%20copy.dart';
import 'firebase_options.dart';
import 'package:travel_app/screens/auth/signin_page.dart';
import 'package:travel_app/screens/auth/signup_page.dart';

// Provider for state management
import 'package:provider/provider.dart';

// Import other necessary classes
import 'providers/travel_plans_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home/main_page.dart';

// Design system - https://m3.material.io/
import 'package:flutter/material.dart';

/// The main entry point of the application.
/// This function initializes Firebase and sets up the `MultiProvider` for state management.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'myApp',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        /// Provides the `TravelTrackerProvider` for managing travel-related state.
        ChangeNotifierProvider(create: ((context) => TravelTrackerProvider())),

        /// Provides the `AppUserProvider` for managing user authentication state.
        // ChangeNotifierProvider(create: ((context) => AppUserProvider())),


        ChangeNotifierProvider(create: ((context) => AppUserProvider())),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
/// 
/// This widget initializes Firebase authentication listeners and sets up
/// the app's routing and theme.
class MyApp extends StatefulWidget {
  /// Creates an instance of `MyApp`.
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Initializes the app's state and listens to whether the user changes.
  /// 
  /// When the users do somehow change within the app, it updates the `AppUserProvider`
  /// and `TravelTrackerProvider` with the current user's information.
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final appUserProvider = context.read<AppUserProvider>();
      final travelProvider = context.read<TravelTrackerProvider>();

      if (user != null) {
        /// Sets the user ID in both providers when a user is logged in.
        appUserProvider.setUser(user.uid);
        travelProvider.setUser(user.uid);
      } else {
        /// Clears the user ID in both providers when no user is logged in.
        appUserProvider.setUser(null);
        travelProvider.setUser(null);
      }
    });
  }

  /// Builds the main application widget.
  /// 
  /// This widget defines the app's theme, initial route, and navigation routes. Basically the settings of the app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelBuddy',
      initialRoute: '/signin',
      routes: {
        '/signin': (context) => const SignInPage(), // Sign-in page
        '/main': (context) => const MainPage(), // Main page after sign-inR
      },
      theme: ThemeData(primaryColor: const Color(0xFF3b665c)),
    );
  }
}
