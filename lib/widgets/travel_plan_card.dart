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

  const TravelPlanCard({
    Key? key,
    required this.travelId,
    required this.uid,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.createdOn,
    required this.image,
  }) : super(key: key);

  Future<Travel> _fetchCompleteTravel() async {
    try {
      final travelDoc = await FirebaseFirestore.instance
          .collection('travel')
          .doc(travelId)
          .get();

      if (travelDoc.exists) {
        return Travel.fromJson(travelDoc.data()!, travelDoc.id);
      } else {
        throw Exception('Travel document not found.');
      }
    } catch (e) {
      print('Error fetching travel data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          try {
            final completeTravel = await _fetchCompleteTravel();

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripDetails(travel: completeTravel),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading travel details: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Card(
          margin: const EdgeInsets.all(4),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: _buildCardImage(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: $location',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage() {
    if (image.isEmpty || image == 'null') {
      return Container(
        color: Colors.grey[200],
        child: Center(child: Icon(Icons.image, size: 40, color: Colors.grey[400])),
      );
    }

    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      );
    } else {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      );
    }
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400])),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
