import 'package:flutter_test/flutter_test.dart';

import 'package:sm_mall/models/product.dart';
import 'package:sm_mall/providers/cart_provider.dart';

void main() {
  late CartNotifier cart;

  const milk = Product(id: 'p1', storeId: 'mall', name: 'Milk', unit: '1L', price: 60.0);
  const bread = Product(id: 'p2', storeId: 'mall', name: 'Bread', unit: '1 pack', price: 40.0);
  const eggs = Product(id: 'p3', storeId: 'mall', name: 'Eggs', unit: '12 pcs', price: 80.0);

  setUp(() {
    cart = CartNotifier();
  });

  group('CartNotifier', () {
    test('starts empty', () {
      expect(cart.state.isEmpty, true);
      expect(cart.state.totalItems, 0);
      expect(cart.state.totalPrice, 0.0);
    });

    test('addItem adds a new product', () {
      cart.addItem(milk);

      expect(cart.state.items.length, 1);
      expect(cart.state.items['p1']!.quantity, 1);
      expect(cart.state.totalPrice, 60.0);
    });

    test('addItem increments quantity for existing product', () {
      cart.addItem(milk);
      cart.addItem(milk);

      expect(cart.state.items.length, 1);
      expect(cart.state.items['p1']!.quantity, 2);
      expect(cart.state.totalPrice, 120.0);
    });

    test('addItem handles multiple different products', () {
      cart.addItem(milk);
      cart.addItem(bread);
      cart.addItem(eggs);

      expect(cart.state.items.length, 3);
      expect(cart.state.totalItems, 3);
      expect(cart.state.totalPrice, 180.0); // 60 + 40 + 80
    });

    test('decrementItem reduces quantity', () {
      cart.addItem(milk);
      cart.addItem(milk);
      cart.addItem(milk);
      cart.decrementItem(milk);

      expect(cart.state.items['p1']!.quantity, 2);
    });

    test('decrementItem removes product when quantity reaches zero', () {
      cart.addItem(milk);
      cart.decrementItem(milk);

      expect(cart.state.items.containsKey('p1'), false);
      expect(cart.state.isEmpty, true);
    });

    test('decrementItem does nothing for missing product', () {
      cart.decrementItem(milk);
      expect(cart.state.isEmpty, true);
    });

    test('removeItem removes product entirely', () {
      cart.addItem(milk);
      cart.addItem(milk);
      cart.addItem(milk);
      cart.removeItem(milk);

      expect(cart.state.items.containsKey('p1'), false);
      expect(cart.state.isEmpty, true);
    });

    test('updateQuantity sets exact quantity', () {
      cart.addItem(milk);
      cart.updateQuantity(milk, 5);

      expect(cart.state.items['p1']!.quantity, 5);
      expect(cart.state.totalPrice, 300.0);
    });

    test('updateQuantity with 0 removes item', () {
      cart.addItem(milk);
      cart.updateQuantity(milk, 0);

      expect(cart.state.isEmpty, true);
    });

    test('updateQuantity with negative removes item', () {
      cart.addItem(milk);
      cart.updateQuantity(milk, -1);

      expect(cart.state.isEmpty, true);
    });

    test('clear empties the cart', () {
      cart.addItem(milk);
      cart.addItem(bread);
      cart.addItem(eggs);
      cart.clear();

      expect(cart.state.isEmpty, true);
      expect(cart.state.totalItems, 0);
      expect(cart.state.totalPrice, 0.0);
    });

    test('totalItems sums all quantities', () {
      cart.addItem(milk);
      cart.addItem(milk);
      cart.addItem(bread);
      cart.updateQuantity(eggs, 3);

      expect(cart.state.totalItems, 6); // 2 + 1 + 3
    });

    test('totalPrice sums all item totals', () {
      cart.updateQuantity(milk, 2);  // 120
      cart.updateQuantity(bread, 3); // 120
      cart.updateQuantity(eggs, 1);  // 80

      expect(cart.state.totalPrice, 320.0);
    });
  });
}
