import 'package:flutter/material.dart';
import 'package:rent_hive_app/src/Components/BottomNavigation.dart';
import 'package:rent_hive_app/src/Components/Drawer.dart';
import 'package:rent_hive_app/src/Pages/Home/home.dart';
import 'package:rent_hive_app/src/Pages/Products/ProductsListing.dart';
import 'package:rent_hive_app/src/Pages/Settings/Settings.dart';
import 'package:rent_hive_app/src/Pages/Wishlist/Wishlist.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rent_hive_app/src/Pages/Notifications/notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final PageController pageController = PageController();

  final List<Widget> _screens = [
    RentHiveHomePage(),
    ProductsPage(),
    WishlistPage(),
    SettingsScreen(),
  ];

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // ✅ Notification bell with badge
  Widget _notificationBell(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final unreadStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: unreadStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 99 ? "99+" : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rent Hive',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _notificationBell(context), // ✅ Use it here
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: PageView(controller: pageController, children: _screens),
      bottomNavigationBar: Bottomnavigation(pageController: pageController),
    );
  }
}
