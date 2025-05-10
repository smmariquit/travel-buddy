import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/travel_plan_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TripDetails extends StatefulWidget {
  final Travel travel;

  TripDetails({Key? key, required this.travel}) : super(key: key);

  @override
  _TripDetailsState createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> with SingleTickerProviderStateMixin {
  File? _coverImage;
  final picker = ImagePicker();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _generateEmptyActivities();
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

  void _generateEmptyActivities() {
    if (widget.travel.activities == null || widget.travel.activities!.isEmpty) {
      final days = widget.travel.endDate!.difference(widget.travel.startDate!).inDays + 1;
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
      setState(() {}); // Refresh UI
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _coverImage = File(pickedFile.path));
    }
  }

  void _addChecklistItem(int index) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Checklist Item"),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: "Enter item")),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => widget.travel.activities![index].checklist!.add(controller.text.trim()));
              }
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(int index) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('itinerary_images/$filename');

    try {
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();
      setState(() => widget.travel.activities![index].imageUrl = imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
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
            Text(activity.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (activity.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(activity.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            TextButton.icon(
              onPressed: () => _pickAndUploadImage(index),
              icon: Icon(Icons.upload, color: Colors.green.shade700),
              label: Text('Upload Image', style: TextStyle(color: Colors.green.shade700)),
            ),
            const SizedBox(height: 10),
            Text("Checklist:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...activity.checklist!.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(children: [
                Icon(Icons.check_box_outline_blank, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(item)),
              ]),
            )),
            TextButton.icon(
              onPressed: () => _addChecklistItem(index),
              icon: Icon(Icons.add, color: Colors.green.shade700),
              label: Text("Add Checklist Item", style: TextStyle(color: Colors.green.shade700)),
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
      builder: (context) => AlertDialog(
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
            onPressed: () {
              if (selectedDate != null && titleController.text.trim().isNotEmpty) {
                setState(() {
                  widget.travel.activities!.add(Activity(
                    title: titleController.text.trim(),
                    startDate: selectedDate!,
                    checklist: [],
                    notes: '',
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.travel.name),
        backgroundColor: Color(0xFF2E7D32),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Overview'), Tab(text: 'Itineraries')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trip Cover Image', style: TextStyle(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _pickCoverImage,
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: _coverImage != null
                          ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _coverImage == null
                        ? Center(child: Icon(Icons.camera_alt, color: Colors.grey[600]))
                        : null,
                  ),
                ),

                Text('Destination: ${widget.travel.location}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Start Date: ${widget.travel.startDate?.toLocal().toString().split(" ")[0]}'),
                Text('End Date: ${widget.travel.endDate?.toLocal().toString().split(" ")[0]}'),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Your QR Code'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ( widget.travel.uid != null)
                              SizedBox(
                                height: 200.0,
                                width: 200.0,
                                child: QrImageView(
                                  data:  widget.travel.uid!,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                ),
                              ),
                            SizedBox(height: 10),
                            if ( widget.travel.uid != null)
                              Text(
                                "Add friends to your travel",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.qr_code),
                  label: Text("Generate QR Code"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: widget.travel.activities == null || widget.travel.activities!.isEmpty
                ? Center(child: Text("No itineraries found."))
                : ListView.builder(
                    itemCount: widget.travel.activities!.length,
                    itemBuilder: (context, index) =>
                        buildItineraryCard(widget.travel.activities![index], index),
                  ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _addManualItinerary,
              backgroundColor: Colors.green.shade700,
              child: Icon(Icons.add),
              tooltip: 'Add Itinerary',
            )
          : null,
    );
  }
}
