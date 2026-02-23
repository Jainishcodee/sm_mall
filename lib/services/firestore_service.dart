import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_item.dart';
import '../models/category.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firestore;

  String _stringValue(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    if (value is String) {
      return value;
    }
    return fallback;
  }

  double _doubleValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  bool _boolValue(
    Map<String, dynamic> data,
    String key, {
    bool fallback = false,
  }) {
    final value = data[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value != 0;
    }
    return fallback;
  }

  CollectionReference<Map<String, dynamic>> get productsCollection {
    return _firestore.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get categoriesCollection {
    return _firestore.collection('categories');
  }

  Future<String> addProduct({
    required String name,
    required String category,
    required double price,
    required String unit,
    required String stockNote,
    required bool isActive,
    required String description,
    String? imageUrl,
    String storeId = 'mall',
  }) async {
    final doc = await productsCollection.add({
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'stockNote': stockNote,
      'isActive': isActive,
      'description': description,
      'imageUrl': imageUrl,
      'storeId': storeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String category,
    required double price,
    required String unit,
    required String stockNote,
    required bool isActive,
    required String description,
    String? imageUrl,
  }) async {
    await productsCollection.doc(productId).update({
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'stockNote': stockNote,
      'isActive': isActive,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await productsCollection.doc(productId).delete();
  }

  Stream<List<Product>> streamActiveProducts() {
    return productsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return _boolValue(data, 'isActive', fallback: true);
          })
          .map((doc) {
            final data = doc.data();
            return Product(
              id: doc.id,
              storeId: _stringValue(data, 'storeId', fallback: 'mall'),
              name: _stringValue(data, 'name'),
              unit: _stringValue(data, 'unit'),
              price: _doubleValue(data, 'price'),
              imageUrl: data['imageUrl'] as String?,
            );
          })
          .toList();
    });
  }

  Stream<List<Product>> streamStoreProducts(String storeId) {
    return productsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final active = _boolValue(data, 'isActive', fallback: true);
            final productStoreId = _stringValue(
              data,
              'storeId',
              fallback: 'mall',
            );
            return active && productStoreId == storeId;
          })
          .map((doc) {
            final data = doc.data();
            return Product(
              id: doc.id,
              storeId: _stringValue(data, 'storeId', fallback: storeId),
              name: _stringValue(data, 'name'),
              unit: _stringValue(data, 'unit'),
              price: _doubleValue(data, 'price'),
              imageUrl: data['imageUrl'] as String?,
            );
          })
          .toList();
    });
  }

  Stream<List<CatalogItem>> streamCatalogItems() {
    return productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CatalogItem(
          product: Product(
            id: doc.id,
            storeId: _stringValue(data, 'storeId', fallback: 'mall'),
            name: _stringValue(data, 'name'),
            unit: _stringValue(data, 'unit'),
            price: _doubleValue(data, 'price'),
            imageUrl: data['imageUrl'] as String?,
          ),
          category: _stringValue(data, 'category'),
          stockNote: _stringValue(data, 'stockNote'),
          isActive: _boolValue(data, 'isActive', fallback: true),
          description: _stringValue(data, 'description'),
        );
      }).toList();
    });
  }

  Stream<List<Category>> streamCategories() {
    return categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc['isActive'] ?? true)
          .map(
            (doc) => Category(
              id: doc.id,
              name: doc['name'] ?? '',
              iconName: doc['iconName'] ?? 'category',
            ),
          )
          .toList();
    });
  }

  Future<Map<String, dynamic>?> getProductDetails(String productId) async {
    final doc = await productsCollection.doc(productId).get();
    return doc.data();
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final activeProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.read(firestoreServiceProvider).streamActiveProducts();
});

final storeProductsStreamProvider =
    StreamProvider.family<List<Product>, String>((ref, storeId) {
      return ref.read(firestoreServiceProvider).streamStoreProducts(storeId);
    });

final catalogItemsStreamProvider = StreamProvider<List<CatalogItem>>((ref) {
  return ref.read(firestoreServiceProvider).streamCatalogItems();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.read(firestoreServiceProvider).streamCategories();
});
