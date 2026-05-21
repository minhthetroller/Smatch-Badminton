import 'package:flutter/material.dart';

import 'map_view.dart';
import 'matches/matches_screen.dart';
import 'widgets/bottom_nav_bar.dart';

/// Main screen with tab navigation between Explore (Map) and Matches
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to prevent conflicts with map gestures
        children: const [
          MapView(),
          MatchesScreen(),
        ],
      ),
      // Use extendBody to prevent content from resizing when bottom nav hides
      extendBody: true,
      bottomNavigationBar: MapBottomNavBar(
        currentIndex: _tabController.index,
        items: MapBottomNavBar.defaultItems,
        onTap: (index) {
          _tabController.animateTo(index);
          setState(() {});
        },
      ),
    );
  }
}
