import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';

class MockData {
  static const categories = <Category>[
    Category(id: 'cat_fruits', name: 'Fruits & Veg', icon: Icons.local_florist),
    Category(id: 'cat_dairy', name: 'Dairy & Bread', icon: Icons.bakery_dining),
    Category(id: 'cat_snacks', name: 'Snacks', icon: Icons.emoji_food_beverage),
    Category(id: 'cat_bakery', name: 'Bakery', icon: Icons.cake),
    Category(
      id: 'cat_breakfast',
      name: 'Breakfast',
      icon: Icons.breakfast_dining,
    ),
    Category(id: 'cat_tea', name: 'Tea, Coffee', icon: Icons.coffee),
    Category(id: 'cat_drinks', name: 'Cold Drinks', icon: Icons.local_drink),
    Category(id: 'cat_sweets', name: 'Sweet Tooth', icon: Icons.icecream),
    Category(id: 'cat_grains', name: 'Atta, Rice', icon: Icons.rice_bowl),
    Category(id: 'cat_oil', name: 'Masala, Oil', icon: Icons.soup_kitchen),
    Category(id: 'cat_sauces', name: 'Sauces', icon: Icons.ramen_dining),
    Category(id: 'cat_meat', name: 'Chicken, Meat', icon: Icons.restaurant),
    Category(
      id: 'cat_cleaning',
      name: 'Cleaning',
      icon: Icons.cleaning_services,
    ),
    Category(id: 'cat_home', name: 'Home & Office', icon: Icons.home_work),
    Category(id: 'cat_personal', name: 'Personal Care', icon: Icons.spa),
    Category(id: 'cat_pets', name: 'Pet Care', icon: Icons.pets),
  ];

  static const products = <Product>[
    Product(
      id: 'prod_banana',
      storeId: 'mall',
      name: 'Bananas',
      unit: '1 kg',
      price: 60,
    ),
    Product(
      id: 'prod_spinach',
      storeId: 'mall',
      name: 'Spinach',
      unit: '250 g',
      price: 35,
    ),
    Product(
      id: 'prod_milk',
      storeId: 'mall',
      name: 'Whole Milk',
      unit: '1 L',
      price: 72,
    ),
    Product(
      id: 'prod_bread',
      storeId: 'mall',
      name: 'Multigrain Bread',
      unit: '400 g',
      price: 55,
    ),
    Product(
      id: 'prod_chips',
      storeId: 'mall',
      name: 'Potato Chips',
      unit: '52 g',
      price: 30,
    ),
    Product(
      id: 'prod_cookies',
      storeId: 'mall',
      name: 'Chocolate Cookies',
      unit: '150 g',
      price: 65,
    ),
    Product(
      id: 'prod_cola',
      storeId: 'mall',
      name: 'Cola',
      unit: '750 ml',
      price: 45,
    ),
    Product(
      id: 'prod_juice',
      storeId: 'mall',
      name: 'Orange Juice',
      unit: '1 L',
      price: 110,
    ),
    Product(
      id: 'prod_coffee',
      storeId: 'mall',
      name: 'Instant Coffee',
      unit: '100 g',
      price: 180,
    ),
    Product(
      id: 'prod_tea',
      storeId: 'mall',
      name: 'Green Tea',
      unit: '25 bags',
      price: 140,
    ),
    Product(
      id: 'prod_rice',
      storeId: 'mall',
      name: 'Basmati Rice',
      unit: '1 kg',
      price: 210,
    ),
    Product(
      id: 'prod_flour',
      storeId: 'mall',
      name: 'Wheat Flour',
      unit: '1 kg',
      price: 85,
    ),
  ];

  static productsForStore(String id) {}
}
