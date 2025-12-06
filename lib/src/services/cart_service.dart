import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Order.dart';
import '../models/Products.dart';
import 'package:flutter/foundation.dart';

class CartService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add product to cart (now requires rentalDuration and cnic)
  Future<void> addToCart(
    Product product, {
    required int rentalDuration,
    required String cnic,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      // Check if product already exists in cart
      final existingOrder =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: currentUserId)
              .where('productId', isEqualTo: product.id)
              .where('status', isEqualTo: 'cart')
              .get();

      if (existingOrder.docs.isNotEmpty) {
        throw Exception('Product already in cart');
      }

      // Create new order
      final order = Order(
        id: '',
        userId: currentUserId!,
        productId: product.id ?? '',
        productTitle: product.title,
        productImage: product.imageURL,
        productPrice: product.price,
        productDescription: product.description,
        productCategory: product.category,
        createdAt: DateTime.now(),
        status: 'cart',
        rentalDuration: rentalDuration,
        cnic: cnic,
        startDate: null,
        endDate: null,
      );

      await _firestore.collection('orders').add(order.toMap());
    } catch (e) {
      throw Exception('Failed to add product to cart: $e');
    }
  }

  // Remove product from cart
  Future<void> removeFromCart(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to remove product from cart: $e');
    }
  }

  // Get all cart items for current user
  Stream<List<Order>> getCartItems() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'cart')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Order.fromMap(doc.data(), doc.id))
                .toList();
          } catch (e) {
            debugPrint('Error parsing cart items: $e');
            return <Order>[];
          }
        })
        .handleError((error) {
          debugPrint('Error fetching cart items: $error');
          return <Order>[];
        });
  }

  // Get all orders for current user
  Stream<List<Order>> getAllUserOrders() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Order.fromMap(doc.data(), doc.id))
                .toList();
          } catch (e) {
            debugPrint('Error parsing all user orders: $e');
            return <Order>[];
          }
        })
        .handleError((error) {
          debugPrint('Error fetching all user orders: $error');
          return <Order>[];
        });
  }

  // Get cart count
  Stream<int> getCartCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          debugPrint('Error fetching cart count: $error');
          return 0;
        });
  }

  // Check if product is in cart
  Future<bool> isProductInCart(String productId) async {
    if (currentUserId == null) return false;

    try {
      final result =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: currentUserId)
              .where('productId', isEqualTo: productId)
              .where('status', isEqualTo: 'cart')
              .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if product is in cart: $e');
      return false;
    }
  }
}
