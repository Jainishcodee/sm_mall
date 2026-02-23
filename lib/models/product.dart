class Product {
  final String id;
  final String storeId;
  final String name;
  final String unit;
  final double price;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.unit,
    required this.price,
    this.imageUrl,
  });
}
