import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String iconName;

  const Category({
    required this.id,
    required this.name,
    required this.iconName,
  });

  IconData get iconData => _iconMap[iconName] ?? Icons.category;

  static const Map<String, IconData> _iconMap = {
    'local_florist': Icons.local_florist,
    'bakery_dining': Icons.bakery_dining,
    'emoji_food_beverage': Icons.emoji_food_beverage,
    'cake': Icons.cake,
    'breakfast_dining': Icons.breakfast_dining,
    'coffee': Icons.coffee,
    'local_drink': Icons.local_drink,
    'icecream': Icons.icecream,
    'rice_bowl': Icons.rice_bowl,
    'soup_kitchen': Icons.soup_kitchen,
    'ramen_dining': Icons.ramen_dining,
    'restaurant': Icons.restaurant,
    'cleaning_services': Icons.cleaning_services,
    'home_work': Icons.home_work,
    'spa': Icons.spa,
    'pets': Icons.pets,
  };
}
