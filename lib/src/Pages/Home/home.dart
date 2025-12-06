import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rent_hive_app/src/Components/HomePage/CarouselSlider.dart';
import 'package:rent_hive_app/src/Components/HomePage/CategorySection.dart';
import 'package:rent_hive_app/src/Components/HomePage/PopularProducts.dart';
import 'package:rent_hive_app/src/Components/HomePage/SearchComponent.dart';
import 'package:rent_hive_app/src/Pages/Structure/Structure.dart';
import 'package:rent_hive_app/src/models/Products.dart';

// void main() {
//   runApp(const RentHiveApp());
// }

// class RentHiveApp extends StatelessWidget {
//   const RentHiveApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(textTheme: GoogleFonts.latoTextTheme()),
//       home: const RentHiveHomePage(),
//     );
//   }
// }

class RentHiveHomePage extends StatefulWidget {
  const RentHiveHomePage({super.key});

  @override
  _RentHiveHomePageState createState() => _RentHiveHomePageState();
}

class _RentHiveHomePageState extends State<RentHiveHomePage> {
  int selectedOption = 0;
  String searchQuery = '';
  bool isSearching = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      isSearching = query.isNotEmpty;
    });
  }

  void onSearchCleared() {
    setState(() {
      searchQuery = '';
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            // Search bar and filter icon
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Searchbar(
                onSearchChanged: onSearchChanged,
                onSearchCleared: onSearchCleared,
              ),
            ),

            // Main content
            Expanded(
              child:
                  isSearching ? _buildSearchResults() : _buildNormalContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel slider
          Carouselslider(),

          const SizedBox(height: 20),

          Categorysection(
            onViewAll: () {
              // Find the page controller and switch to the categories page (index 1)
              final mainScreenState =
                  context.findAncestorStateOfType<MainScreenState>();
              if (mainScreenState != null) {
                mainScreenState.pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // Popular Places header
          const Text(
            "Popular Products",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // List of popular places
          Popularproducts(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('products')
              .where('title', isGreaterThanOrEqualTo: searchQuery)
              .where('title', isLessThan: '$searchQuery\uf8ff')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Product.fromMap(data, doc.id);
            }).toList();

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No products found with name "$searchQuery"',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onSearchCleared,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Clear Search'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Results (${products.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onSearchCleared,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return TweenAnimationBuilder(
                    tween: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ),
                    duration: Duration(milliseconds: 300 + index * 100),
                    builder: (context, offset, child) {
                      return Transform.translate(
                        offset: offset,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${product.title} tapped"),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    index % 2 == 0 ? 12 : 45,
                                  ),
                                  child: Image.network(
                                    product.imageURL,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey[400],
                                          size: 40,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'Montserrat',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${product.category} | ${product.description.length > 30 ? '${product.description.substring(0, 30)}...' : product.description}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "\$${product.price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
