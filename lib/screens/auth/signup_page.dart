// Flutter & Material
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/screens/auth/interests_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/utils/pick_profile_image.dart';
import 'package:travel_app/api/firebase_auth_api.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

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
  File? _profileImage;
  String? password;
  String? confirmPassword;
  bool _isUsernameTaken = false;
  Timer? _debounce;

  @override
  void dispose() {
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _goToNextPage() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _checkUsername(String text) {
    if (text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('appUsers')
          .where('username', isEqualTo: text)
          .get()
          .then((snapshot) {
            if (mounted) {
              _isUsernameTaken = snapshot.docs.isNotEmpty;
            }
          });
    } else {
      _isUsernameTaken = false;
    }
  }

  /////// Main build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/images/hike_bg.jpg', fit: BoxFit.cover),
          ),
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          // Form content
          SafeArea(
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
              children: [
                const Text(
                  "Step 1 of 3",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Tell us about yourself",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
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
                      const SizedBox(height: 10),
                      const Text(
                        "Tap to upload a profile picture",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  label: "First Name",
                  hint: "e.g. Juan",
                  onSaved: (val) => _signUpData.firstName = val,
                  validator:
                      (val) => val == null || val.isEmpty ? "Required" : null,
                  onChanged: (val) => _signUpData.firstName = val,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: "Middle Name (optional)",
                  hint: "e.g. Santos",
                  onSaved: (val) => _signUpData.middleName = val,
                  onChanged: (val) => _signUpData.middleName = val,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: "Last Name",
                  hint: "e.g. Dela Cruz",
                  onSaved: (val) => _signUpData.lastName = val,
                  validator:
                      (val) => val == null || val.isEmpty ? "Required" : null,
                  onChanged: (val) => _signUpData.lastName = val,
                ),
                const SizedBox(height: 140),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _goToNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF218463),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Next", style: TextStyle(fontSize: 16)),
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
  }) {
    return TextFormField(
      obscureText: obscureText,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
      validator: validator,
      controller: controller,
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(174, 238, 238, 238),
      labelText: label,
      labelStyle: const TextStyle(color: Color.fromARGB(255, 55, 55, 55)),
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      ),
    );
  }

  /////////////PAGE 2
  Widget _buildAccountInfoPage() {
    final _formKey2 = GlobalKey<FormState>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Step 2 of 3",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              const Text(
                "Set up your account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                label: "Username",
                hint: "e.g. juan_dlc",
                controller: _usernameController,
                onSaved: (val) => _signUpData.username = val,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  if (_isUsernameTaken) return "Username is already taken";
                  return null;
                },
                onChanged: (text) {
                  _checkUsername(text);
                },
                errorText:
                    _isUsernameTaken ? "Username is already taken" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: "Email",
                hint: "e.g. juan@gmail.com",
                onSaved: (val) => _signUpData.email = val,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final emailRegex = RegExp(
                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$",
                  );
                  if (!emailRegex.hasMatch(val)) return "Enter a valid email";
                  return null;
                },
                onChanged: (val) => _signUpData.email = val,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: "Phone Number",
                hint: "e.g. 09XXXXXXXXX",
                onSaved: (val) => _signUpData.phone = val,
                onChanged: (val) => _signUpData.phone = val,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                      child: const Text("Back"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey2.currentState!.validate()) {
                          _formKey2.currentState!.save();

                          final email = _signUpData.email!;
                          final username = _signUpData.username!;
                          final userSnapshot =
                              await FirebaseFirestore.instance
                                  .collection('appUsers')
                                  .where('email', isEqualTo: email)
                                  .get();

                          final usernameSnapshot =
                              await FirebaseFirestore.instance
                                  .collection('appUsers')
                                  .where('username', isEqualTo: username)
                                  .get();

                          if (userSnapshot.docs.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This email is already in use.'),
                              ),
                            );
                          } else if (usernameSnapshot.docs.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This username is already taken.',
                                ),
                              ),
                            );
                          } else {
                            // Proceed if both email and username are unique
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF218463),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Next"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /////////////PAGE 3
  Widget _buildSecurityInfoPage() {
    final _formKey3 = GlobalKey<FormState>();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController =
        TextEditingController();
    bool _obscurePassword = true;
    bool _obscureConfirmPassword = true;
    String? password;

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
              key: _formKey3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Step 3 of 3",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Secure your account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Password field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.black),
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        "Password",
                        "At least 6 characters",
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
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
                      onChanged: (val) => _signUpData.password = val,
                    ),
                  ),

                  // Confirm password field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(color: Colors.black),
                      obscureText: _obscureConfirmPassword,
                      decoration: _inputDecoration(
                        "Confirm Password",
                        "Repeat password",
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
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

                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                          child: const Text("Back"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey3.currentState!.validate()) {
                              password = _passwordController.text;
                              _signUpData.password = password!;
                              _signUpData.profileImage ??= File(
                                "assets/default_avatar.jpg",
                              );
                              _submitSignUp();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF218463),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Sign Up"),
                        ),
                      ),
                    ],
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
