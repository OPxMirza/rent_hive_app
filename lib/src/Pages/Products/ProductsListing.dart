import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:carousel_slider/carousel_slider.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/Products.dart';
import '../../models/Category.dart';
import '../../Components/CategoryChip.dart';
import '../../Components/ProductCard.dart';
import '../../Components/ProductDetailsSheet.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: Colors.deepPurple,
      ),
      home: ProductsPage(),
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> _allProducts = [];
  List<Category> _categories = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch categories
      final catSnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      final categories =
          catSnapshot.docs
              .map((doc) => Category.fromMap(doc.data(), doc.id))
              .toList();
      // Fetch products
      final prodSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('status', isEqualTo: 'available')
              .get();
      final products =
          prodSnapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id))
              .toList();
      setState(() {
        _categories = categories;
        _allProducts = products;
        _isLoading = false;
        _selectedCategory = 'All';
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Product> get _filteredProducts {
    List<Product> filtered = _allProducts;
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (p) =>
                    p.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    p.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search here...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap:
                              () => setState(() => _selectedCategory = 'All'),
                          child: Chip(
                            label: const Text('All'),
                            backgroundColor:
                                _selectedCategory == 'All'
                                    ? Colors.deepPurple
                                    : Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  _selectedCategory == 'All'
                                      ? Colors.white
                                      : Colors.deepPurple,
                            ),
                            padding: const EdgeInsets.all(10.0),
                          ),
                        ),
                      ),
                      for (int i = 0; i < _categories.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap:
                                () => setState(
                                  () => _selectedCategory = _categories[i].name,
                                ),
                            child: CategoryChip(
                              cat: _categories[i],
                              isSelected:
                                  _categories[i].name == _selectedCategory,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            const SizedBox(height: 20),
            const Text(
              'Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredProducts.isEmpty
                      ? Center(
                        child: Text(
                          'No product found in that category',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.7,
                            ),
                        itemCount: _filteredProducts.length,
                        itemBuilder:
                            (context, index) => GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (context) => ProductDetailsSheet(
                                        product: _filteredProducts[index],
                                      ),
                                );
                              },
                              child: ProductCard(
                                product: _filteredProducts[index],
                              ),
                            ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
