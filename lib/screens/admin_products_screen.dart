import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      _ProductRow(
        name: 'Special Gujarati Thali',
        price: 'Rs 299',
        stock: '28 in stock',
        category: 'Meals',
        isActive: true,
      ),
      _ProductRow(
        name: 'Dal Khichadi (500g)',
        price: 'Rs 169',
        stock: '12 in stock',
        category: 'Meals',
        isActive: true,
      ),
      _ProductRow(
        name: 'Masala Chaas',
        price: 'Rs 35',
        stock: 'Low stock',
        category: 'Beverages',
        isActive: true,
      ),
      _ProductRow(
        name: 'Gulab Jamun (2 pc)',
        price: 'Rs 79',
        stock: 'Out of stock',
        category: 'Desserts',
        isActive: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminProductFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Manage products, availability, and pricing.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.slate500),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '32 items',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...products.map(
            (product) => _ProductTile(
              data: product,
              onEdit: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminProductFormScreen(
                      initialName: product.name,
                      initialCategory: product.category,
                      initialPrice: product.price,
                      initialStock: product.stock,
                    ),
                  ),
                );
              },
              onDelete: () {},
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProductRow {
  final String name;
  final String price;
  final String stock;
  final String category;
  final bool isActive;

  const _ProductRow({
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.isActive,
  });
}

class _ProductTile extends StatelessWidget {
  final _ProductRow data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        data.isActive ? AppColors.success : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.fastfood, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.category} · ${data.price}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Text(
                  data.stock,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.slate700),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: AppColors.slate700),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
