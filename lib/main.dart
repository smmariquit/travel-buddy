/// TravelBuddy - An All-in-One Travel App in Flutter
///
/// This is the main entry point for the TravelBuddy application, a comprehensive travel planning app built with Flutter and Firebase.
///
/// ## Overview
/// TravelBuddy enables users to manage and track their travel plans, leveraging Firebase for authentication and data storage, and Provider for state management.
///
/// ## Features
/// - User authentication (sign in, sign up)
/// - Travel plan management
/// - State management using Provider
/// - Material 3 design system
///
/// ## Technologies Used
/// - Flutter
/// - Firebase (Core, Auth)
/// - Provider (State Management)
///
/// ## Developers
/// - De Ramos, Windee Rose - II BSCS
/// - Mariquit, Simonee Ezekiel - II BSCS ([LinkedIn](https://linkedin.com/in/stimmie))
/// - Duran, Jason - II BSCS
///
/// Developed May 2025
///
/// ## References
/// 1. Some parts of this app were made with the assistance of Large Language Models (LLMs) like Microsoft Copilot
/// 2. [DartDoc](https://dart.dev/tools/dart-doc)
/// 3. [Material Design](https://m3.material.io/)

// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:travel_app/utils/notification_service.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'providers/user_provider.dart';
import 'providers/travel_plans_provider.dart';
import 'screens/home/main_page.dart';
import 'screens/auth/signin_page.dart';

/// The main entry point of the application.
///
/// This function initializes Firebase and sets up the [MultiProvider] for state management.
///
/// The [TravelTrackerProvider] manages travel-related state, while the [AppUserProvider] manages user authentication state.
// [] means it will render in DartDoc. It will also ignore comments with //.

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        /// Provides the `TravelTrackerProvider` for managing travel-related state.
        ChangeNotifierProvider(create: ((context) => TravelTrackerProvider())),

        /// Provides the `AppUserProvider` for managing user authentication state.
        ChangeNotifierProvider(create: ((context) => AppUserProvider())),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the TravelBuddy application.
///
/// This widget initializes Firebase authentication listeners and sets up
/// the app's routing and theme. It is responsible for providing the top-level
/// [MaterialApp] and managing authentication state changes.
class MyApp extends StatefulWidget {
  /// Creates an instance of [MyApp].
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// State class for [MyApp].
///
/// Handles initialization logic, listens for authentication state changes,
/// and updates the relevant providers accordingly.
class _MyAppState extends State<MyApp> {
  /// Initializes the app's state and listens to authentication changes.
  ///
  /// When the authentication state changes, updates the [AppUserProvider] and
  /// [TravelTrackerProvider] with the current user's information.
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // Run the code whenever the auth changes
      /// Provider by the Provider package, context.read<thing>(); looks up the ancestors in the widget tree for the current context. Since we wrapped main in MultiProvider, it will find a provider and return it.
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
  /// Returns a [MaterialApp] configured with the app's theme, initial route,
  /// and navigation routes. The initial route is set to `/signin`.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelBuddy',
      initialRoute: '/main',
      routes: {
        '/signin': (context) => const SignInPage(), // Sign-in page
        '/main': (context) => const MainPage(), // Main page after sign-in
      },
      theme: ThemeData(primaryColor: const Color(0xFF3b665c)),
      // no need for home: since initialRoute is already set.
    );
  }
}
