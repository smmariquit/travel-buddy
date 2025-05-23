// Flutter & Material
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase & External Services
import 'package:firebase_auth/firebase_auth.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:travel_app/screens/home/main_page.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool showSignInErrorMessage = false;
  bool _obscurePassword = true;

  String? username;
  String? password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset('assets/images/hike_bg.jpg', fit: BoxFit.cover),
          ),

          // Dark overlay
          Container(color: Colors.black.withOpacity(0.5)),

          // Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 100,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome back! Log in to plan your next trip.",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    usernameField,
                    passwordField,
                    if (showSignInErrorMessage) signInErrorMessage,
                    const SizedBox(height: 10),
                    submitButton,
                    const SizedBox(height: 20),
                    orConnect,
                    googleSignInButton,
                    signUpButton,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get heading => const Center(
    child: Text(
      "Sign In",
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3CC08E),
      ),
    ),
  );

  Widget get subtitle => const Center(
    child: Text(
      "Welcome back! Please log in to continue.",
      style: TextStyle(fontSize: 16, color: Colors.grey),
      textAlign: TextAlign.center,
    ),
  );

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Widget get usernameField => Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: TextFormField(
      controller: _usernameController,
      decoration: _inputDecoration("Username", "e.g. travelguru123"),
      onSaved: (value) => username = value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your username";
        }
        if (value.length < 3) {
          return "Username must be at least 3 characters long";
        }
        // final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$");
        // if (!emailRegex.hasMatch(value)) {
        //   return 'Please enter a valid email address';
        // }
        return null;
      },
    ),
  );

  Widget get passwordField => Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: _inputDecoration("Password", "******").copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      onSaved: (value) => password = value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your password";
        }
        return null;
      },
    ),
  );

  Widget get signInErrorMessage => const Padding(
    padding: EdgeInsets.only(bottom: 30),
    child: Text(
      "Invalid username or password",
      style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
    ),
  );

  Widget get submitButton => Container(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3CC08E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          final authProvider = context.read<AppUserProvider>();
          final travelProvider = context.read<TravelTrackerProvider>();
          String message = await authProvider.signIn(username!, password!);
          if (message == "Signed in successfully") {
            travelProvider.setUser(authProvider.uid);
            setState(() {
              showSignInErrorMessage = false;
            });
            Navigator.pushReplacementNamed(
              context,
              '/main',
            ); // Navigate to main page
          } else {
            setState(() {
              showSignInErrorMessage = true;
            });
          }
        }
      },
      child: const Text("Sign In", style: TextStyle(fontSize: 16)),
    ),
  );

  Widget get googleSignInButton => Center(
    child: Container(
      width: 200,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton.icon(
        icon: Image.network(
          'https://img.icons8.com/color/48/000000/google-logo.png',
          height: 24,
          width: 24,
        ),
        label: const Text(
          "Sign in with Google",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () async {
          final authProvider = context.read<AppUserProvider>();
          final travelProvider = context.read<TravelTrackerProvider>();

          // Sign in with Google
          String? result = await authProvider.signInWithGoogle();

          if (result == null) {
            // Check if user exists in Firestore
            final userDoc =
                await FirebaseFirestore.instance
                    .collection('appUsers')
                    .doc(authProvider.uid)
                    .get();

            if (userDoc.exists) {
              // User exists, sign them in directly
              travelProvider.setUser(authProvider.uid);
              Navigator.pushReplacementNamed(context, '/main');
            } else {
              // New user, go to signup flow
              Navigator.pushReplacementNamed(context, '/interests');
            }
          } else {
            // If sign-in fails, show error message
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(result)));
          }
        },
      ),
    ),
  );

  Widget get orConnect => Padding(
    padding: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Or connect with", style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget get signUpButton => Padding(
    padding: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.grey),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpPage()),
            ).then((_) {
              Navigator.pushReplacementNamed(
                context,
                '/interests',
              ); // Navigate to interests page after signup
            });
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(color: Color(0xFFFF7029)),
          ),
        ),
      ],
    ),
  );
}
