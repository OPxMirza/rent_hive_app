import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/Category.dart';

class Categorysection extends StatefulWidget {
  final VoidCallback? onViewAll;
  const Categorysection({super.key, this.onViewAll});

  @override
  State<Categorysection> createState() => _CategorysectionState();
}

class _CategorysectionState extends State<Categorysection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      final categories =
          snapshot.docs
              .map((doc) => Category.fromMap(doc.data(), doc.id))
              .toList();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String categoryName) {
    // Map category names to appropriate material icons
    final name = categoryName.toLowerCase();

    if (name.contains('food') ||
        name.contains('restaurant') ||
        name.contains('meal')) {
      return Icons.fastfood;
    } else if (name.contains('shopping') ||
        name.contains('store') ||
        name.contains('market')) {
      return Icons.shopping_bag;
    } else if (name.contains('health') ||
        name.contains('medical') ||
        name.contains('hospital')) {
      return Icons.local_hospital;
    } else if (name.contains('sport') ||
        name.contains('fitness') ||
        name.contains('gym')) {
      return Icons.sports_soccer;
    } else if (name.contains('music') ||
        name.contains('audio') ||
        name.contains('sound')) {
      return Icons.music_note;
    } else if (name.contains('book') ||
        name.contains('read') ||
        name.contains('library')) {
      return Icons.book;
    } else if (name.contains('home') ||
        name.contains('house') ||
        name.contains('property')) {
      return Icons.home;
    } else if (name.contains('work') ||
        name.contains('office') ||
        name.contains('business')) {
      return Icons.work;
    } else if (name.contains('electronic') ||
        name.contains('device') ||
        name.contains('tech')) {
      return Icons.devices;
    } else if (name.contains('furniture') ||
        name.contains('chair') ||
        name.contains('table')) {
      return Icons.chair;
    } else if (name.contains('vehicle') ||
        name.contains('car') ||
        name.contains('transport')) {
      return Icons.directions_car;
    } else if (name.contains('clothing') ||
        name.contains('fashion') ||
        name.contains('wear')) {
      return Icons.checkroom;
    } else if (name.contains('toy') ||
        name.contains('game') ||
        name.contains('play')) {
      return Icons.toys;
    } else if (name.contains('beauty') ||
        name.contains('cosmetic') ||
        name.contains('makeup')) {
      return Icons.face;
    } else if (name.contains('pet') ||
        name.contains('animal') ||
        name.contains('dog')) {
      return Icons.pets;
    } else {
      return Icons.category; // Default icon
    }
  }

  void _onCategoryTap(Category category) {
    // Handle individual category tap
    debugPrint('Tapped on category: ${category.name}');
    // Navigate to specific category page or filter content
    // Example:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CategoryDetailPage(category: category),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Categories header with navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                ),
              ),
              GestureDetector(
                onTap: widget.onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Categories list
        SizedBox(
          height: 120,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                  ? const Center(
                    child: Text(
                      'No categories available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return GestureDetector(
                        onTap: () {
                          // Handle category tap
                          _onCategoryTap(category);
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon container
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(index),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child:
                                      category.iconURL.isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            child: Image.network(
                                              category.iconURL,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Icon(
                                                  _getCategoryIcon(
                                                    category.name,
                                                  ),
                                                  color: Colors.white,
                                                  size: 24,
                                                );
                                              },
                                            ),
                                          )
                                          : Icon(
                                            _getCategoryIcon(category.name),
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                ),
                                const SizedBox(height: 8),
                                // Category name
                                Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
