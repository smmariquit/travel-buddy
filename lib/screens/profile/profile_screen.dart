// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/models/user_model.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/profile/friends_list.dart';
import 'package:travel_app/utils/constants.dart';
import 'package:travel_app/utils/pick_profile_image.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:travel_app/utils/responsive_layout.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    {"interest": 'Sports', "selected": false},
  ];

  List<Map<String, dynamic>> _travelStyles = [
    {"style": 'Backpacking', "selected": false},
    {"style": 'Luxury Travel', "selected": false},
    {"style": 'Solo Travel', "selected": false},
    {"style": 'Family Vacation', "selected": false},
    {"style": 'Cruise', "selected": false},
    {"style": 'Road Trip', "selected": false},
    {"style": 'Eco-Tourism', "selected": false},
    {"style": 'Adventure Travel', "selected": false},
  ];

  AppUser? _currentUserData;
  bool _isPrivate = false;

  int _friendsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppUserProvider>();
      final userStream = provider.userStream;

      userStream.listen((firebaseUser) async {
        if (firebaseUser != null) {
          final uid = firebaseUser.uid;
          final doc =
              await FirebaseFirestore.instance
                  .collection('appUsers')
                  .doc(uid)
                  .get();

          if (doc.exists) {
            final data = doc.data()!;
            final user = AppUser.fromJson(data);

            final masterInterests = [
              'Adventure',
              'Culture',
              'Food',
              'Nature',
              'Relaxation',
              'Shopping',
              'Sightseeing',
              'Sports',
            ];

            final masterStyles = [
              'Backpacking',
              'Luxury Travel',
              'Solo Travel',
              "Family Vacation",
              "Cruise",
              'Road Trip',
              'Eco-Tourism',
              'Adventure Travel',
            ];

            final selectedInterests = user.interests ?? [];
            final selectedStyles = user.travelStyles ?? [];

            // Fetch friends count
            final friendsList = user.friendUIDs ?? [];
            int friendsCount = friendsList.length;

            setState(() {
              _currentUserData = user;
              _firstNameController.text = user.firstName;
              _middleNameController.text = user.middleName ?? '';
              _lastNameController.text = user.lastName;
              _phoneController.text = user.phoneNumber ?? '';
              _locationController.text = user.location ?? '';
              _isPrivate = user.isPrivate;
              _friendsCount = friendsCount;

              _interests =
                  masterInterests.map((interest) {
                    return {
                      "interest": interest,
                      "selected": selectedInterests.contains(interest),
                    };
                  }).toList();

              _travelStyles =
                  masterStyles.map((style) {
                    return {
                      "style": style,
                      "selected": selectedStyles.contains(style),
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

      List<String> selectedInterests =
          _interests
              .where((interest) => interest['selected'])
              .map<String>((interest) => interest['interest'] as String)
              .toList();

      List<String> selectedTravelStyles =
          _travelStyles
              .where((style) => style['selected'])
              .map<String>((style) => style['style'] as String)
              .toList();

      try {
        await FirebaseFirestore.instance.collection('appUsers').doc(uid).update(
          {
            'interests': selectedInterests,
            'travelStyles': selectedTravelStyles,
          },
        );
      } catch (e) {
        print("Failed to save interests and travel styles: $e");
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));

      provider.loadUserStream(uid);
      final doc =
          await FirebaseFirestore.instance
              .collection('appUsers')
              .doc(uid)
              .get();
      if (doc.exists) {
        final updatedUser = AppUser.fromJson(doc.data()!);
        setState(() {
          _currentUserData = updatedUser;
        });
      }
    }
  }

  // Navigate to Friends List Screen
  void _navigateToFriendsList() {
    if (_currentUserData == null ||
        (_currentUserData!.friendUIDs?.isEmpty ?? true)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No friends to display')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FriendsListScreen(
              friendUIDs: _currentUserData!.friendUIDs!,
              currentUserID: _currentUserData!.uid,
            ),
      ),
    );
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
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48), // To balance the back button
                    ],
                  ),
                ),
                SizedBox(height: 20),

                Card(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Profile Image
                        GestureDetector(
                          onTap: () async {
                            final source =
                                await showModalBottomSheet<ImageSource>(
                                  context: context,
                                  builder:
                                      (context) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.camera_alt,
                                              ),
                                              title: const Text('Take a photo'),
                                              onTap:
                                                  () => Navigator.pop(
                                                    context,
                                                    ImageSource.camera,
                                                  ),
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.photo_library,
                                              ),
                                              title: const Text(
                                                'Choose from gallery',
                                              ),
                                              onTap:
                                                  () => Navigator.pop(
                                                    context,
                                                    ImageSource.gallery,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                );

                            if (source == null) return;

                            final permission =
                                source == ImageSource.camera
                                    ? Permission.camera
                                    : Permission.photos;

                            final status = await permission.request();

                            if (!status.isGranted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${permission.toString().split('.').last} permission denied',
                                  ),
                                ),
                              );
                              return;
                            }

                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: source,
                            );
                            if (pickedFile == null) return;

                            final uid = _currentUserData!.uid;
                            final file = File(pickedFile.path);
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child('profile_images/$uid.jpg');

                            try {
                              await storageRef.putFile(file);
                              final imageUrl =
                                  await storageRef.getDownloadURL();
                              await FirebaseFirestore.instance
                                  .collection('appUsers')
                                  .doc(uid)
                                  .update({'profileImageUrl': imageUrl});

                              setState(() {
                                _currentUserData = _currentUserData!.copyWith(
                                  profileImageUrl: imageUrl,
                                );
                              });
                            } catch (e) {
                              print('Upload failed: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to upload image'),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                _currentUserData!.profileImageUrl != null
                                    ? NetworkImage(
                                      _currentUserData!.profileImageUrl!,
                                    )
                                    : null,
                            child:
                                _currentUserData!.profileImageUrl == null
                                    ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey[600],
                                    )
                                    : null,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Full Name
                        Text(
                          '${_currentUserData!.firstName} ${_currentUserData!.lastName}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Username
                        if (_currentUserData!.username != null) ...[
                          SizedBox(height: 4),
                          Text(
                            '@${_currentUserData!.username}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],

                        SizedBox(height: 24),

                        // User Stats Row
                        FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('travel')
                                  .where(
                                    'uid',
                                    isEqualTo: _currentUserData!.uid,
                                  )
                                  .get(),
                          builder: (context, snapshot) {
                            int travelCount = 0;
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasData) {
                                travelCount = snapshot.data!.docs.length;
                              }
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Friends Count - Now clickable
                                GestureDetector(
                                  onTap: _navigateToFriendsList,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.transparent,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$_friendsCount',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Friends',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Divider
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),

                                // Travels Count
                                Column(
                                  children: [
                                    snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.green,
                                          ),
                                        )
                                        : Text(
                                          '$travelCount',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                    Text(
                                      'Travels',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: 24),

                        // Private Profile Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Private Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _isPrivate,
                              onChanged: (value) async {
                                setState(() {
                                  _isPrivate = value;
                                });
                                await FirebaseFirestore.instance
                                    .collection('appUsers')
                                    .doc(_currentUserData!.uid)
                                    .update({'isPrivate': value});
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Profile Information Section - The existing form card
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _interests.map((interest) {
                                  return FilterChip(
                                    label: Text(interest['interest']),
                                    selected: interest['selected'],
                                    onSelected: (selected) {
                                      setState(() {
                                        interest['selected'] = selected;
                                      });
                                    },
                                    selectedColor: Colors.green,
                                    checkmarkColor: Colors.white,
                                  );
                                }).toList(),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Travel Styles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _travelStyles.map((style) {
                                  return FilterChip(
                                    label: Text(style['style']),
                                    selected: style['selected'],
                                    onSelected: (selected) {
                                      setState(() {
                                        style['selected'] = selected;
                                      });
                                    },
                                    selectedColor: Colors.green,
                                    checkmarkColor: Colors.white,
                                  );
                                }).toList(),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _saveChanges,
                            icon: Icon(Icons.save),
                            label: Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Sign Out Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text('Confirm Sign Out'),
                              content: Text(
                                'Are you sure you want to sign out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    await context
                                        .read<AppUserProvider>()
                                        .signOut();
                                    if (mounted) {
                                      Navigator.of(
                                        context,
                                      ).pushNamedAndRemoveUntil(
                                        '/signin',
                                        (route) => false,
                                      );
                                    }
                                  },
                                  child: Text('Yes'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('No'),
                                ),
                              ],
                            ),
                      );
                    },
                    icon: Icon(Icons.exit_to_app),
                    label: Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
