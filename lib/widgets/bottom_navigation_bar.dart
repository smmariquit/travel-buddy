import 'package:flutter/material.dart';
import 'package:travel_app/screens/main_page.dart';
import 'package:travel_app/screens/find_similar_people.dart';
import 'package:travel_app/screens/profile_screen.dart';

class BottomNavBar extends StatelessWidget{
  BottomNavBar({
    super.key
  });

  @override
  Widget build(BuildContext context){
    return BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.home, color: Colors.green),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.map, color: Colors.grey),
                  onPressed: () {
                    // TODO: Replace with Plans page
                  },
                ),
                const SizedBox(width: 48), // space for FAB
                IconButton(
                  icon: Icon(Icons.handshake, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FindSimilarPeople()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          );
  }
}