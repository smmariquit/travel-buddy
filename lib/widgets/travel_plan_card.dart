/// Travel Plan Card Widget
///
/// Displays a clickable card summarizing a travel plan, including image, name, location, and date range.
/// Tapping the card fetches the full travel plan and navigates to the details page.
///
/// # References
/// - [InkWell](https://api.flutter.dev/flutter/material/InkWell-class.html)
/// - [Card](https://api.flutter.dev/flutter/material/Card-class.html)
/// - [ClipRRect](https://api.flutter.dev/flutter/widgets/ClipRRect-class.html)
/// - [TextOverflow](https://api.flutter.dev/flutter/painting/TextOverflow.html)
/// - [Image.asset](https://api.flutter.dev/flutter/widgets/Image/Image.asset.html)
/// - [Image.network](https://api.flutter.dev/flutter/widgets/Image/Image.network.html)

// Flutter & Material
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Firebase & External Services
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// State Management
import 'package:provider/provider.dart';

// App-specific
import 'package:travel_app/models/travel_plan_model.dart';
import 'package:travel_app/providers/travel_plans_provider.dart';
import 'package:travel_app/providers/user_provider.dart';
import 'package:travel_app/utils/constants.dart';
import 'package:travel_app/screens/add_travel/trip_details.dart';

/// Constants for styling the [TravelPlanCard].
class TravelPlanCardConstants {
  static const double cardWidth = 240;
  static const double cardHeight = 200;
  static const double cardElevation = 4;
  static const double cardMargin = 4;
  static const double cardPadding = 12;
  static const double cardImageHeight = 140;
}

/// A stateless widget that displays a clickable card for a travel plan.
///
/// The card shows the plan's image, name, location, and date range.
/// Tapping the card fetches the full travel plan and navigates to the details page.
class TravelPlanCard extends StatelessWidget {
  final String travelId;
  final String uid;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdOn;
  final String location;
  final String image;

  /// Creates a [TravelPlanCard] widget.
  ///
  /// All parameters are required and must not be null.
  const TravelPlanCard({
    Key? key,
    required this.travelId,
    required this.uid,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.location,
    required this.createdOn,
    required this.image,
  });

  /// Fetches the complete [Travel] object from Firestore using [travelId].
  ///
  /// Throws an [Exception] if the document is not found or if an error occurs.
  Future<Travel> _fetchCompleteTravel() async {
    try {
      final travelDoc =
          await FirebaseFirestore.instance
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

  /// Builds the travel plan card UI.
  ///
  /// The card is clickable and navigates to the details page on tap.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: TravelPlanCardConstants.cardWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        // https://api.flutter.dev/flutter/material/InkWell-class.html Gives the user the ability to tap on the card
        // Also creates a ripple effect when the user taps on the card, which is a material design effect.
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
                  content: Text(
                    'Error loading travel details: ${e.toString()}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Card(
          // https://api.flutter.dev/flutter/material/Card-class.html
          margin: const EdgeInsets.all(TravelPlanCardConstants.cardMargin),
          elevation: TravelPlanCardConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                // https://api.flutter.dev/flutter/widgets/ClipRRect-class.html To clip the image to the border radius of the card
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: SizedBox(
                  height: TravelPlanCardConstants.cardImageHeight,
                  width: double.infinity,
                  child: _buildCardImage(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(
                  TravelPlanCardConstants.cardPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            endDate != null
                                ? '${_formatDate(startDate)} - ${_formatDate(endDate!)}'
                                : '${_formatDate(startDate)} -',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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

  /// Builds the card image widget.
  ///
  /// If [image] is empty or 'null', displays a placeholder icon.
  /// If [image] is an asset path, loads the asset image.
  /// If [image] is a network URL, loads the image from the network.
  /// If loading fails, displays a broken image icon.
  Widget _buildCardImage() {
    if (image.isEmpty || image == 'null') {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
        ),
      );
    }

    /// Differentiate whether the image is a local asset or from the Firebase database.
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

  /// Returns a placeholder widget when the image is not found.
  ///
  /// Displays a broken image icon.
  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  /// Formats a [DateTime] as DD/MM/YYYY, which is ISO 8601 format.
  ///
  /// Returns a string in the format 'dd/mm/yyyy'.
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }
}
