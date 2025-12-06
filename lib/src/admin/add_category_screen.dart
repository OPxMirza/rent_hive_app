import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/Category.dart';

// Replace with your Cloudinary details
const String cloudName = 'draqcjajq';
const String uploadPreset = 'hive_app';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedIconPath;
  // Removed unused _imagePicker field
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dynamic list of available category icons
  List<String> availableIcons = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();

    // Load all icons from assets/categoryIcons folder
    _loadCategoryIcons();
  }

  // Function to automatically load all images from assets/categoryIcons folder
  Future<void> _loadCategoryIcons() async {
    try {
      // Get the manifest data to access asset information
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filter assets that are in the categoryIcons folder
      final categoryIconAssets =
          manifestMap.keys
              .where((String key) => key.startsWith('assets/categoryIcons/'))
              .where(
                (String key) =>
                    key.toLowerCase().endsWith('.png') ||
                    key.toLowerCase().endsWith('.jpg') ||
                    key.toLowerCase().endsWith('.jpeg'),
              )
              .toList();

      setState(() {
        availableIcons = categoryIconAssets;
      });

      debugPrint('Loaded ${availableIcons.length} category icons');
    } catch (e) {
      debugPrint('Error loading category icons: $e');
      // Fallback to manual list if automatic loading fails
      setState(() {
        availableIcons = [
          'assets/categoryIcons/download (11).png',
          'assets/categoryIcons/download (10).png',
          'assets/categoryIcons/download (9).png',
          'assets/categoryIcons/images (9).png',
          'assets/categoryIcons/images (8).png',
          'assets/categoryIcons/download (4).jpg',
          'assets/categoryIcons/download (8).png',
          'assets/categoryIcons/images (7).png',
          'assets/categoryIcons/images (6).png',
          'assets/categoryIcons/download (3).jpg',
          'assets/categoryIcons/images (5).png',
          'assets/categoryIcons/download (7).png',
          'assets/categoryIcons/download (6).png',
          'assets/categoryIcons/images.jpg',
          'assets/categoryIcons/images (4).png',
          'assets/categoryIcons/download (5).png',
          'assets/categoryIcons/download (4).png',
          'assets/categoryIcons/download (3).png',
          'assets/categoryIcons/images (3).png',
          'assets/categoryIcons/images (2).png',
          'assets/categoryIcons/images (1).png',
        ];
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showIconGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Category Icon',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final iconPath = availableIcons[index];
                      final isSelected = _selectedIconPath == iconPath;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIconPath = iconPath;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xFF6366F1)
                                      : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Stack(
                              children: [
                                Image.asset(
                                  iconPath,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.category,
                                        color: Colors.grey[400],
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.3),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 40,
                                      ),
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
            ),
          ),
    );
  }

  Future<String?> _uploadIconToCloudinary() async {
    try {
      if (_selectedIconPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an icon first'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      List<int> bytes;

      if (_selectedIconPath!.startsWith('assets/')) {
        // Load from assets
        final ByteData data = await rootBundle.load(_selectedIconPath!);
        bytes = data.buffer.asUint8List();
      } else {
        // Load from file system
        final file = File(_selectedIconPath!);
        bytes = await file.readAsBytes();
      }

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Add upload preset
      request.fields['upload_preset'] = uploadPreset;

      // Add the icon file
      final filename = _selectedIconPath!.split('/').last;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final resJson = json.decode(resStr);
        return resJson['secure_url'];
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error uploading icon to Cloudinary: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading icon to Cloudinary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIconPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an icon first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload icon to Cloudinary
      final String? iconUrl = await _uploadIconToCloudinary();
      if (iconUrl == null) throw Exception('Failed to upload icon');

      // Create new category
      final category = Category(iconURL: iconUrl, name: _nameController.text);

      // Save to Firestore
      await _firestore.collection('categories').add(category.toMap());

      // Show success message and return to previous screen
      if (!mounted) return;
      Navigator.pop(context, category);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Add New Category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconPicker(),
                const SizedBox(height: 30),
                _buildFormFields(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (_selectedIconPath != null)
                Image.asset(
                  _selectedIconPath!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading icon',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No Icon Selected',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select from gallery',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedIconPath != null ? 'Selected Icon' : 'Select Icon',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                        ),
                        onPressed: _showIconGallery,
                        tooltip: 'Select from Assets',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: Colors.black.withValues(alpha: 0.7),
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   child: IconButton(
                    //     icon: const Icon(Icons.camera_alt, color: Colors.white),
                    //     onPressed: _pickIcon,
                    //     tooltip: 'Pick from Gallery',
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
        ),
      ),
      child: _buildTextField(
        controller: _nameController,
        label: 'Category Name',
        hint: 'Enter category name',
        icon: Icons.category,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a category name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Add Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
        ),
      ),
    );
  }
}
