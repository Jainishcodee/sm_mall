import 'product.dart';

class CatalogItem {
  final Product product;
  final String category;
  final String stockNote;
  final bool isActive;
  final String description;

  const CatalogItem({
    required this.product,
    required this.category,
    required this.stockNote,
    required this.isActive,
    required this.description,
  });

  CatalogItem copyWith({
    Product? product,
    String? category,
    String? stockNote,
    bool? isActive,
    String? description,
  }) {
    return CatalogItem(
      product: product ?? this.product,
      category: category ?? this.category,
      stockNote: stockNote ?? this.stockNote,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }
}
