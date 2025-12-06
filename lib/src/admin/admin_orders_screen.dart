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
          (snapshot) =>
              snapshot.docs
                  .map((doc) => model.Order.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> _updateOrderStatus(
    String orderId,
    String productId,
    String status,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final orderRef = firestore.collection('orders').doc(orderId);
    final productRef = firestore.collection('products').doc(productId);

    await firestore.runTransaction((transaction) async {
      // Update order status
      transaction.update(orderRef, {'status': status});

      // Update product status
      if (status == 'approved') {
        transaction.update(productRef, {'status': 'rented'});
      } else if (status == 'returned') {
        transaction.update(productRef, {'status': 'available'});
      }
    });
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
                                Text(
                                  'User: ${order.userId}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'CNIC: ${order.cnic}',
                                  style: const TextStyle(fontSize: 13),
                                ),
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
                          'From: ${order.startDate!.toLocal().toString().split(' ')[0]} To: ${order.endDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      Text('Address: ${order.productDescription}'),
                      Text('Category: ${order.productCategory}'),
                      Text(
                        'Price: Rs. ${order.productPrice.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (order.status == 'pending') ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed:
                                  () => _updateOrderStatus(
                                    order.id,
                                    order.productId,
                                    'approved',
                                  ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed:
                                  () => _updateOrderStatus(
                                    order.id,
                                    order.productId,
                                    'rejected',
                                  ),
                            ),
                          ] else if (order.status == 'approved') ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment_turned_in),
                              label: const Text('Mark as Returned'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed:
                                  () => _updateOrderStatus(
                                    order.id,
                                    order.productId,
                                    'returned',
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
      case 'rejected':
        return Colors.red;
      case 'returned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
