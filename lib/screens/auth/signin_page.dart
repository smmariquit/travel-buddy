// Flutter & Material
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase & External Services
import 'package:firebase_auth/firebase_auth.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:travel_app/screens/friends/friends_list.dart';
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
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 60,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Welcome Back!",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Sign in to continue planning your next adventure.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 50),
                            usernameField,
                            passwordField,
                            if (showSignInErrorMessage) signInErrorMessage,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _signUpCTAButton(context),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: submitButton),
                          const SizedBox(width: 12),
                          Expanded(child: googleSignInButton),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
      style: const TextStyle(color: Colors.white),
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
      style: const TextStyle(color: Colors.white),
      obscureText: _obscurePassword,
      decoration: _inputDecoration("Password", "******").copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
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

  Widget get submitButton => SizedBox(
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
            Navigator.pushReplacementNamed(context, '/main');
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

  Widget get googleSignInButton => SizedBox(
    height: 55,
    child: ElevatedButton.icon(
      icon: Image.network(
        'https://img.icons8.com/color/48/000000/google-logo.png',
        height: 24,
        width: 24,
      ),
      label: const Text(
        "Google",
        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
      onPressed: () async {
        final authProvider = context.read<AppUserProvider>();
        final travelProvider = context.read<TravelTrackerProvider>();
        await authProvider.signOutGoogle();
        String? result = await authProvider.signInWithGoogle();
        if (result == null) {
          travelProvider.setUser(authProvider.uid);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.zero,
            ),
          );
        }
      },
    ),
  );

  Widget _signUpCTAButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          "Don't have an account? Sign up",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3CC08E),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpPage()),
          );
        },
      ),
    );
  }
}
