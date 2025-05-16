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
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/screens/view_all_plans.dart';
import 'package:travel_app/utils/constants.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class TripDetails extends StatefulWidget {
  final Travel travel;

  TripDetails({Key? key, required this.travel}) : super(key: key);

  @override
  _TripDetailsState createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails>
    with SingleTickerProviderStateMixin {
  File? _coverImage;
  String? _coverImageUrl;
  final picker = ImagePicker();
  late TabController _tabController;
  TravelTrackerProvider? _travelPlansProvider;
  bool _isLoading = true;
  final GlobalKey qrKey = GlobalKey();
  late Travel _travel;
  final _usernameController = TextEditingController();

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _travel = widget.travel;
    _loadTravelData();
    _travelPlansProvider = TravelTrackerProvider();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTravelData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('travel')
              .doc(_travel.id)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          final updatedTravel = Travel.fromJson(data, _travel.id);
          setState(() {
            _travel = _travel.copyWith(
              name: updatedTravel.name,
              location: updatedTravel.location,
              startDate: updatedTravel.startDate,
              endDate: updatedTravel.endDate,
              flightDetails: updatedTravel.flightDetails,
              accommodation: updatedTravel.accommodation,
              notes: updatedTravel.notes,
              activities: updatedTravel.activities,
              imageUrl: updatedTravel.imageUrl,
              sharedWith: updatedTravel.sharedWith,
            );
            _coverImageUrl = updatedTravel.imageUrl;
          });
        }
      }

      _generateEmptyActivities();
      _loadCoverImageUrl();
    } catch (e) {
      print('Error loading travel data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveActivitiesToFirestore() async {
    if (_travel.id == null) return;

    try {
      final List<Map<String, dynamic>> activitiesData =
          _travel.activities?.map((activity) => activity.toJson()).toList() ??
          [];

      await FirebaseFirestore.instance
          .collection('travel')
          .doc(_travel.id)
          .update({'activities': activitiesData});
    } catch (e) {
      print('Error saving activities to Firestore: $e');
    }
  }

  void _generateEmptyActivities() {
    if (_travel.activities == null || _travel.activities!.isEmpty) {
      int days = 1;
      if (_travel.endDate != null && _travel.startDate != null) {
        days = _travel.endDate!.difference(_travel.startDate!).inDays + 1;
      }
      _travel = _travel.copyWith(
        activities: List.generate(days, (i) {
          final date = _travel.startDate!.add(Duration(days: i));
          return Activity(
            title: "Day ${i + 1} - ${date.toLocal().toString().split(' ')[0]}",
            startDate: date,
            checklist: [],
            notes: '',
            imageUrl: null,
          );
        }),
      );
      _saveActivitiesToFirestore();
    }
  }

  Future<void> _loadCoverImageUrl() async {
    if (_travel.imageUrl != null && _travel.imageUrl!.isNotEmpty) {
      setState(() {
        _coverImageUrl = _travel.imageUrl;
      });
      return;
    }

    try {
      final ref = FirebaseStorage.instance.ref(
        'cover_images/${_travel.id}.jpg',
      );
      final url = await ref.getDownloadURL();
      setState(() {
        _coverImageUrl = url;
        _travel = _travel.copyWith(imageUrl: url);
      });
    } catch (e) {
      print('Error fetching cover image URL: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance.ref().child(
      'cover_images/${_travel.id}.jpg',
    );

    try {
      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('travel')
          .doc(_travel.id)
          .update({'imageUrl': imageUrl});

      setState(() {
        _coverImage = file;
        _coverImageUrl = imageUrl;
        _travel = _travel.copyWith(imageUrl: imageUrl);
      });
    } catch (e) {
      print('Upload failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload cover image'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.15,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    }
  }

  void _addChecklistItem(int index) {
    if (_travel.uid == FirebaseAuth.instance.currentUser?.uid) {
    final controller = TextEditingController();
    

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Add Checklist Item"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: "Enter item"),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    setState(
                      () => _travel.activities![index].checklist!.add(
                        controller.text.trim(),
                      ),
                    );

                    // Save to Firestore after adding the checklist item
                    await _saveActivitiesToFirestore();
                  }
                  Navigator.pop(context);
                },
                child: Text("Add"),
              ),
            ],
          ),
    );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot edit shared travel plans.'),
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage(int index) async {
    if (_travel.uid == FirebaseAuth.instance.currentUser?.uid) {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    if (_travel.id == null) return;

    final filename = '${_travel.id}_activity_${index}.jpg';
    final ref = FirebaseStorage.instance.ref().child(
      'itinerary_images/$filename',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading activity image...'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 16,
            right: 16,
          ),
        ),
      );
    }

    try {
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      final Activity updatedActivity = Activity(
        title: _travel.activities![index].title,
        startDate: _travel.activities![index].startDate,
        endDate: _travel.activities![index].endDate,
        place: _travel.activities![index].place,
        time: _travel.activities![index].time,
        notes: _travel.activities![index].notes,
        imageUrl: imageUrl,
        checklist: _travel.activities![index].checklist,
      );

      setState(() {
        _travel.activities![index] = updatedActivity;
      });

      await _saveActivitiesToFirestore();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity image uploaded successfully'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.15,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text("Upload failed: $e"),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.15,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    }} else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot edit shared travel plans.'),
        ),
      );
    }
  }

  Widget buildItineraryCard(Activity activity, int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (activity.imageUrl != null && activity.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  activity.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Add error handling for network images
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(child: Icon(Icons.error)),
                    );
                  },
                ),
              ),
            TextButton.icon(
              onPressed: () => _pickAndUploadImage(index),
              icon: Icon(Icons.upload, color: Colors.green.shade700),
              label: Text(
                activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                    ? 'Change Image'
                    : 'Upload Image',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
            const SizedBox(height: 10),
            Text("Checklist:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...activity.checklist!.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Icon(Icons.check_box_outline_blank, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _addChecklistItem(index),
              icon: Icon(Icons.add, color: Colors.green.shade700),
              label: Text(
                "Add Checklist Item",
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addManualItinerary() async {
    DateTime? selectedDate;
    TextEditingController titleController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Add Custom Itinerary"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: "Title"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _travel.startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  child: Text("Pick Date"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate != null &&
                      titleController.text.trim().isNotEmpty) {
                    setState(() {
                      _travel.activities ??= [];
                      _travel.activities!.add(
                        Activity(
                          title: titleController.text.trim(),
                          startDate: selectedDate!,
                          checklist: [],
                          notes: '',
                        ),
                      );
                    });

                    // Save the new itinerary to Firestore
                    await _saveActivitiesToFirestore();
                    Navigator.pop(context);
                  }
                },
                child: Text("Add"),
              ),
            ],
          ),
    );
  }

  Future<void> saveQRToGalleryPlus() async {
    try {
      await Permission.storage.request();
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the QR widget as image
      ui.Image qrImage = await boundary.toImage(pixelRatio: 3.0);

      // Create a new picture recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Paint white background
      final paint = Paint()..color = ui.Color(0xFFFFFFFF); // White color
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          qrImage.width.toDouble(),
          qrImage.height.toDouble(),
        ),
        paint,
      );

      // Draw the QR image on top of white background
      canvas.drawImage(qrImage, Offset.zero, Paint());

      // End recording and create final image
      final picture = recorder.endRecording();
      final imgWithWhiteBg = await picture.toImage(
        qrImage.width,
        qrImage.height,
      );

      // Convert to bytes
      final byteData = await imgWithWhiteBg.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();

        final result = await ImageGallerySaverPlus.saveImage(
          pngBytes,
          quality: 100,
          name: "qr_code_white_bg_${DateTime.now().millisecondsSinceEpoch}",
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR Code to gallery!')));
      }
    } catch (e) {
      print('Error saving QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR code.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 16,
            right: 16,
          ),
        ),
      );
    }
  }

  void showQRDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Your QR Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget
                    .travel
                    .id
                    .isNotEmpty) // Use id property instead of uid
                  RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      color:
                          Colors.white, // Ensure white background for QR code
                      child: SizedBox(
                        height: 200.0,
                        width: 200.0,
                        child: QrImageView(
                          data: widget.travel.id, // Use id instead of uid
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                if (widget.travel.id.isNotEmpty)
                  Text(
                    "Add friends to your travel",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await saveQRToGalleryPlus();
                },
                child: Text("Save QR", style: TextStyle(color: primaryColor)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_travel.name),
        backgroundColor: Color(0xFF2E7D32),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Overview'), Tab(text: 'Itineraries')],
        ),
        actions: [
          if (_travel.uid == FirebaseAuth.instance.currentUser?.uid)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _editTravelPlan,
              tooltip: 'Edit travel plan',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTravelData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Overview Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Image Section
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Trip Cover Image',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickCoverImage,
                                child: Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    image:
                                        _coverImage != null
                                            ? DecorationImage(
                                              image: FileImage(_coverImage!),
                                              fit: BoxFit.cover,
                                            )
                                            : _coverImageUrl != null
                                            ? DecorationImage(
                                              image: NetworkImage(
                                                _coverImageUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                            : null,
                                  ),
                                  child:
                                      (_coverImage == null &&
                                              _coverImageUrl == null)
                                          ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.grey[600],
                                                  size: 48,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Tap to add cover image',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        
                        // SizedBox(height: 24),

                        // Trip Details Section
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trip Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildDetailRow(
                                  Icons.location_on,
                                  'Destination',
                                  _travel.location,
                                ),
                                SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Start Date',
                                  _travel.startDate?.toLocal().toString().split(
                                        " ",
                                      )[0] ??
                                      'Not set',
                                ),
                                SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'End Date',
                                  _travel.endDate != null
                                      ? _travel.endDate!
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0]
                                      : 'Not set',
                                ),
                                if (_travel.flightDetails?.isNotEmpty ??
                                    false) ...[
                                  SizedBox(height: 8),
                                  _buildDetailRow(
                                    Icons.flight,
                                    'Flight Details',
                                    _travel.flightDetails!,
                                  ),
                                ],
                                if (_travel.accommodation?.isNotEmpty ??
                                    false) ...[
                                  SizedBox(height: 8),
                                  _buildDetailRow(
                                    Icons.hotel,
                                    'Accommodation',
                                    _travel.accommodation!,
                                  ),
                                ],
                                if (_travel.notes?.isNotEmpty ?? false) ...[
                                  SizedBox(height: 8),
                                  _buildDetailRow(
                                    Icons.note,
                                    'Notes',
                                    _travel.notes!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Share buttons (only for trip owner)
                        if (_travel.uid == FirebaseAuth.instance.currentUser?.uid)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // Shared Users Section
                                if (_travel.sharedWith != null &&
                                    _travel.sharedWith!.isNotEmpty)
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Shared With',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          FutureBuilder<
                                            List<Map<String, dynamic>>
                                          >(
                                            future: _getSharedUsersInfo(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                              if (!snapshot.hasData ||
                                                  snapshot.data!.isEmpty) {
                                                return Text(
                                                  'No users shared with',
                                                );
                                              }
                                              return Column(
                                                children:
                                                    snapshot.data!
                                                        .map(
                                                          (user) => ListTile(
                                                            leading: CircleAvatar(
                                                              child: Text(
                                                                user['username'][0]
                                                                    .toUpperCase(),
                                                              ),
                                                            ),
                                                            title: Text(
                                                              user['username'],
                                                            ),
                                                            trailing: IconButton(
                                                              icon: Icon(
                                                                Icons
                                                                    .remove_circle_outline,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              onPressed:
                                                                  () => _removeSharedUser(
                                                                    user['uid'],
                                                                  ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Share by Username'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: _usernameController,
                                              decoration: const InputDecoration(
                                                labelText: 'Username',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final username = _usernameController.text.trim();
                                                if (username.isEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Please enter a username'),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                try {
                                                  final userQuery = await FirebaseFirestore.instance
                                                      .collection('appUsers')
                                                      .where('username', isEqualTo: username)
                                                      .get();

                                                  if (userQuery.docs.isEmpty) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('User not found'),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  final targetUserId = userQuery.docs.first.id;
                                                  await FirebaseFirestore.instance
                                                      .collection('travel')
                                                      .doc(_travel.id)
                                                      .update({
                                                    'sharedWith': FieldValue.arrayUnion([targetUserId]),
                                                  });

                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Travel plan shared successfully',
                                                          ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          margin: EdgeInsets.only(
                                                            bottom:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.15,
                                                            left: 16,
                                                            right: 16,
                                                          ),
                                                        ),
                                                      );
                                                      Navigator.pop(context);
                                                    } catch (e) {
                                                      print(
                                                        'Error sharing travel plan: $e',
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Failed to share travel plan',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: const Text('Share'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Share by Username'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: showQRDialog,
                                  icon: const Icon(Icons.qr_code),
                                  label: const Text("Generate QR Code"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 48),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Delete Button (only for trip owner)
                        if (_travel.uid ==
                            FirebaseAuth.instance.currentUser?.uid)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text('Delete this plan'),
                                        content: Text(
                                          'Are you sure you want to delete this plan? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final scaffoldMessenger =
                                                  ScaffoldMessenger.of(context);
                                              final navigator = Navigator.of(
                                                context,
                                              );
                                              navigator.pop();

                                              final success = await context
                                                  .read<TravelTrackerProvider>()
                                                  .deleteTravelPlan(_travel.id);

                                              if (success) {
                                                scaffoldMessenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Travel plan deleted successfully',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                                navigator.pop();
                                              } else {
                                                scaffoldMessenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Failed to delete travel plan',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                              icon: Icon(Icons.delete, color: Colors.white),
                              label: Text('Delete Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Itineraries Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        _travel.activities == null ||
                                _travel.activities!.isEmpty
                            ? Center(child: Text("No itineraries found."))
                            : ListView.builder(
                              itemCount: _travel.activities!.length,
                              itemBuilder:
                                  (context, index) => buildItineraryCard(
                                    _travel.activities![index],
                                    index,
                                  ),
                            ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1),
      floatingActionButton: _travel.uid == FirebaseAuth.instance.currentUser?.uid
          ? FloatingActionButton(
              onPressed: _addManualItinerary,
              backgroundColor: Colors.green.shade700,
              child: const Icon(Icons.add),
              tooltip: 'Add Itinerary',
            )
          : null,
      floatingActionButtonLocation:
          _travel.uid == FirebaseAuth.instance.currentUser?.uid
              ? FloatingActionButtonLocation.centerDocked
              : null,
    );
  }

  Future<List<Map<String, dynamic>>> _getSharedUsersInfo() async {
    if (_travel.sharedWith == null || _travel.sharedWith!.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> usersInfo = [];
    for (String uid in _travel.sharedWith!) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('appUsers')
                .doc(uid)
                .get();

        if (userDoc.exists) {
          usersInfo.add({
            'uid': uid,
            'username': userDoc.data()?['username'] ?? 'Unknown User',
          });
        }
      } catch (e) {
        print('Error fetching user info: $e');
      }
    }
    return usersInfo;
  }

  Future<void> _removeSharedUser(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('travel')
          .doc(_travel.id)
          .update({
            'sharedWith': FieldValue.arrayRemove([userId]),
          });

      // Refresh the travel data to update the UI
      await _loadTravelData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User removed from shared list'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showShareByUsernameDialog() async {
    final usernameController = TextEditingController();

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Share with Friend'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Enter friend\'s username',
                    hintText: 'e.g., john_doe',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final username = usernameController.text.trim();
                  if (username.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a username')),
                    );
                    return;
                  }

                  // Find user by username
                  final userQuery =
                      await FirebaseFirestore.instance
                          .collection('appUsers')
                          .where('username', isEqualTo: username)
                          .get();

                  if (userQuery.docs.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User not found'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.15,
                            left: 16,
                            right: 16,
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  final friendUid = userQuery.docs.first.id;

                  // Don't allow sharing with yourself
                  if (friendUid == FirebaseAuth.instance.currentUser?.uid) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cannot share with yourself')),
                      );
                    }
                    return;
                  }

                  // Check if already shared
                  if (_travel.sharedWith?.contains(friendUid) ?? false) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Already shared with this user'),
                        ),
                      );
                    }
                    return;
                  }

                  try {
                    // Add to sharedWith array
                    await FirebaseFirestore.instance
                        .collection('travel')
                        .doc(_travel.id)
                        .update({
                          'sharedWith': FieldValue.arrayUnion([friendUid]),
                        });

                    // Refresh the travel data
                    await _loadTravelData();

                    if (context.mounted) {
                      Navigator.pop(context); // Close the dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully shared with $username'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sharing: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _editTravelPlan() async {
    final nameController = TextEditingController(text: _travel.name);
    final locationController = TextEditingController(text: _travel.location);
    final notesController = TextEditingController(text: _travel.notes);
    final flightController = TextEditingController(text: _travel.flightDetails);
    final accommodationController = TextEditingController(
      text: _travel.accommodation,
    );

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Travel Plan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Trip Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: flightController,
                    decoration: InputDecoration(
                      labelText: 'Flight Details',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: accommodationController,
                    decoration: InputDecoration(
                      labelText: 'Accommodation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updatedTravel = _travel.copyWith(
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      notes: notesController.text.trim(),
                      flightDetails: flightController.text.trim(),
                      accommodation: accommodationController.text.trim(),
                    );

                    await FirebaseFirestore.instance
                        .collection('travel')
                        .doc(_travel.id)
                        .update(updatedTravel.toJson());

                    await _loadTravelData();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Travel plan updated successfully'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating travel plan: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }
}
