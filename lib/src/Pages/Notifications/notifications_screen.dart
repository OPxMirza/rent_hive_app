import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Stream<QuerySnapshot> _notificationStream(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'wishlist':
        return Icons.favorite_border;
      case 'announcement':
      default:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () async {
              final snap = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: user.uid)
                  .where('isRead', isEqualTo: false)
                  .get();

              final batch = FirebaseFirestore.instance.batch();
              for (final doc in snap.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
            },
            child: const Text(
              "Mark all read",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = (data['title'] ?? '') as String;
              final body = (data['body'] ?? '') as String;
              final type = (data['type'] ?? 'announcement') as String;
              final isRead = (data['isRead'] ?? false) as bool;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isRead ? Colors.grey.shade300 : Colors.deepPurple.shade100,
                  child: Icon(
                    _iconForType(type),
                    color: isRead ? Colors.grey : Colors.deepPurple,
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                  ),
                ),
                subtitle: Text(body),
                trailing: isRead
                    ? null
                    : const Icon(Icons.circle, size: 10, color: Colors.red),
                onTap: () async {
                  await _markAsRead(doc.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
