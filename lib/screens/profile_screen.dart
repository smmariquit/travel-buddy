import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
          final doc = await FirebaseFirestore.instance.collection('appUsers').doc(uid).get();

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("User Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'First name required' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Last name required' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                initialValue: _currentUserData!.username,
                decoration: const InputDecoration(labelText: 'Username'),
                enabled: false,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),

              TextFormField(
                initialValue: _currentUserData!.email,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
