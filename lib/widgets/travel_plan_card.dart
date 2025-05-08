import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import '../models/travel_plan_model.dart';
import '../screens/add_travel/trip_details.dart';

class TravelPlanCard extends StatelessWidget {
  final String uid;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdOn;
  final String location; // Changed from Location to String
  final String image;

  TravelPlanCard({
    super.key,
    required this.uid,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.location, // Updated type
    required this.createdOn,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetails(
              travel: Travel(
                uid: uid,
                name: name,
                startDate: startDate,
                endDate: endDate,
                createdOn: createdOn,
                location: location, // Updated type
                activities: [], // Initialize with an empty list
              ),
            ),
          ),
        );
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
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
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
                    'Location: $location', // Updated to use string directly
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start Date: ${startDate.toLocal()}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'End Date: ${endDate.toLocal()}',
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
}