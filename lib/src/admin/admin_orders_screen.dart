import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Order.dart' as model;

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  Stream<List<model.Order>> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => model.Order.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Creates a notification document in Firestore
  Future<void> _createNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    required String orderId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('notifications').add({
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type, // ex: order_approved, order_paid
      'orderId': orderId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateOrderStatus({
    required String orderId,
    required String productId,
    required String userId,
    required String status,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final orderRef = firestore.collection('orders').doc(orderId);
    final productRef = firestore.collection('products').doc(productId);

    await firestore.runTransaction((transaction) async {
      // Update order status
      transaction.update(orderRef, {'status': status});

      // Update product status
      if (status == 'approved' || status == 'paid') {
        transaction.update(productRef, {'status': 'rented'});
      } else if (status == 'returned') {
        transaction.update(productRef, {'status': 'available'});
      }
    });

    // AFTER transaction success => create notification
    if (status == 'approved') {
      await _createNotification(
        recipientId: userId,
        title: "Order Approved ✅",
        body: "Your rental request has been approved.",
        type: "order_approved",
        orderId: orderId,
      );
    } else if (status == 'rejected') {
      await _createNotification(
        recipientId: userId,
        title: "Order Rejected ❌",
        body: "Your rental request was rejected.",
        type: "order_rejected",
        orderId: orderId,
      );
    } else if (status == 'returned') {
      await _createNotification(
        recipientId: userId,
        title: "Order Returned 🔁",
        body: "Your rental has been marked as returned.",
        type: "order_returned",
        orderId: orderId,
      );
    } else if (status == 'paid') {
      await _createNotification(
        recipientId: userId,
        title: "Payment Received 💰",
        body: "Your payment has been received successfully.",
        type: "order_paid",
        orderId: orderId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Requests')),
      body: StreamBuilder<List<model.Order>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rental requests found.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(order.productImage),
                            radius: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.productTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text('User: ${order.userId}',
                                    style: const TextStyle(fontSize: 13)),
                                Text('CNIC: ${order.cnic}',
                                    style: const TextStyle(fontSize: 13)),
                                Text(
                                  'Status: ${order.status}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _statusColor(order.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Rental Duration: ${order.rentalDuration} days'),
                      if (order.startDate != null && order.endDate != null)
                        Text(
                          'From: ${order.startDate!.toLocal().toString().split(' ')[0]} '
                          'To: ${order.endDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      Text('Address: ${order.productDescription}'),
                      Text('Category: ${order.productCategory}'),
                      Text('Price: Rs. ${order.productPrice.toStringAsFixed(0)}'),
                      const SizedBox(height: 10),

                      // ACTIONS
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (order.status == 'pending') ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => _updateOrderStatus(
                                orderId: order.id,
                                productId: order.productId,
                                userId: order.userId,
                                status: 'approved',
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => _updateOrderStatus(
                                orderId: order.id,
                                productId: order.productId,
                                userId: order.userId,
                                status: 'rejected',
                              ),
                            ),
                          ] else if (order.status == 'approved') ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.payment),
                              label: const Text('Mark Paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                              onPressed: () => _updateOrderStatus(
                                orderId: order.id,
                                productId: order.productId,
                                userId: order.userId,
                                status: 'paid',
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment_turned_in),
                              label: const Text('Returned'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () => _updateOrderStatus(
                                orderId: order.id,
                                productId: order.productId,
                                userId: order.userId,
                                status: 'returned',
                              ),
                            ),
                          ] else if (order.status == 'paid') ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment_turned_in),
                              label: const Text('Returned'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () => _updateOrderStatus(
                                orderId: order.id,
                                productId: order.productId,
                                userId: order.userId,
                                status: 'returned',
                              ),
                            ),
                          ] else ...[
                            Text(
                              'No actions available',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'paid':
        return Colors.deepPurple;
      case 'rejected':
        return Colors.red;
      case 'returned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
