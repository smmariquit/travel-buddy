// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/screens/auth/interests_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'package:travel_app/api/firebase_auth_api.dart';
import 'dart:io';
import 'dart:async';
import 'package:password_strength/password_strength.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class SignUpData {
  File? profileImage;
  String? firstName;
  String? middleName;
  String? lastName;
  String? username;
  String? email;
  String? phone;
  String? password;
}

class _SignUpPageState extends State<SignUpPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final SignUpData _signUpData = SignUpData();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? password;
  String? confirmPassword;
  bool _isUsernameTaken = false;
  bool _isEmailTaken = false;
  bool _isPhoneTaken = false;
  Timer? _usernameDebounce;
  Timer? _emailDebounce;
  Timer? _phoneDebounce;
  double _passwordStrength = 0.0;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = _signUpData.username ?? '';
    _emailController.text = _signUpData.email ?? '';
    _phoneController.text = _signUpData.phone ?? '';
    _firstNameController.text = _signUpData.firstName ?? '';
    _middleNameController.text = _signUpData.middleName ?? '';
    _lastNameController.text = _signUpData.lastName ?? '';
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_onEmailChanged);
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_onEmailChanged);
    _phoneController.removeListener(_onPhoneChanged);
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _phoneDebounce?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () {
      final text = _usernameController.text;
      if (text.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('appUsers')
            .where('username', isEqualTo: text)
            .get()
            .then((snapshot) {
              if (mounted) {
                final taken = snapshot.docs.isNotEmpty;
                if (_isUsernameTaken != taken) {
                  setState(() {
                    _isUsernameTaken = taken;
                  });
                }
              }
            });
      } else {
        if (mounted && _isUsernameTaken != false) {
          setState(() {
            _isUsernameTaken = false;
          });
        }
      }
    });
  }

  void _onEmailChanged() {
    _emailDebounce?.cancel();
    _emailDebounce = Timer(const Duration(milliseconds: 500), () {
      final text = _emailController.text;
      if (text.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('appUsers')
            .where('email', isEqualTo: text)
            .get()
            .then((snapshot) {
              if (mounted) {
                final taken = snapshot.docs.isNotEmpty;
                if (_isEmailTaken != taken) {
                  setState(() {
                    _isEmailTaken = taken;
                  });
                }
              }
            });
      } else {
        if (mounted && _isEmailTaken != false) {
          setState(() {
            _isEmailTaken = false;
          });
        }
      }
    });
  }

  void _onPhoneChanged() {
    _phoneDebounce?.cancel();
    _phoneDebounce = Timer(const Duration(milliseconds: 500), () {
      final text = _phoneController.text;
      if (text.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('appUsers')
            .where('phone', isEqualTo: text)
            .get()
            .then((snapshot) {
              if (mounted) {
                final taken = snapshot.docs.isNotEmpty;
                if (_isPhoneTaken != taken) {
                  setState(() {
                    _isPhoneTaken = taken;
                  });
                }
              }
            });
      } else {
        if (mounted && _isPhoneTaken != false) {
          setState(() {
            _isPhoneTaken = false;
          });
        }
      }
    });
  }

  void _goToNextPage() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Show a SnackBar if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /////// Main build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/hike_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPersonalInfoPage(),
                      _buildAccountInfoPage(),
                      _buildSecurityInfoPage(),
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
  ////////////////////////

  /////First page

  Widget _buildPersonalInfoPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressBar(
                  maxSteps: 3,
                  progressType: LinearProgressBar.progressTypeLinear,
                  currentStep: 1,
                  progressColor: Colors.green,
                  backgroundColor: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 10),
                Text(
                  "Let's get to know you!",
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF218463),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  _signUpData.profileImage != null
                                      ? FileImage(_signUpData.profileImage!)
                                      : const AssetImage(
                                            'assets/default_avatar.jpg',
                                          )
                                          as ImageProvider,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF218463),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Tap to upload or change your profile picture",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _buildTextField(
                  label: "First Name",
                  hint: "e.g. Juan",
                  controller: _firstNameController,
                  onSaved: (val) => _signUpData.firstName = val,
                  validator:
                      (val) => val == null || val.isEmpty ? "Required" : null,
                  onChanged: (val) => _signUpData.firstName = val,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: "Middle Name (optional)",
                  hint: "e.g. Santos",
                  controller: _middleNameController,
                  onSaved: (val) => _signUpData.middleName = val,
                  onChanged: (val) => _signUpData.middleName = val,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: "Last Name",
                  hint: "e.g. Dela Cruz",
                  controller: _lastNameController,
                  onSaved: (val) => _signUpData.lastName = val,
                  validator:
                      (val) => val == null || val.isEmpty ? "Required" : null,
                  onChanged: (val) => _signUpData.lastName = val,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _goToNextPage,
                    style: _buttonStyle,
                    child: const Text("Next"),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(120, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  //////////////////

  ///// Necessary Widgets
  Widget _buildTextField({
    required String label,
    required String hint,
    bool obscureText = false,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
    String? errorText,
    void Function(String)? onChanged,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF218463),
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  // Common button style
  final _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF218463),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(double.infinity, 55),
  );

  // Common outlined button style
  final _outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF218463),
    side: const BorderSide(color: Color(0xFF218463)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(double.infinity, 55),
  );

  /////////////PAGE 2
  Widget _buildAccountInfoPage() {
    final formKey2 = GlobalKey<FormState>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: formKey2,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressBar(
                        maxSteps: 3,
                        progressType: LinearProgressBar.progressTypeLinear,
                        currentStep: 2,
                        progressColor: Colors.green,
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Set up your account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(
                        label: "Username",
                        hint: "e.g. juan_dlc",
                        controller: _usernameController,
                        onSaved: (val) => _signUpData.username = val,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (_isUsernameTaken) {
                            return "Username is already taken";
                          }
                          return null;
                        },
                        onChanged: (text) {
                          _signUpData.username = text;
                        },
                        errorText:
                            _isUsernameTaken
                                ? "Username is already taken"
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Email",
                        hint: "e.g. juan@gmail.com",
                        controller: _emailController,
                        onSaved: (val) => _signUpData.email = val,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (_isEmailTaken) {
                            return "Email is already registered";
                          }
                          final emailRegex = RegExp(
                            r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$",
                          );
                          if (!emailRegex.hasMatch(val)) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                        onChanged: (val) {
                          _signUpData.email = val;
                        },
                        errorText:
                            _isEmailTaken
                                ? "Email is already registered"
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Phone Number (optional)",
                        hint: "e.g. 09606878535 (11 digits)",
                        controller: _phoneController,
                        onSaved: (val) => _signUpData.phone = val,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return null; // Allow empty
                          if (val.length != 11) {
                            return "Phone number must be 11 digits";
                          }
                          if (!val.startsWith('09')) {
                            return "Phone number must start with '09'";
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(val)) {
                            return "Phone number must contain only digits";
                          }
                          if (_isPhoneTaken) {
                            return "Phone number is already registered";
                          }
                          return null;
                        },
                        onChanged: (val) => _signUpData.phone = val,
                        keyboardType: TextInputType.phone,
                        errorText:
                            _isPhoneTaken
                                ? "Phone number is already registered"
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                      style: _outlinedButtonStyle,
                      child: const Text("Back"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey2.currentState!.validate()) {
                          formKey2.currentState!.save();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Show a SnackBar if validation fails
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fix the errors before continuing.',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: _buttonStyle,
                      child: const Text("Next"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(120, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /////////////PAGE 3
  Widget _buildSecurityInfoPage() {
    final formKey3 = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: formKey3,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressBar(
                            maxSteps: 3,
                            progressType: LinearProgressBar.progressTypeLinear,
                            currentStep: 3,
                            progressColor: Colors.green,
                            backgroundColor: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Secure your account",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Password field
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.black),
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Password",
                                labelStyle: const TextStyle(
                                  color: Color(0xFF218463),
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: "At least 6 characters",
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
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
                              onChanged: (val) {
                                _signUpData.password = val;
                                setState(() {
                                  _passwordStrength = estimatePasswordStrength(
                                    val,
                                  );
                                });
                              },
                            ),
                          ),
                          // Password strength indicator
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: _passwordStrength,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _passwordStrength < 0.3
                                        ? Colors.red
                                        : _passwordStrength < 0.7
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _passwordStrength < 0.3
                                      ? "Weak password"
                                      : _passwordStrength < 0.7
                                      ? "Medium strength"
                                      : "Strong password",
                                  style: TextStyle(
                                    color:
                                        _passwordStrength < 0.3
                                            ? Colors.red
                                            : _passwordStrength < 0.7
                                            ? Colors.orange
                                            : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Confirm password field
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              style: const TextStyle(color: Colors.black),
                              obscureText: obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                labelStyle: const TextStyle(
                                  color: Color(0xFF218463),
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: "Repeat password",
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscureConfirmPassword =
                                          !obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Repeat your password";
                                }
                                if (value != _passwordController.text) {
                                  return "Passwords do not match";
                                }
                                return null;
                              },
                              onChanged: (val) => _signUpData.password = val,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                          style: _outlinedButtonStyle,
                          child: const Text("Back"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey3.currentState!.validate()) {
                              password = _passwordController.text;
                              _signUpData.password = password!;
                              _signUpData.profileImage ??= File(
                                "assets/default_avatar.jpg",
                              );
                              _submitSignUp();
                            }
                          },
                          style: _buttonStyle,
                          child: const Text("Sign Up"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(120, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ////Submit function
  void _submitSignUp() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final FirebaseAuthAPI authService = FirebaseAuthAPI();
    File? profileImage = _signUpData.profileImage;
    String imageUrl = '';
    String uid = '';

    try {
      // First try to create the user account
      String? signUpMessage = await authService.signUp(
        _signUpData.email!,
        _signUpData.password!,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Check if there was an error during sign up
      if (signUpMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating account: $signUpMessage")),
        );
        return;
      }

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        uid = user.uid;

        // Handle profile image
        try {
          final storageRef = FirebaseStorage.instance.ref().child(
            'profile_images/$uid.jpg',
          );

          if (profileImage != null && await profileImage.exists()) {
            // If the user selected a profile image, upload it
            await storageRef.putFile(profileImage);
            imageUrl = await storageRef.getDownloadURL();
          } else {
            // Use a default image URL
            imageUrl =
                'https://firebasestorage.googleapis.com/v0/b/nth-autumn-458710-t7.firebasestorage.app/o/profile_images%2Fdefault_avatar.jpg?alt=media&token=99f110bf-3c7c-4fd4-a77a-ad29ce5f4653';
          }

          // Continue with user provider update
          await context.read<AppUserProvider>().signUp(
            _signUpData.firstName!,
            _signUpData.lastName!,
            _signUpData.email!,
            _signUpData.password!,
            _signUpData.middleName,
            _signUpData.username!,
            _signUpData.phone,
            imageUrl,
          );

          // Navigate to interests page on success
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const InterestsPage()),
            );
          }
        } catch (imageError) {
          // Handle image upload errors specifically
          // print('Error during image upload: $imageError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error uploading profile image: ${imageError.toString().substring(0, 100)}',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User account created but session not established. Please try logging in.',
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // print('Detailed error during sign up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-up failed: ${e.toString().substring(0, 100)}'),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await _showImageSourcePicker();
    if (source == null) return;

    final statusGranted = await _requestPermissions(source);
    if (!statusGranted) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _signUpData.profileImage = File(pickedFile.path);
      });
    }
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
    );
  }

  Future<bool> _requestPermissions(ImageSource source) async {
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return false;
    }
    return true;
  }
}
