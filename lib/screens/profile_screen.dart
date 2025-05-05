import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';


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
    {"style": 'Backpacker', "selected": false},
    {"style": 'Luxury', "selected": false},
    {"style": 'Adventure', "selected": false},
    {"style": 'Cultural', "selected": false},
    {"style": 'Business', "selected": false}
  ];

  AppUser? _currentUserData;
  bool _isTapped = false;
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
        final doc = await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final user = AppUser.fromJson(data);

          // Master lists
          final masterInterests = [
            'Adventure', 'Culture', 'Food', 'Nature',
            'Relaxation', 'Shopping', 'Sightseeing', 'Sports'
          ];

          final masterStyles = [
            'Backpacker', 'Luxury', 'Adventure',
            'Cultural', 'Business'
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

      // Save interests and travel styles
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
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar + Username
              Center(
                child: Stack(
                  children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: _currentUserData!.profileImageUrl != ''
                          ? MemoryImage(base64Decode(_currentUserData!.profileImageUrl!))
                          : const AssetImage('assets/default_avatar.jpg') as ImageProvider,

                      ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _isTapped = !_isTapped;
                          });

                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            final base64Image = base64Encode(bytes);

                            final provider = context.read<AppUserProvider>();
                            final uid = _currentUserData!.uid;

                            await provider.editProfileImageUrl(uid, base64Image);
                            provider.loadUserStream(uid); // refresh data

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
                          radius: 18,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.camera_alt,
                            color: _isTapped ? Colors.green : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                _currentUserData!.username,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _currentUserData!.email,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // Editable Fields
              _buildProfileInputField(
                label: "First Name",
                controller: _firstNameController,
                validatorMsg: "First name required",
              ),
              const SizedBox(height: 15),

              _buildProfileInputField(
                label: "Last Name",
                controller: _lastNameController,
                validatorMsg: "Last name required",
              ),
              const SizedBox(height: 15),

              _buildProfileInputField(
                label: "Phone Number",
                controller: _phoneController,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              _buildProfileInputField(
                label: "Location",
                controller: _locationController,
              ),
              const SizedBox(height: 30),

              // Interests Chips
              Text('Select your Interests'),
              Wrap(
                spacing: 10,
                children: List.generate(_interests.length, (index) {
                  return InputChip(
                    label: Text(_interests[index]['interest']),
                    selected: _interests[index]['selected'],
                    onPressed: () {
                      setState(() {
                        _interests[index]['selected'] = !_interests[index]['selected'];
                      });
                    },
                    selectedColor: Colors.blue,
                  );
                }),
              ),
              const SizedBox(height: 30),

              // Travel Styles Chips
              Text('Select your Travel Styles'),
              Wrap(
                spacing: 10,
                children: List.generate(_travelStyles.length, (index) {
                  return InputChip(
                    label: Text(_travelStyles[index]['style']),
                    selected: _travelStyles[index]['selected'],
                    onPressed: () {
                      setState(() {
                        _travelStyles[index]['selected'] = !_travelStyles[index]['selected'];
                      });
                    },
                    selectedColor: Colors.blue,
                  );
                }),
              ),
              const SizedBox(height: 30),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInputField({
    required String label,
    required TextEditingController controller,
    String? validatorMsg,
    TextInputType? inputType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validatorMsg != null
          ? (value) => value == null || value.isEmpty ? validatorMsg : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
