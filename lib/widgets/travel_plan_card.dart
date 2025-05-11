import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_plan_model.dart';
import '../screens/add_travel/trip_details.dart';

class TravelPlanCard extends StatelessWidget {
  final String travelId;
  final String uid;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdOn;
  final String location;
  final String image;

  TravelPlanCard({
    super.key,
    required this.travelId,
    required this.uid,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.createdOn,
    required this.image,
  });

  Future<Travel> _fetchCompleteTravel() async {
    try {
      // Get the complete travel document from Firestore
      final travelDoc = await FirebaseFirestore.instance
          .collection('travel')
          .doc(travelId)
          .get();
      
      if (travelDoc.exists) {
        // Create a Travel object from the complete Firestore document
        return Travel.fromJson(travelDoc.data()!, travelDoc.id);
      } else {
        throw Exception('Travel document not found.');
      }
    } catch (e) {
      print('Error fetching complete travel data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Show loading indicator
        final BuildContext dialogContext = context;
        showDialog(
          context: dialogContext,
          barrierDismissible: false,
          builder: (BuildContext context) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        );

        try {
          // Fetch the complete travel data with timeout to prevent indefinite loading
          final completeTravel = await _fetchCompleteTravel().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timeout. Please try again.');
            },
          );
          
          // Safely close loading indicator if context is still valid
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
          
          // Safely navigate if context is still valid
          if (dialogContext.mounted) {
            Navigator.push(
              dialogContext,
              MaterialPageRoute(
                builder: (context) => TripDetails(travel: completeTravel),
              ),
            );
          }
        } catch (e) {
          // Safely close loading indicator if context is still valid
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
          
          // Show error message
          if (dialogContext.mounted) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text('Error loading travel details: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          print('Error in TravelPlanCard tap: $e');
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 200,
                width: 200,
                child: image.startsWith('assets/')
                  ? Image.asset(
                      image,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Image.asset(
                          'assets/sample_image.jpg', // Fallback to a default image
                          fit: BoxFit.cover,
                        );
                      },
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: $location',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start Date: ${_formatDate(startDate)}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'End Date: ${_formatDate(endDate)}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}