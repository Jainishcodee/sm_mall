import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminProductFormScreen extends StatefulWidget {
  final String? initialName;
  final String? initialCategory;
  final String? initialPrice;
  final String? initialStock;

  const AdminProductFormScreen({
    super.key,
    this.initialName,
    this.initialCategory,
    this.initialPrice,
    this.initialStock,
  });

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  late final TextEditingController nameController;
  late final TextEditingController categoryController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  late final TextEditingController unitController;
  late final TextEditingController descriptionController;

  bool isActive = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    categoryController =
        TextEditingController(text: widget.initialCategory ?? '');
    priceController = TextEditingController(
      text: widget.initialPrice?.replaceAll('Rs ', '') ?? '',
    );
    stockController = TextEditingController(text: widget.initialStock ?? '');
    unitController = TextEditingController(text: '500 g');
    descriptionController = TextEditingController(
      text: 'Freshly prepared and packed with care.',
    );
    isActive = widget.initialName != null;
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    stockController.dispose();
    unitController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            title: 'Product Details',
            subtitle: 'Keep catalog up to date for better conversions.',
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Product name',
            controller: nameController,
            hintText: 'Enter product name',
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Category',
            controller: categoryController,
            hintText: 'Meals, Beverages, Desserts',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Price (Rs)',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  hintText: '0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Unit',
                  controller: unitController,
                  hintText: '500 g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Stock note',
            controller: stockController,
            hintText: '28 in stock',
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Description',
            subtitle: 'Used on product cards and listings.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add short product description',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Availability',
            subtitle: 'Control whether the item is visible to customers.',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: isActive,
            activeColor: AppColors.success,
            title: const Text('Product active'),
            subtitle: Text(
              isActive ? 'Visible on customer app' : 'Hidden from customer app',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.slate500),
            ),
            onChanged: (value) => setState(() => isActive = value),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(isEditing ? 'Save Changes' : 'Add Product'),
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Delete Product'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.slate500),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.slate700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
