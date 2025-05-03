import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'signup_page.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';

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
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            SystemNavigator.pop(); // Closes the app
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 10),
                subtitle,
                const SizedBox(height: 40),
                usernameField,
                passwordField,
                if (showSignInErrorMessage) signInErrorMessage,
                submitButton,
                signUpButton,
                orConnect,  
                googleSignInButton,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get heading => const Center(
    child: Text(
      "Sign in now",
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
    ),
  );

  Widget get subtitle => const Center(
    child: Text(
      "Please sign in to continue our app",
      style: TextStyle(fontSize: 16, color: Colors.grey),
    ),
  );


  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(174, 238, 238, 238),
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
      ),
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
    height: 60,
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: ElevatedButton(
       style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3CC08E), // green
        foregroundColor: Colors.white, // text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
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
          } else {
            setState(() {
              showSignInErrorMessage = true;
            });
          }
        }
      },
      child: const Text("Sign In"),
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
        label: const Text("Sign in with Google", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () async {
          final authProvider = context.read<AppUserProvider>();
          final travelProvider = context.read<TravelTrackerProvider>();

          String? result = await authProvider.signInWithGoogle();

          if (result == null) {
            travelProvider.setUser(authProvider.uid);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result)),
            );
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
        const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpPage()),
            );
          },
          child: const Text("Sign Up", style: TextStyle(color: Color(0xFFFF7029))),
        ),
      ],
    ),
  );
}
