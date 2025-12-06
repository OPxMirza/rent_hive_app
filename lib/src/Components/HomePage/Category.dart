import 'package:flutter/material.dart';

class Category extends StatelessWidget {
  const Category({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // child: // SizedBox(
              //   height: 140,
              //   child: ListView.builder(
              //     scrollDirection: Axis.horizontal,
              //     itemCount: categories.length,
              //     physics: BouncingScrollPhysics(),
              //     shrinkWrap: true,
              //     itemBuilder: (context, index) {
              //       return Container(
              //         width: 120,
              //         margin: const EdgeInsets.symmetric(horizontal: 8),
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           borderRadius: BorderRadius.circular(16),
              //           boxShadow: const [
              //             BoxShadow(color: Colors.grey, blurRadius: 4),
              //           ],
              //         ),
              //         child: Padding(
              //           padding: const EdgeInsets.all(8.0), // 4 sides padding
              //           child: Column(
              //             children: [
              //               Container(
              //                 height: 80,
              //                 decoration: BoxDecoration(
              //                   borderRadius: BorderRadius.circular(12),
              //                   image: DecorationImage(
              //                     image: AssetImage(images[index]),
              //                     fit: BoxFit.cover,
              //                   ),
              //                 ),
              //               ),
              //               const SizedBox(height: 6),
              //               Center(
              //                 child: Text(
              //                   categories[index],
              //                   textAlign: TextAlign.center,
              //                   style: const TextStyle(
              //                     fontWeight: FontWeight.bold,
              //                     fontSize: 15,
              //                     fontFamily: 'Georgia', // Stylish font
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       );
              //     },
              //   ),
              // ),
    );
  }
}