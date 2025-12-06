import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Carouselslider extends StatelessWidget {
  final List<String> imgList = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
  ];

  Carouselslider({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        viewportFraction: 0.8,
      ),
      items:
          imgList
              .map(
                (item) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(item, fit: BoxFit.cover, width: 1000),
                  ),
                ),
              )
              .toList(),
    );
  }
}
