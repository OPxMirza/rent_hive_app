import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> availableIcons = [];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _loadCategoryIcons();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryIcons() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final categoryIconAssets = manifestMap.keys
          .where((key) => key.startsWith('assets/categoryIcons/'))
          .where((key) =>
              key.toLowerCase().endsWith('.png') ||
              key.toLowerCase().endsWith('.jpg') ||
              key.toLowerCase().endsWith('.jpeg'))
          .toList();

      if (!mounted) return;
      setState(() => availableIcons = categoryIconAssets);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        availableIcons = [
          'assets/categoryIcons/download (11).png',
          'assets/categoryIcons/download (10).png',
          'assets/categoryIcons/download (9).png',
          'assets/categoryIcons/images (9).png',
          'assets/categoryIcons/images (8).png',
        ];
      });
    }
  }

  void _showIconGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildGalleryHeader(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      setState(() => _selectedIconPath = iconPath);
                      Navigator.pop(context);
                    },
                    child: _buildIconItem(iconPath, isSelected),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Category Icon',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIconItem(String iconPath, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
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
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: Icon(Icons.category, size: 40, color: Colors.grey[400]),
              ),
            ),
            if (isSelected)
              Container(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                child: const Center(
                  child: Icon(Icons.check_circle, color: Colors.white, size: 40),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadIconToCloudinary() async {
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

    try {
      List<int> bytes;
      String mimeType = 'image/png';
      final filename = _selectedIconPath!.split('/').last;

      if (_selectedIconPath!.startsWith('assets/')) {
        final data = await rootBundle.load(_selectedIconPath!);
        bytes = data.buffer.asUint8List();
      } else if (File(_selectedIconPath!).existsSync()) {
        bytes = await File(_selectedIconPath!).readAsBytes();
      } else {
        throw Exception('Invalid icon path');
      }

      if (filename.toLowerCase().endsWith('.jpg') ||
          filename.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      }

      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
            contentType: MediaType('image', mimeType.split('/').last),
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final resJson = json.decode(resStr);
        return resJson['secure_url'];
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading icon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // ✅ NEW: notify all users when category added
  Future<void> _notifyAllUsersAboutNewCategory({
    required String categoryId,
    required String categoryName,
  }) async {
    final usersSnap = await _firestore.collection('users').get();
    if (usersSnap.docs.isEmpty) return;

    final batch = _firestore.batch();
    final now = Timestamp.now();

    for (final u in usersSnap.docs) {
      final uid = u.id;

      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'recipientId': uid,
        'title': 'New Category Added',
        'body': '$categoryName category is now available',
        'type': 'category',
        'refId': categoryId,
        'createdAt': now,
        'isRead': false,
      });
    }

    await batch.commit();
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
      final iconUrl = await _uploadIconToCloudinary();
      if (iconUrl == null) throw Exception('Failed to upload icon');

      final name = _nameController.text.trim();

      final category = Category(iconURL: iconUrl, name: name);

      // ✅ Save category + get docId
      final docRef =
          await _firestore.collection('categories').add(category.toMap());

      // ✅ Create notifications for all users
      await _notifyAllUsersAboutNewCategory(
        categoryId: docRef.id,
        categoryName: name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added and users notified ✅'),
          backgroundColor: Colors.green,
        ),
      );

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Add New Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ),
      ),
      child: GestureDetector(
        onTap: _showIconGallery,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                    errorBuilder: (_, __, ___) => _iconPlaceholder(),
                  )
                else
                  _iconPlaceholder(),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      onPressed: _showIconGallery,
                      tooltip: 'Select from Assets',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconPlaceholder() {
    return Container(
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
    );
  }

  Widget _buildFormFields() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
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
        validator: (value) =>
            (value == null || value.trim().isEmpty)
                ? 'Please enter a category name'
                : null,
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
            color: Colors.black.withOpacity(0.05),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
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
            shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
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
