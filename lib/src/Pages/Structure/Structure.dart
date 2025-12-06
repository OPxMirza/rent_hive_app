import 'package:flutter/material.dart';
import 'package:rent_hive_app/src/Components/BottomNavigation.dart';
import 'package:rent_hive_app/src/Components/Drawer.dart';
import 'package:rent_hive_app/src/Pages/Home/home.dart';
import 'package:rent_hive_app/src/Pages/Products/ProductsListing.dart';
import 'package:rent_hive_app/src/Pages/Settings/Settings.dart';
import 'package:rent_hive_app/src/Pages/Wishlist/Wishlist.dart';

// void main() {
//   runApp(const RentHiveApp());
// }

// class RentHiveApp extends StatelessWidget {
//   const RentHiveApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Rent Hive',
//       theme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//         primaryColor: Colors.white,
//         scaffoldBackgroundColor: Colors.grey[50],
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.deepPurple,
//           foregroundColor: Colors.white,
//           elevation: 0,
//         ),
//         bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//           backgroundColor: Colors.white,
//           selectedItemColor: Colors.deepPurple,
//           unselectedItemColor: Colors.grey,
//           type: BottomNavigationBarType.fixed,
//           elevation: 8,
//         ),
//       ),
//       home: const MainScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: PageView(controller: pageController, children: _screens),
      bottomNavigationBar: Bottomnavigation(pageController: pageController),
    );
  }
}
