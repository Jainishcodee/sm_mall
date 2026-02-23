import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_skeleton.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    CatalogItem product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Delete "${product.product.name}" from Firestore? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteProduct(product.product.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product deleted')));
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error.code == 'permission-denied'
          ? 'Delete failed: sign in as admin with real OTP.'
          : 'Delete failed: ${error.message ?? error.code}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(catalogItemsStreamProvider);
    final productCount = productsAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$productCount items',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...productsAsync.when(
            data: (products) => products
                .map(
                  (product) => _ProductTile(
                    data: product,
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminProductFormScreen(initialItem: product),
                        ),
                      );
                    },
                    onDelete: () async {
                      await _deleteProduct(context, ref, product);
                    },
                  ),
                )
                .toList(),
            loading: () => [const ProductListSkeleton(itemCount: 4)],
            error: (error, stack) => [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Unable to load products.')),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final CatalogItem data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = data.isActive ? AppColors.success : AppColors.primary;
    final imageUrl = data.product.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
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
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) {
                        return Icon(Icons.fastfood, color: statusColor);
                      },
                    ),
                  )
                : Icon(Icons.fastfood, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.product.name,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.category} · Rs ${data.product.price.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Text(
                  data.stockNote,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.slate700),
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
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
