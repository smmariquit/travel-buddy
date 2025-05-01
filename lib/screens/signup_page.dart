import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/screens/interests_page.dart';
import '../providers/auth_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String? firstName;
  String? lastName;
  String? username;
  String? email;
  String? password;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
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
                firstNameField,
                lastNameField,
                usernameField,
                emailField,
                passwordField,
                submitButton,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get heading => const Center(
    child: Text(
      "Create an account",
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
    ),
  );

  Widget get subtitle => const Center(
    child: Text(
      "Tell us a bit about yourself",
      style: TextStyle(fontSize: 16, color: Color.fromARGB(214, 0, 0, 0)),
    ),
  );

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(174, 238, 238, 238),
      labelText: label,
      labelStyle: TextStyle(color: Color.fromARGB(255, 55, 55, 55)),
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      )
    );
  }

  Widget get firstNameField => Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: TextFormField(
      
      style: const TextStyle(color: Colors.black),
      decoration: _inputDecoration("First Name", "Juan"),
      onSaved: (value) => firstName = value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your first name";
        }
        return null;
      },
    ),
  );

  Widget get lastNameField => Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: TextFormField(
      style: const TextStyle(color: Colors.black),
      decoration: _inputDecoration("Last Name", "Dela Cruz"),
      onSaved: (value) => lastName = value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your last name";
        }
        return null;
      },
    ),
  );

  Widget get emailField => Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: TextFormField(
      style: const TextStyle(color: Colors.black),
      decoration: _inputDecoration("Email", "juandelacruz09@gmail.com"),
      onSaved: (value) => email = value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your email";
        }
        final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$");
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    ),
  );

  Widget get passwordField => Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: TextFormField(
      style: const TextStyle(color: Colors.black),
      obscureText: _obscurePassword,
      decoration: _inputDecoration("Password", "At least 6 characters").copyWith(
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
          return "Please enter a valid password";
        }
        if (value.length < 6) {
          return "Password must be at least 6 characters long";
        }
        String pattern =
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$';
        RegExp regex = RegExp(pattern);
        if (!regex.hasMatch(value)) {
          return "Password must contain uppercase, lowercase, digit, and special character";
        }
        return null;
      },
    ),
  );

  Widget get submitButton => Container(
    width: double.infinity,
    height: 50,
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3CC08E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          await context
              .read<UserAuthProvider>()
              .signUp(firstName!, lastName!, email!, password!, username!);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InterestsPage()),
            );
          };
        }
      },
      child: const Text("Sign Up", style: TextStyle(fontSize: 16)),
    ),
  );

  Widget get usernameField => Padding(
  padding: const EdgeInsets.only(bottom: 30),
  child: TextFormField(
    style: const TextStyle(color: Colors.black),
    decoration: _inputDecoration("Username", "juan_dlc"),
    onSaved: (value) => username = value,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return "Please enter a username";
      }
      return null;
    },
  ),
);

}
