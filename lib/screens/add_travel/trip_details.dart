// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:travel_app/utils/constants.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';

class TripDetails extends StatefulWidget {
  final Travel travel;

  const TripDetails({super.key, required this.travel});

  @override
  // ignore: library_private_types_in_public_api
  _TripDetailsState createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails>
    with SingleTickerProviderStateMixin {
  File? _coverImage;
  String? _coverImageUrl;
  final picker = ImagePicker();
  late TabController _tabController;
  bool _isLoading = true;
  late Travel updatedTravel;
  final GlobalKey qrKey = GlobalKey();
  Travel? _travel;
  final _usernameController = TextEditingController();
  late bool hasFriends;
  final _errorMessage = ValueNotifier<String?>(null);

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

  // Add method to update notification days
  Future<void> _updateNotificationDays(int days) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('travel')
          .doc(_travel!.id)
          .update({'notificationDays': days});

      // Update local state
      setState(() {
        _travel = _travel!.copyWith(notificationDays: days);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification settings updated! You\'ll be notified $days days before your trip.',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update notification settings: $e',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
        ),
      );
    }
  }

  Future<void> _loadTravelData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('travel')
              .doc(_travel!.id)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          updatedTravel = Travel.fromJson(data, _travel!.id);
          setState(() {
            _travel = _travel!.copyWith(
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
              notificationDays: updatedTravel.notificationDays,
            );
            _coverImageUrl = updatedTravel.imageUrl;
          });
        }
      }

      _generateEmptyActivities();
      _loadCoverImageUrl();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveActivitiesToFirestore() async {
    try {
      final List<Map<String, dynamic>> activitiesData =
          _travel!.activities?.map((activity) => activity.toJson()).toList() ??
          [];

      await FirebaseFirestore.instance
          .collection('travel')
          .doc(_travel!.id)
          .update({'activities': activitiesData});
    } catch (e) {}
  }

  void _generateEmptyActivities() {
    if (_travel!.activities == null || _travel!.activities!.isEmpty) {
      int days = 1;
      if (_travel!.endDate != null && _travel!.startDate != null) {
        days = _travel!.endDate!.difference(_travel!.startDate!).inDays + 1;
      }
      _travel = _travel!.copyWith(
        activities: List.generate(days, (i) {
          final date = _travel!.startDate!.add(Duration(days: i));
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
    if (_travel!.imageUrl != null && _travel!.imageUrl!.isNotEmpty) {
      setState(() {
        _coverImageUrl = _travel!.imageUrl;
      });
      return;
    }

    try {
      final ref = FirebaseStorage.instance.ref(
        'cover_images/${_travel!.id}.jpg',
      );
      final url = await ref.getDownloadURL();
      setState(() {
        _coverImageUrl = url;
        _travel = _travel!.copyWith(imageUrl: url);
      });
    } catch (e) {}
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance.ref().child(
      'cover_images/${_travel!.id}.jpg',
    );

    try {
      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('travel')
          .doc(_travel!.id)
          .update({'imageUrl': imageUrl});

      setState(() {
        _coverImage = file;
        _coverImageUrl = imageUrl;
        _travel = _travel!.copyWith(imageUrl: imageUrl);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload cover image'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
      }
    }
  }

  void _addChecklistItem(int index) {
    if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid) {
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
                      setState(() {
                        _travel!.activities![index].checklist ??= [];
                        _travel!.activities![index].checklist!.add({
                          'text': controller.text.trim(),
                          'checked': false,
                        });
                      });

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
        const SnackBar(content: Text('You cannot edit shared travel plans.')),
      );
    }
  }

  Future<void> _pickAndUploadImage(int index) async {
    if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      final filename = '${_travel!.id}_activity_$index.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'itinerary_images/$filename',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading activity image...'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.zero,
          ),
        );
      }

      try {
        await ref.putFile(file);
        final imageUrl = await ref.getDownloadURL();

        final Activity updatedActivity = Activity(
          title: _travel!.activities![index].title,
          startDate: _travel!.activities![index].startDate,
          endDate: _travel!.activities![index].endDate,
          place: _travel!.activities![index].place,
          time: _travel!.activities![index].time,
          notes: _travel!.activities![index].notes,
          imageUrl: imageUrl,
          checklist: _travel!.activities![index].checklist,
        );

        setState(() {
          _travel!.activities![index] = updatedActivity;
        });

        await _saveActivitiesToFirestore();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Activity image uploaded successfully'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.zero,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload failed: $e"),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.zero,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot edit shared travel plans.')),
      );
    }
  }

  Widget _buildNotificationSettings() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Notification Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
              SizedBox(height: 16),
            if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
              Text(
                'When do you want to be notified about this trip?',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            SizedBox(height: 12),

            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Create slider for days selection
                    Row(
                      children: [
                        Text('1', style: GoogleFonts.poppins()),
                        Expanded(
                          child: Slider(
                            value: _travel!.notificationDays.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: _travel!.notificationDays.toString(),
                            onChanged: (value) {
                              setState(() {
                                _travel = _travel!.copyWith(
                                  notificationDays: value.round(),
                                );
                              });
                            },
                            onChangeEnd: (value) {
                              _updateNotificationDays(value.round());
                            },
                          ),
                        ),
                        Text('30', style: GoogleFonts.poppins()),
                      ],
                    ),
                    if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
                      SizedBox(height: 8),
                    if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
                      Text(
                        'You will be notified ${_travel!.notificationDays} day${_travel!.notificationDays > 1 ? "s" : ""} before your trip starts',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
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
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(child: Icon(Icons.error)),
                    );
                  },
                ),
              ),
            if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
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
            ...activity.checklist!.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: entry.value['checked'] as bool? ?? false,
                      onChanged:
                          (_travel!.uid ==
                                  FirebaseAuth.instance.currentUser?.uid)
                              ? (bool? value) async {
                                setState(() {
                                  activity.checklist![entry.key]['checked'] =
                                      value ?? false;
                                });
                                await _saveActivitiesToFirestore();
                              }
                              : null,
                    ),
                    Expanded(
                      child: Text(
                        entry.value['text'] as String,
                        style: TextStyle(
                          decoration:
                              (entry.value['checked'] as bool? ?? false)
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                    ),
                    if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          setState(() {
                            activity.checklist!.removeAt(entry.key);
                          });
                          await _saveActivitiesToFirestore();
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
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
                      initialDate: _travel!.startDate ?? DateTime.now(),
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
                      _travel!.activities ??= [];
                      _travel!.activities!.add(
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
        byteData.buffer.asUint8List();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR Code to gallery!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR code.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.zero,
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
        title: Text(_travel!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Overview'), Tab(text: 'Itineraries')],
        ),
        actions: [
          if (_travel!.uid == FirebaseAuth.instance.currentUser?.uid)
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
                                  _travel!.location,
                                ),
                                SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Start Date',
                                  DateFormat(
                                    'EEEE, MMM d, yyyy',
                                  ).format(_travel!.startDate!),
                                ),
                                SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'End Date',
                                  _travel!.endDate != null
                                      ? DateFormat(
                                        'EEEE, MMM d, yyyy',
                                      ).format(_travel!.endDate!)
                                      : 'Not set',
                                ),
                                if (_travel!.flightDetails?.isNotEmpty ??
                                    false) ...[
                                  SizedBox(height: 8),
                                  _buildDetailRow(
                                    Icons.flight,
                                    'Flight Details',
                                    _travel!.flightDetails!,
                                  ),
                                ],
                                if (_travel!.accommodation?.isNotEmpty ??
                                    false) ...[
                                  SizedBox(height: 8),
                                  _buildDetailRow(
                                    Icons.hotel,
                                    'Accommodation',
                                    _travel!.accommodation!,
                                  ),
                                ],
                                if (_travel!.notes?.isNotEmpty ?? false) ...[
                                  SizedBox(height: 8),
                                  _buildDetailRow(
                                    Icons.note,
                                    'Notes',
                                    _travel!.notes!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        if (_travel!.uid ==
                            FirebaseAuth.instance.currentUser?.uid)
                          _buildNotificationSettings(),

                        // Share buttons (only for trip owner)
                        if (_travel!.uid ==
                            FirebaseAuth.instance.currentUser?.uid)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // Shared Users Section
                                if (_travel!.sharedWith != null &&
                                    _travel!.sharedWith!.isNotEmpty)
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
                                  onPressed: () async {
                                    if (await userHasFriends()) {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Share by Username',
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller:
                                                        _usernameController,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Username',
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Add error message display
                                                  ValueListenableBuilder<
                                                    String?
                                                  >(
                                                    valueListenable:
                                                        _errorMessage,
                                                    builder: (
                                                      context,
                                                      error,
                                                      child,
                                                    ) {
                                                      if (error == null)
                                                        return SizedBox.shrink();
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 16.0,
                                                            ),
                                                        child: Text(
                                                          error,
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final username =
                                                          _usernameController
                                                              .text
                                                              .trim();
                                                      if (username.isEmpty) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Please enter a username',
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      try {
                                                        // Clear any previous error
                                                        _errorMessage.value =
                                                            null;

                                                        // First check if user exists
                                                        final userQuery =
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'appUsers',
                                                                )
                                                                .where(
                                                                  'username',
                                                                  isEqualTo:
                                                                      username,
                                                                )
                                                                .get();

                                                        if (userQuery
                                                            .docs
                                                            .isEmpty) {
                                                          _errorMessage.value =
                                                              'User not found';
                                                          return;
                                                        }

                                                        final targetUserId =
                                                            userQuery
                                                                .docs
                                                                .first
                                                                .id;

                                                        // Check if they are friends
                                                        final targetUserDoc =
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'appUsers',
                                                                )
                                                                .doc(
                                                                  targetUserId,
                                                                )
                                                                .get();

                                                        final currentUserId =
                                                            FirebaseAuth
                                                                .instance
                                                                .currentUser
                                                                ?.uid;
                                                        if (currentUserId ==
                                                            null) {
                                                          _errorMessage.value =
                                                              'You must be logged in to share';
                                                          return;
                                                        }

                                                        final isFriend =
                                                            targetUserDoc
                                                                .data()?['friendUIDs']
                                                                ?.contains(
                                                                  currentUserId,
                                                                ) ??
                                                            false;

                                                        if (!isFriend) {
                                                          _errorMessage.value =
                                                              '${username} is not a friend';
                                                          return;
                                                        }

                                                        // If they are friends, share the travel plan
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'travel',
                                                            )
                                                            .doc(_travel!.id)
                                                            .update({
                                                              'sharedWith':
                                                                  FieldValue.arrayUnion([
                                                                    targetUserId,
                                                                  ]),
                                                            });
                                                        setState(() {
                                                          _travel = _travel!
                                                              .copyWith(
                                                                sharedWith: [
                                                                  ..._travel!
                                                                      .sharedWith!,
                                                                  targetUserId,
                                                                ],
                                                              );
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
                                                            margin:
                                                                EdgeInsets.zero,
                                                          ),
                                                        );
                                                        Navigator.pop(context);
                                                      } catch (e) {
                                                        _errorMessage.value =
                                                            'Failed to share travel plan: ${e.toString()}';
                                                      }
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text('Share'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Text(
                                                'No friends to share with',
                                              ),
                                              content: Text(
                                                'Please add friends to share with',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: Text('OK'),
                                                ),
                                              ],
                                            ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Share by Username'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
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
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
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
                        if (_travel!.uid ==
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
                                                  .deleteTravelPlan(
                                                    _travel!.id,
                                                  );

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
                        _travel!.activities == null ||
                                _travel!.activities!.isEmpty
                            ? Center(child: Text("No itineraries found."))
                            : ListView.builder(
                              itemCount: _travel!.activities!.length,
                              itemBuilder:
                                  (context, index) => buildItineraryCard(
                                    _travel!.activities![index],
                                    index,
                                  ),
                            ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1),
      floatingActionButton:
          _travel!.uid == FirebaseAuth.instance.currentUser?.uid
              ? FloatingActionButton(
                onPressed: _addManualItinerary,
                backgroundColor: primaryColor,
                tooltip: 'Add Itinerary',
                child: const Icon(Icons.playlist_add_check),
              )
              : null,
      floatingActionButtonLocation:
          _travel!.uid == FirebaseAuth.instance.currentUser?.uid
              ? FloatingActionButtonLocation.centerDocked
              : null,
    );
  }

  Future<List<Map<String, dynamic>>> _getSharedUsersInfo() async {
    if (_travel!.sharedWith == null || _travel!.sharedWith!.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> usersInfo = [];
    for (String uid in _travel!.sharedWith!) {
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
      } catch (e) {}
    }
    return usersInfo;
  }

  Future<void> _removeSharedUser(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('travel')
          .doc(_travel!.id)
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

  Future<void> _editTravelPlan() async {
    final nameController = TextEditingController(text: _travel!.name);
    final locationController = TextEditingController(text: _travel!.location);
    final notesController = TextEditingController(text: _travel!.notes);
    final flightController = TextEditingController(
      text: _travel!.flightDetails,
    );
    final accommodationController = TextEditingController(
      text: _travel!.accommodation,
    );

    DateTime? startDate = _travel!.startDate;
    DateTime? endDate = _travel!.endDate;

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
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
                        // Start Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = picked;
                                // If end date is before new start date, update it
                                if (endDate != null &&
                                    endDate!.isBefore(picked)) {
                                  endDate = picked;
                                }
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              startDate != null
                                  ? DateFormat(
                                    'EEEE, MMM d, yyyy',
                                  ).format(startDate!)
                                  : 'Select Date',
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        // End Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  endDate ?? startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                endDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              endDate != null
                                  ? DateFormat(
                                    'EEEE, MMM d, yyyy',
                                  ).format(endDate!)
                                  : 'Select Date',
                            ),
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
                          final updatedTravel = _travel!.copyWith(
                            name: nameController.text.trim(),
                            location: locationController.text.trim(),
                            notes: notesController.text.trim(),
                            flightDetails: flightController.text.trim(),
                            accommodation: accommodationController.text.trim(),
                            startDate: startDate,
                            endDate: endDate,
                          );

                          await FirebaseFirestore.instance
                              .collection('travel')
                              .doc(_travel!.id)
                              .update(updatedTravel.toJson());

                          await _loadTravelData();

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Travel plan updated successfully',
                                ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<bool> userHasFriends() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();

    final friends = userDoc.data()?['friendUIDs'];
    return friends != null && friends is List && friends.isNotEmpty;
  }
}
