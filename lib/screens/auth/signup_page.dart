import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/screens/auth/interests_page.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:travel_app/utils/pick_profile_image.dart';
import 'package:travel_app/api/firebase_auth_api.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

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
  File? _profileImage;
  String? password;
  String? confirmPassword;

  void _goToNextPage() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
            child: Image.asset(
              'assets/images/hike_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
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
                        backgroundImage: _signUpData.profileImage != null
                            ? FileImage(_signUpData.profileImage!)
                            : const AssetImage('assets/default_avatar.jpg') as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("Tap to upload a profile picture",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                label: "First Name",
                hint: "e.g. Juan",
                onSaved: (val) => _signUpData.firstName = val,
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: "Middle Name (optional)",
                hint: "e.g. Santos",
                onSaved: (val) => _signUpData.middleName = val,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: "Last Name",
                hint: "e.g. Dela Cruz",
                onSaved: (val) => _signUpData.lastName = val,
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
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
              )
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
  }) {
    return TextFormField(
      obscureText: obscureText,
      onSaved: onSaved,
      validator: validator,
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
              onSaved: (val) => _signUpData.username = val,
              validator: (val) => val == null || val.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "Email",
              hint: "e.g. juan@gmail.com",
              onSaved: (val) => _signUpData.email = val,
              validator: (val) {
                if (val == null || val.isEmpty) return "Required";
                final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$");
                if (!emailRegex.hasMatch(val)) return "Enter a valid email";
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "Phone Number",
              hint: "e.g. 09XXXXXXXXX",
              onSaved: (val) => _signUpData.phone = val,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pageController.previousPage(
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
                        final userSnapshot = await FirebaseFirestore.instance
                            .collection('appUsers')
                            .where('email', isEqualTo: email)
                            .get();

                        final usernameSnapshot = await FirebaseFirestore.instance
                            .collection('appUsers')
                            .where('username', isEqualTo: username)
                            .get();

                        if (userSnapshot.docs.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This email is already in use.')),
                          );
                        } else if (usernameSnapshot.docs.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This username is already taken.')),
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
                )
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
  final TextEditingController _confirmPasswordController = TextEditingController();
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
                const Text("Step 3 of 3",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                const Text("Secure your account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                // Password field
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: TextFormField(
                    controller: _passwordController,
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
                ),

                // Confirm password field
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: Colors.black),
                    obscureText: _obscureConfirmPassword,
                    decoration: _inputDecoration("Confirm Password", "Repeat password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                  ),
                ),

                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
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
                            _signUpData.profileImage ??= File("assets/default_avatar.jpg");
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
  final FirebaseAuthAPI authService = FirebaseAuthAPI();
  File? profileImage = _signUpData.profileImage;
  String imageUrl = '';
  String uid = '';

  try {
    String? signUpMessage = await authService.signUp(
      _signUpData.email!,
      _signUpData.password!,
    );

    if (signUpMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(signUpMessage)),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      uid = user.uid;

      final storageRef = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');

      if (profileImage != null && await profileImage.exists()) {
        // If the user selected a profile image, upload it
        await storageRef.putFile(profileImage);
      } else {
        // If no profile image is selected, upload a default avatar image
        final byteData = await rootBundle.load('assets/default_avatar.jpg');
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/default_avatar.jpg');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        await storageRef.putFile(file);
      }

      imageUrl = await storageRef.getDownloadURL();

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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterestsPage()),
        );
      }
    }
  } catch (e) {
    print('Error during sign up or image upload: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign-up failed. Please try again.')),
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return false;
    }
    return true;
  }

}