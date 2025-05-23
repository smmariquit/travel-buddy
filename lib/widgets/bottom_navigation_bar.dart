/// This widget serves as the main navigation for the app.
///
/// [BottomNavBar] appears at the bottom of the screen and provides navigation
/// between the main sections of the app: Home, Plans, Find Similar People, and Profile.
/// It also reserves space for a Floating Action Button (FAB) in the center.
///
/// The navigation bar uses a [BottomAppBar] with a notched shape to accommodate the FAB.
/// Each icon button navigates to a different screen using [Navigator].
library;

// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
// (none in this file)

// State Management
// (none in this file)

// App-specific
import 'package:travel_app/screens/home/main_page.dart';
import 'package:travel_app/screens/friends/find_similar_people.dart';
import 'package:travel_app/screens/profile/profile_screen.dart';
import 'package:travel_app/screens/view_all_plans.dart';

/// Constants for the bottom navigation bar
class BottomNavConstants {
  static const double notchMargin = 8.0;
  static const double fabSpace = 48.0;
  static const double iconSize = 36.0;
  static const Color selectedColor = Color(
    0xFF218463,
  ); // Using the app's primary color
  static const Color unselectedColor = Colors.grey;
}

/// A stateful widget that displays the main bottom navigation bar for the app.
///
/// The navigation bar includes:
/// - Home button: Navigates to the main page
/// - Plans button: (To be implemented) Navigates to the user's travel plans
/// - Find Similar People button: Navigates to a screen for finding similar users
/// - Profile button: Navigates to the user's profile
///
/// The bar also reserves space in the center for a Floating Action Button (FAB).
class BottomNavBar extends StatefulWidget {
  final int selectedIndex;

  /// Creates a [BottomNavBar] widget.
  const BottomNavBar({super.key, required this.selectedIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  /// List of navigation items with their respective icons and routes
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'Home',
      route: (context) => const MainPage(),
      routeName: '/main',
    ),
    NavigationItem(
      icon: Icons.map,
      label: 'Plans',
      route: (context) => const ViewAllPlans(),
      routeName: '/plans',
    ),
    NavigationItem(
      icon: Icons.handshake,
      label: 'Find People',
      route: (context) => const FindSimilarPeopleScreen(),
      routeName: '/find_people',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Profile',
      route: (context) => const ProfileScreen(),
      routeName: '/profile',
    ),
  ];

  void _onItemTapped(int index) {
    // Only navigate if it's not the current page
    if (index != _selectedIndex) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: _navigationItems[index].route,
          settings: RouteSettings(name: _navigationItems[index].routeName),
        ),
      );
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: BottomNavConstants.notchMargin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ...List.generate(_navigationItems.length + 1, (index) {
            // Skip the middle space for FAB
            if (index == 2) {
              return const SizedBox(width: BottomNavConstants.fabSpace);
            }

            // Adjust index for items after the FAB space
            final adjustedIndex = index > 2 ? index - 1 : index;

            return IconButton(
              icon: Icon(
                _navigationItems[adjustedIndex].icon,
                color:
                    _selectedIndex == adjustedIndex
                        ? BottomNavConstants.selectedColor
                        : BottomNavConstants.unselectedColor,
              ),
              onPressed: () => _onItemTapped(adjustedIndex),
              tooltip: _navigationItems[adjustedIndex].label,
              iconSize: BottomNavConstants.iconSize,
            );
          }),
        ],
      ),
    );
  }
}

/// A class to hold navigation item data
class NavigationItem {
  final IconData icon;
  final String label;
  final Widget Function(BuildContext) route;
  final String routeName;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.routeName,
  });
}
