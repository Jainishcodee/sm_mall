import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProductImage({
    required String productId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('products')
          .child(productId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (error) {
      return null;
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (error) {
      // Ignore deletion errors
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
