import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:travel_app/providers/travel_app_provider.dart';
import 'screens/main_page.dart';
import 'providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ((context) => TravelTrackerProvider())),
        ChangeNotifierProvider(create: ((context) => UserAuthProvider())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final userAuthProvider = context.read<UserAuthProvider>();
      final travelProvider = context.read<TravelTrackerProvider>();

      if (user != null) {
        userAuthProvider.setUser(user.uid);
        travelProvider.setUser(user.uid);
      } else {
        userAuthProvider.setUser(null);
        travelProvider.setUser(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
      },
      theme: ThemeData(primaryColor: const Color(0xFF3b665c)),
    );
  }
}
