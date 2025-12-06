import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String? id;
  final String name;
  final String iconURL;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    required this.iconURL,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Firestore document to Category object
  factory Category.fromMap(Map<String, dynamic> map, String documentId) {
    return Category(
      id: documentId,
      name: map['name'] ?? '',
      iconURL: map['iconURL'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Category object to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconURL': iconURL,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy of the category with some fields updated
  Category copyWith({
    String? id,
    String? name,
    String? iconURL,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconURL: iconURL ?? this.iconURL,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
