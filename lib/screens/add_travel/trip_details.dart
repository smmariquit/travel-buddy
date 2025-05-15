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
import 'package:travel_app/utils/constants.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:travel_app/widgets/bottom_navigation_bar.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isLoading = true;
  final GlobalKey qrKey = GlobalKey();


  @override
void initState() {
  super.initState();
  print('Travel debug - id: ${widget.travel.id}, id: ${widget.travel.id}');
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

  Future<void> _loadTravelData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the latest travel data from Firestore to ensure we have the most up-to-date info
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('travel')
              .doc(widget.travel.id)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          // Update the travel object with the latest data
          final updatedTravel = Travel.fromJson(data, widget.travel.id);

          setState(() {
            // Update activities with the ones from Firestore
            widget.travel.activities = updatedTravel.activities;
            widget.travel.imageUrl = updatedTravel.imageUrl;
            _coverImageUrl = updatedTravel.imageUrl;
          });
        }
        
      }

      // After fetching the latest data, make sure we have activities
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

  void _generateEmptyActivities() {
    if (widget.travel.activities == null || widget.travel.activities!.isEmpty) {
      int days = 1;
      if (widget.travel.endDate != null && widget.travel.startDate != null) {
        days = widget.travel.endDate!.difference(widget.travel.startDate!).inDays + 1;
    }
      widget.travel.activities = List.generate(days, (i) {
        final date = widget.travel.startDate!.add(Duration(days: i));
        return Activity(
          title: "Day ${i + 1} - ${date.toLocal().toString().split(' ')[0]}",
          startDate: date,
          checklist: [],
          notes: '',
          imageUrl: null,
        );
      });
      _saveActivitiesToFirestore();
    }
  }

  Future<void> _loadCoverImageUrl() async {
    if (widget.travel.imageUrl != null && widget.travel.imageUrl!.isNotEmpty) {
      setState(() {
        _coverImageUrl = widget.travel.imageUrl;
      });
      return;
    }

    final travelId = widget.travel.id;
    try {
      final ref = FirebaseStorage.instance.ref('cover_images/${travelId}.jpg');
      final url = await ref.getDownloadURL();
      setState(() {
        _coverImageUrl = url;
        widget.travel.imageUrl = url;
      });
    } catch (e) {
      print('Error fetching cover image URL: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final travelId = widget.travel.id;
    final storageRef = FirebaseStorage.instance.ref().child(
      'cover_images/$travelId.jpg',
    );

    try {
      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('travel')
          .doc(travelId)
          .update({'imageUrl': imageUrl});

      // Update local state
      setState(() {
        _coverImage = file;
        _coverImageUrl = imageUrl;
        widget.travel.imageUrl = imageUrl;
      });
    } catch (e) {
      print('Upload failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload cover image')));
    }
  }

  void _addChecklistItem(int index) {
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
                      () => widget.travel.activities![index].checklist!.add(
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
  }

  Future<void> _saveActivitiesToFirestore() async {
    if (widget.travel.id == null) return;

    try {
      // Convert each Activity object to a Map using the toJson method
      final List<Map<String, dynamic>> activitiesData =
          widget.travel.activities
              ?.map((activity) => activity.toJson())
              .toList() ??
          [];

      // Print for debugging
      print(
        'Saving activities to Firestore: ${activitiesData.length} activities',
      );

      // Debug: check imageUrls before saving
      for (int i = 0; i < activitiesData.length; i++) {
        print('Activity $i imageUrl: ${activitiesData[i]['imageUrl']}');
      }

      // Update Firestore with the properly formatted activities data
      await FirebaseFirestore.instance
          .collection('travel')
          .doc(widget.travel.id)
          .update({'activities': activitiesData});

      print('Activities saved successfully to Firestore');
    } catch (e) {
      // print('Error saving activities to Firestore: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to save activities: ${e.toString()}')),
      // );
    }
  }

  Future<void> _pickAndUploadImage(int index) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final travelId = widget.travel.id;
    if (travelId == null) return;

    // Add unique name with travel ID and activity index
    final filename = '${travelId}_activity_${index}.jpg';
    final ref = FirebaseStorage.instance.ref().child(
      'itinerary_images/$filename',
    );

    // Show loading indicator
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Uploading activity image...')));

    try {
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // Create a new Activity instance with updated imageUrl to ensure proper serialization
      final Activity updatedActivity = Activity(
        title: widget.travel.activities![index].title,
        startDate: widget.travel.activities![index].startDate,
        endDate: widget.travel.activities![index].endDate,
        place: widget.travel.activities![index].place,
        time: widget.travel.activities![index].time,
        notes: widget.travel.activities![index].notes,
        imageUrl: imageUrl,
        checklist: widget.travel.activities![index].checklist,
      );

      // Update the activity in the travel object
      setState(() {
        widget.travel.activities![index] = updatedActivity;
      });

      // Save the updated activity to Firestore
      await _saveActivitiesToFirestore();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity image uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
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
                      initialDate: widget.travel.startDate ?? DateTime.now(),
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
                      widget.travel.activities ??= [];
                      widget.travel.activities!.add(
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
      Rect.fromLTWH(0, 0, qrImage.width.toDouble(), qrImage.height.toDouble()),
      paint,
    );

    // Draw the QR image on top of white background
    canvas.drawImage(qrImage, Offset.zero, Paint());

    // End recording and create final image
    final picture = recorder.endRecording();
    final imgWithWhiteBg = await picture.toImage(qrImage.width, qrImage.height);

    // Convert to bytes
    final byteData = await imgWithWhiteBg.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: "qr_code_white_bg_${DateTime.now().millisecondsSinceEpoch}",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Code to gallery!')),
      );
    }
  } catch (e) {
    print('Error saving QR code: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save QR code.')),
    );
  }
}

void showQRDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Your QR Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.travel.id.isNotEmpty) // Use id property instead of uid
            RepaintBoundary(
              key: qrKey,
              child: Container(
                color: Colors.white, // Ensure white background for QR code
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
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
        title: Text(widget.travel.name),
        backgroundColor: Color(0xFF2E7D32),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Overview'), Tab(text: 'Itineraries')],
        ),
        actions: [
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Cover Image',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: _pickCoverImage,
                          child: Container(
                            margin: EdgeInsets.only(top: 10),
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              image:
                                  _coverImage != null
                                      ? DecorationImage(
                                        image: FileImage(_coverImage!),
                                        fit: BoxFit.cover,
                                      )
                                      : _coverImageUrl != null
                                      ? DecorationImage(
                                        image: NetworkImage(_coverImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                (_coverImage == null && _coverImageUrl == null)
                                    ? Center(
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                    : null,
                          ),
                        ),

                        Text(
                          'Destination: ${widget.travel.location}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start Date: ${widget.travel.startDate?.toLocal().toString().split(" ")[0]}',
                        ),
                        Text(
                          'End Date: ${widget.travel.endDate != null ? widget.travel.endDate!.toLocal().toString().split(' ')[0] : '—'}',
                        ),

                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: showQRDialog,
                          icon: Icon(Icons.qr_code),
                          label: Text("Generate QR Code"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        widget.travel.activities == null ||
                                widget.travel.activities!.isEmpty
                            ? Center(child: Text("No itineraries found."))
                            : ListView.builder(
                              itemCount: widget.travel.activities!.length,
                              itemBuilder:
                                  (context, index) => buildItineraryCard(
                                    widget.travel.activities![index],
                                    index,
                                  ),
                            ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1),
      floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
      floatingActionButton:
          FloatingActionButton(
                onPressed: _addManualItinerary,
                backgroundColor: Colors.green.shade700,
                child: Icon(Icons.add),
                tooltip: 'Add Itinerary',
              )
    );
  }
}
