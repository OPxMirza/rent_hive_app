import 'package:flutter/material.dart';
import '../models/Category.dart';

class CategoryChip extends StatelessWidget {
  final Category cat;
  final bool isSelected;

  const CategoryChip({super.key, required this.cat, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (cat.iconURL.isNotEmpty) {
      if (cat.iconURL.startsWith('http')) {
        avatar = Image.network(
          cat.iconURL,
          width: 24,
          height: 24,
          errorBuilder:
              (c, e, s) => const Icon(Icons.category, color: Colors.deepPurple),
        );
      } else {
        avatar = Image.asset(
          cat.iconURL,
          width: 24,
          height: 24,
          errorBuilder:
              (c, e, s) => const Icon(Icons.category, color: Colors.deepPurple),
        );
      }
    } else {
      avatar = const Icon(Icons.category, color: Colors.deepPurple);
    }

    return Chip(
      padding: const EdgeInsets.all(10.0),
      backgroundColor: isSelected ? Colors.deepPurple : Colors.white,
      avatar: avatar,
      label: Text(
        cat.name,
        style: TextStyle(color: isSelected ? Colors.white : Colors.deepPurple),
      ),
    );
  }
}
