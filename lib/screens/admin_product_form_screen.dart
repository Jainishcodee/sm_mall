import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/catalog_item.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_skeleton.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final CatalogItem? initialItem;

  const AdminProductFormScreen({super.key, this.initialItem});

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  late final TextEditingController nameController;
  late final TextEditingController categoryController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  late final TextEditingController unitController;
  late final TextEditingController descriptionController;

  bool isActive = true;
  Object? selectedImage;
  bool isUploading = false;
  String? _draftProductId;

  XFile? _selectedImageAsXFile() {
    final current = selectedImage;
    if (current == null) {
      return null;
    }
    if (current is XFile) {
      return current;
    }
    try {
      final path = (current as dynamic).path;
      if (path is String && path.isNotEmpty) {
        return XFile(path);
      }
    } catch (_) {
      // Ignore conversion failures
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    nameController = TextEditingController(text: initial?.product.name ?? '');
    categoryController = TextEditingController(text: initial?.category ?? '');
    priceController = TextEditingController(
      text: initial?.product.price.toStringAsFixed(0) ?? '',
    );
    stockController = TextEditingController(text: initial?.stockNote ?? '');
    unitController = TextEditingController(text: initial?.product.unit ?? '');
    descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    isActive = initial?.isActive ?? true;
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

  Future<void> _pickImage() async {
    // Constrain dimensions and quality so we don't load a 12MP photo into
    // RAM — readAsBytes + MultipartFile.fromBytes were OOM-ing on lower-RAM
    // devices when uploading the original.
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        selectedImage = pickedFile;
      });
    }
  }

  Future<void> _uploadAndSave() async {
    final name = nameController.text.trim();
    final category = categoryController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? -1;
    final stockNote = stockController.text.trim();
    final unit = unitController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || price <= 0 || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name, unit, and valid price.')),
      );
      return;
    }

    final isEditing = widget.initialItem != null;
    setState(() => isUploading = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      String productId;

      if (isEditing) {
        productId = widget.initialItem!.product.id;
        await firestoreService.updateProduct(
          productId: productId,
          name: name,
          category: category,
          price: price,
          unit: unit,
          stockNote: stockNote,
          isActive: isActive,
          description: description,
          imageUrl: null,
        );
      } else {
        productId =
            _draftProductId ??
            await firestoreService.addProduct(
              name: name,
              category: category,
              price: price,
              unit: unit,
              stockNote: stockNote,
              isActive: isActive,
              description: description,
              imageUrl: null,
            );
        _draftProductId ??= productId;
        await firestoreService.updateProduct(
          productId: productId,
          name: name,
          category: category,
          price: price,
          unit: unit,
          stockNote: stockNote,
          isActive: isActive,
          description: description,
          imageUrl: null,
        );
      }

      final imageFile = _selectedImageAsXFile();
      if (imageFile != null) {
        final imageUrl = await cloudinaryService.uploadProductImage(
          imageFile: imageFile,
          publicId: productId,
        );
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Image upload failed (no URL returned).');
        }

        await firestoreService.updateProduct(
          productId: productId,
          name: name,
          category: category,
          price: price,
          unit: unit,
          stockNote: stockNote,
          isActive: isActive,
          description: description,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() => isUploading = false);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving product: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialItem != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Product' : 'Add Product')),
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
            hintText: 'Number of units (e.g. 15) or text label',
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
            ),
            onChanged: (value) => setState(() => isActive = value),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Product Image',
            subtitle: 'Upload a photo of your product',
          ),
          const SizedBox(height: 12),
          if (selectedImage != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _PickedImagePreview(file: selectedImage!),
              ),
            ),
          if (selectedImage == null &&
              widget.initialItem?.product.imageUrl != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.initialItem!.product.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: Text(selectedImage != null ? 'Change Image' : 'Pick Image'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: AppColors.slate200,
              foregroundColor: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isUploading ? null : _uploadAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isUploading
                ? const SkeletonBox(
                    height: 16,
                    width: 110,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  )
                : Text(isEditing ? 'Save Changes' : 'Add Product'),
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: const Text(
                      'Are you sure you want to delete this product?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  try {
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.deleteProduct(
                      widget.initialItem!.product.id,
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting product: $error'),
                        ),
                      );
                    }
                  }
                }
              },
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

class _PickedImagePreview extends StatelessWidget {
  final Object file;

  const _PickedImagePreview({required this.file});

  XFile? _asXFile() {
    if (file is XFile) {
      return file as XFile;
    }
    try {
      final path = (file as dynamic).path;
      if (path is String && path.isNotEmpty) {
        return XFile(path);
      }
    } catch (_) {
      // Ignore conversion failures
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final xFile = _asXFile();
    if (xFile == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Unsupported image type')),
      );
    }
    return FutureBuilder<Uint8List>(
      future: xFile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Could not load image')),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: SkeletonBox(
              height: 200,
              width: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          );
        }
        return Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.slate500),
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
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.slate700),
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
