import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartState {
  final Map<String, CartItem> items;

  const CartState({required this.items});

  int get totalItems {
    return items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return items.values.fold(0, (sum, item) => sum + item.totalPrice);
  }

  bool get isEmpty => items.isEmpty;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState(items: {}));

  void addItem(Product product) {
    final existing = state.items[product.id];
    if (existing == null) {
      state = CartState(
        items: {
          ...state.items,
          product.id: CartItem(product: product, quantity: 1),
        },
      );
    } else {
      updateQuantity(product, existing.quantity + 1);
    }
  }

  void decrementItem(Product product) {
    final existing = state.items[product.id];
    if (existing == null) {
      return;
    }
    if (existing.quantity <= 1) {
      removeItem(product);
    } else {
      updateQuantity(product, existing.quantity - 1);
    }
  }

  void removeItem(Product product) {
    final updated = Map<String, CartItem>.from(state.items);
    updated.remove(product.id);
    state = CartState(items: updated);
  }

  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeItem(product);
      return;
    }
    state = CartState(
      items: {
        ...state.items,
        product.id: CartItem(product: product, quantity: quantity),
      },
    );
  }

  void clear() {
    state = const CartState(items: {});
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
