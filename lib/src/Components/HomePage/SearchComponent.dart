import 'package:flutter/material.dart';

class Searchbar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback onSearchCleared;

  const Searchbar({
    super.key,
    required this.onSearchChanged,
    required this.onSearchCleared,
  });

  @override
  State<Searchbar> createState() => _SearchbarState();
}

class _SearchbarState extends State<Searchbar> {
  final List<String> options = ["2-4 Beds", "Price", "Location", "Type"];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAlert(String msg) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Action'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                icon: const Icon(Icons.search),
                hintText: 'Search products...',
                border: InputBorder.none,
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchCleared();
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                widget.onSearchChanged(value);
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
