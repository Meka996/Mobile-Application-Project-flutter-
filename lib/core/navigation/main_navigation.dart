import '../widgets/velora_button.dart';
import '../widgets/velora_text_field.dart';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final List<String> pages = [
    'Home Screen',
    'Shop Screen',
    'Wishlist Screen',
    'Profile Screen',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VELORA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),

      body: selectedIndex == 0
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Home Screen',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, color: AppTheme.deepRose),
                ),

                const SizedBox(height: 30),

                const VeloraTextField(
                  hint: 'Search for dresses, shoes, bags...',
                  icon: Icons.search,
                ),

                const SizedBox(height: 25),

                VeloraButton(
                  text: 'Shop Now',
                  icon: Icons.shopping_bag_outlined,
                  onPressed: () {
                    setState(() {
                      selectedIndex = 1;
                    });
                  },
                ),
              ],
            )
          : Center(
              child: Text(
                pages[selectedIndex],
                style: const TextStyle(fontSize: 25, color: AppTheme.deepRose),
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.offWhite,
        selectedItemColor: AppTheme.deepRose,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
