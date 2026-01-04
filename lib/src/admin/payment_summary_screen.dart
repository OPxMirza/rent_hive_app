import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Order.dart' as model;

class PaymentSummaryScreen extends StatelessWidget {
  const PaymentSummaryScreen({super.key});

  // ✅ Get ALL orders (paid + unpaid) sorted by latest
  Stream<List<model.Order>> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => model.Order.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Summaries'),
      ),
      body: StreamBuilder<List<model.Order>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              final status = (order.status ?? '').toString().toLowerCase();
              final isPaid = status == 'paid';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        order.productTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ✅ Status (PAID / NOT PAID)
                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid ? 'PAID' : 'NOT PAID',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text('User ID: ${order.userId}'),

                      const SizedBox(height: 6),

                      Text(
                        'Date: ${order.createdAt.toLocal().toString().split(' ')[0]}',
                      ),

                      const SizedBox(height: 6),

                      Text('Rental Duration: ${order.rentalDuration} days'),

                      const SizedBox(height: 6),

                      Text(
                        'Price: Rs. ${order.productPrice.toStringAsFixed(0)}',
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
}
