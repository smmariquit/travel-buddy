import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';

// TO DO: AFTER EDITING THE PROFILE, HINDI NAGA-UPDATE SA
//MAIN PAGE YUNG FIRSTNAME SA APPBAR UNTIL PINDUTIN ULIT YUNG HOME BUTTON

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool isTapped = false;
  AppUser? _currentUserData;

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

            setState(() {
              _currentUserData = user;
              _firstNameController.text = user.firstName;
              _lastNameController.text = user.lastName;
              _phoneController.text = user.phoneNumber ?? '';
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
    super.dispose();
  }

  void _saveChanges() async {
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      provider.loadUserStream(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Stack(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/placeholderpfp.jpg',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isTapped = !isTapped;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color:
                                isTapped         // pangcheck lang wahahaha if napipindot since wala pa functionality
                                    ? Colors.green
                                    : Colors.white, 
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Center(
                child: Column(
                  children: [
                    Text(
                      _currentUserData!.username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentUserData!.email,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'First name required'
                            : null,
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Last name required'
                            : null,
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 10),

              ElevatedButton(onPressed: _saveChanges, child: Text("Save")),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar()
    );
  }
}
