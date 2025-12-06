import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/Order.dart' as model;
import '../../services/cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final CartService _cartService = CartService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;
  User? _currentUser;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(27.7172, 85.3240),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndLoadUserData();
  }

  Future<void> _initializeFirebaseAndLoadUserData() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        FirebaseAuth.instance.signInAnonymously().then((credential) {
          setState(() {
            _currentUser = credential.user;
          });
        });
      } else {
        setState(() {
          _currentUser = user;
        });
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    setState(() {
      _loading = true;
    });

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _addressController.text = userData['address'] ?? '';
        _phoneController.text = userData['phone'] ?? '';

        if (userData['location'] != null) {
          _selectedLocation = LatLng(
            userData['location'].latitude,
            userData['location'].longitude,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _processPayment(model.Order order) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a payment.')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery location.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
            'status': 'paid',
            'deliveryLocation': GeoPoint(
              _selectedLocation!.latitude,
              _selectedLocation!.longitude,
            ),
            'deliveryAddress': _addressController.text,
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
            'name': _nameController.text,
            'email': _emailController.text,
            'address': _addressController.text,
            'phone': _phoneController.text,
            'location': GeoPoint(
              _selectedLocation!.latitude,
              _selectedLocation!.longitude,
            ),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Order Confirmed.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showPaymentDialog(model.Order order) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Complete Payment'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Product: ${order.productTitle}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Amount: Rs. ${order.productPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _addressController,
                        labelText: 'Delivery Address',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Select delivery location on map:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                            if (_selectedLocation != null) {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(_selectedLocation!),
                              );
                            }
                          },
                          initialCameraPosition: _kInitialPosition,
                          markers:
                              _selectedLocation != null
                                  ? {
                                    Marker(
                                      markerId: const MarkerId(
                                        'selectedLocation',
                                      ),
                                      position: _selectedLocation!,
                                      infoWindow: const InfoWindow(
                                        title: 'Delivery Location',
                                      ),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueRed,
                                          ),
                                    ),
                                  }
                                  : {},
                          onTap: (LatLng location) {
                            setState(() {
                              _selectedLocation = location;
                            });
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(location),
                            );
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedLocation != null)
                        Text(
                          'Selected Location: ${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                          '${_selectedLocation!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _loading ? null : () => _processPayment(order),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.deepPurple,
                          ),
                          child:
                              _loading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text('Complete Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Map<String, List<model.Order>> _groupOrdersByStatus(
    List<model.Order> orders,
  ) {
    final map = <String, List<model.Order>>{};
    for (final order in orders) {
      (map[order.status] ??= []).add(order);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text(
          'My Orders',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: _cartService.getCartCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<model.Order>>(
                stream: _cartService.getAllUserOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final cartItems = snapshot.data ?? [];

                  if (cartItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some products to get started!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final groupedOrders = _groupOrdersByStatus(cartItems);
                  final statusOrder = [
                    'pending',
                    'approved',
                    'paid',
                    'rejected',
                    'returned',
                  ];

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        statusOrder.map((status) {
                          final orders = groupedOrders[status] ?? [];
                          if (orders.isEmpty) return const SizedBox.shrink();

                          return ExpansionTile(
                            title: Text(
                              '${status[0].toUpperCase()}${status.substring(1)} (${orders.length})',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            initiallyExpanded:
                                status == 'pending' || status == 'approved',
                            children:
                                orders.map((item) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          item.productImage,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              height: 80,
                                              width: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      title: Text(
                                        item.productTitle,
                                        style: GoogleFonts.roboto(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rs. ${item.productPrice.toStringAsFixed(2)}',
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (item.status == 'approved')
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  _showPaymentDialog(item);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: const Text('Pay Now'),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _cartService.removeFromCart(
                                              item.id,
                                            ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          );
                        }).toList(),
                  );
                },
              ),
    );
  }
}
