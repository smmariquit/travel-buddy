import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:travel_app/utils/responsive_layout.dart';
import 'package:travel_app/utils/image_converter.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  List<Map<String, dynamic>> _interests = [
    {"interest": 'Adventure', "selected": false},
    {"interest": 'Culture', "selected": false},
    {"interest": 'Food', "selected": false},
    {"interest": 'Nature', "selected": false},
    {"interest": 'Relaxation', "selected": false},
    {"interest": 'Shopping', "selected": false},
    {"interest": 'Sightseeing', "selected": false},
    {"interest": 'Sports', "selected": false}
  ];

  List<Map<String, dynamic>> _travelStyles = [
    {"style": 'Backpacking', "selected": false},
    {"style": 'Luxury Travel', "selected": false},
    {"style": 'Solo Travel', "selected": false},
    {"style": 'Family Vacation', "selected": false},
    {"style": 'Cruise', "selected": false},
    {"style": 'Road Trip', "selected": false},
    {"style": 'Eco-Tourism', "selected": false},
    {"style": 'Adventure Travel', "selected": false}
  ];

  AppUser? _currentUserData;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppUserProvider>();
      final userStream = provider.userStream;

      userStream.listen((firebaseUser) async {
        if (firebaseUser != null) {
          final uid = firebaseUser.uid;
          final doc = await FirebaseFirestore.instance.collection('appUsers').doc(uid).get();

          if (doc.exists) {
            final data = doc.data()!;
            final user = AppUser.fromJson(data);

            final masterInterests = [
              'Adventure', 'Culture', 'Food', 'Nature',
              'Relaxation', 'Shopping', 'Sightseeing', 'Sports'
            ];

            final masterStyles = [
              'Backpacking', 'Luxury Travel', 'Solo Travel', "Family Vacation", 
              "Cruise", 'Road Trip', 'Eco-Tourism', 'Adventure Travel'
            ];

            final selectedInterests = user.interests ?? [];
            final selectedStyles = user.travelStyles ?? [];

            setState(() {
              _currentUserData = user;
              _firstNameController.text = user.firstName;
              _middleNameController.text = user.middleName ?? '';
              _lastNameController.text = user.lastName;
              _phoneController.text = user.phoneNumber ?? '';
              _locationController.text = user.location ?? '';
              _isPrivate = user.isPrivate;

              _interests = masterInterests.map((interest) {
                return {
                  "interest": interest,
                  "selected": selectedInterests.contains(interest)
                };
              }).toList();

              _travelStyles = masterStyles.map((style) {
                return {
                  "style": style,
                  "selected": selectedStyles.contains(style)
                };
              }).toList();
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && _currentUserData != null) {
      final provider = context.read<AppUserProvider>();
      final uid = _currentUserData!.uid;

      if (_currentUserData!.firstName != _firstNameController.text) {
        await provider.editFirstName(uid, _firstNameController.text.trim());
      }
      if (_currentUserData!.lastName != _lastNameController.text) {
        await provider.editLastName(uid, _lastNameController.text.trim());
      }
      if ((_currentUserData!.phoneNumber ?? '') != _phoneController.text) {
        await provider.editPhoneNumber(uid, _phoneController.text.trim());
      }
      if ((_currentUserData!.location ?? '') != _locationController.text) {
        await provider.editLocation(uid, _locationController.text.trim());
      }

      List<String> selectedInterests = _interests
          .where((interest) => interest['selected'])
          .map<String>((interest) => interest['interest'] as String)
          .toList();

      List<String> selectedTravelStyles = _travelStyles
          .where((style) => style['selected'])
          .map<String>((style) => style['style'] as String)
          .toList();

      try {
        await FirebaseFirestore.instance.collection('appUsers').doc(uid).update({
          'interests': selectedInterests,
          'travelStyles': selectedTravelStyles,
        });
      } catch (e) {
        print("Failed to save interests and travel styles: $e");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );

      provider.loadUserStream(uid);
      final doc = await FirebaseFirestore.instance.collection('appUsers').doc(uid).get();
      if (doc.exists) {
        final updatedUser = AppUser.fromJson(doc.data()!);
        setState(() {
          _currentUserData = updatedUser;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          _currentUserData!.username,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),

                Transform.translate(
                  offset: Offset(0, -30),
                  child: Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _currentUserData!.profileImageUrl != null &&
                                    _currentUserData!.profileImageUrl!.isNotEmpty
                                ? MemoryImage(base64Decode(_currentUserData!.profileImageUrl!))
                                : null,
                            child: _currentUserData!.profileImageUrl == null ||
                                    _currentUserData!.profileImageUrl!.isEmpty
                                ? Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () async {
                              final source = await showModalBottomSheet<ImageSource>(
                                context: context,
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Take a photo'),
                                        onTap: () => Navigator.pop(context, ImageSource.camera),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: const Text('Choose from gallery'),
                                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (source == null) return;

                              final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
                              final status = await permission.request();

                              if (!status.isGranted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${permission.toString().split('.').last} permission denied')),
                                );
                                return;
                              }

                              final picked = await ImagePicker().pickImage(source: source);
                              if (picked != null) {
                                final bytes = await picked.readAsBytes();
                                final base64Image = base64Encode(bytes);

                                final provider = context.read<AppUserProvider>();
                                final uid = _currentUserData!.uid;

                                await provider.editProfileImageUrl(uid, base64Image);
                                provider.loadUserStream(uid);

                                final doc = await FirebaseFirestore.instance.collection('appUsers').doc(uid).get();
                                if (doc.exists) {
                                  final updatedUser = AppUser.fromJson(doc.data()!);
                                  setState(() {
                                    _currentUserData = updatedUser;
                                  });
                                }
                              }
                            },

                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 5),
                
                  Transform.translate(
                    offset: Offset(0, -30),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildProfileField(icon: Icons.person_outline, label: "First Name", controller: _firstNameController)),
                                SizedBox(width: 10),
                                Expanded(child: _buildProfileField(icon: Icons.badge, label: "Last Name", controller: _lastNameController)),
                              ],
                            ),
                            _buildProfileField(icon: Icons.account_circle_outlined, label: _currentUserData!.username, editable: false),
                            _buildProfileField(icon: Icons.email_outlined, label: _currentUserData!.email, editable: false),
                            _buildProfileField(icon: Icons.phone_outlined, label: "Phone number", controller: _phoneController),
                            _buildProfileField(icon: Icons.location_on_outlined, label: "Location", controller: _locationController),

                            SizedBox(height: 8),
                            Text('Interests', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _interests.map((item) {
                                final isSelected = item['selected'];
                                return InputChip(
                                  label: Text(
                                    item['interest'],
                                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      item['selected'] = selected;
                                    });
                                  },
                                  selectedColor: Colors.green,
                                  checkmarkColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 8),
                            Text('Travel Styles', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _travelStyles.map((item) {
                                final isSelected = item['selected'];
                                return InputChip(
                                  label: Text(
                                    item['style'],
                                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      item['selected'] = selected;
                                    });
                                  },
                                  selectedColor: Colors.green,
                                  checkmarkColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _saveChanges,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green[700],
                                  side: BorderSide(color: Colors.green[700]!),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  "Edit profile",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
              ],
            ),
          ),
        ),
      ),   
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    TextEditingController? controller,
    bool editable = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: Icon(icon, color: Colors.grey),
        title: editable
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: label,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
      ),
    );
  }
}
