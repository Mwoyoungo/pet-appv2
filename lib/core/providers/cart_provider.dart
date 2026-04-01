import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_app/core/models/product_model.dart';

class CartItem {
  final String productId;
  final String storeId;
  final String storeName;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.storeId,
    required this.storeName,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        storeId: storeId,
        storeName: storeName,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl,
      );
}

class CartState {
  final String? storeId;
  final String? storeName;
  final Map<String, CartItem> items; // productId → CartItem

  const CartState({
    this.storeId,
    this.storeName,
    this.items = const {},
  });

  double get subtotal =>
      items.values.fold(0.0, (sum, i) => sum + i.price * i.quantity);

  int get totalItems => items.values.fold(0, (sum, i) => sum + i.quantity);

  bool get isEmpty => items.isEmpty;

  int quantityOf(String productId) => items[productId]?.quantity ?? 0;
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Returns true if the cart belongs to a different store (user should be warned).
  bool wouldClearCart(String storeId) =>
      state.storeId != null && state.storeId != storeId;

  void addItem(ProductModel product, String storeId, String storeName) {
    // Different store → start fresh
    if (state.storeId != null && state.storeId != storeId) {
      state = const CartState();
    }

    final items = Map<String, CartItem>.from(state.items);
    if (items.containsKey(product.id)) {
      items[product.id] = items[product.id]!
          .copyWith(quantity: items[product.id]!.quantity + 1);
    } else {
      items[product.id] = CartItem(
        productId: product.id,
        storeId: storeId,
        storeName: storeName,
        name: product.name,
        price: product.price,
        quantity: 1,
        imageUrl: product.imageUrl,
      );
    }
    state = CartState(storeId: storeId, storeName: storeName, items: items);
  }

  void decreaseItem(String productId) {
    final items = Map<String, CartItem>.from(state.items);
    if (!items.containsKey(productId)) return;
    final current = items[productId]!.quantity;
    if (current <= 1) {
      items.remove(productId);
    } else {
      items[productId] = items[productId]!.copyWith(quantity: current - 1);
    }
    state = CartState(
      storeId: items.isEmpty ? null : state.storeId,
      storeName: items.isEmpty ? null : state.storeName,
      items: items,
    );
  }

  void removeItem(String productId) {
    final items = Map<String, CartItem>.from(state.items)
      ..remove(productId);
    state = CartState(
      storeId: items.isEmpty ? null : state.storeId,
      storeName: items.isEmpty ? null : state.storeName,
      items: items,
    );
  }

  /// Increment an item already in the cart by productId (no ProductModel needed).
  void incrementItem(String productId) {
    final items = Map<String, CartItem>.from(state.items);
    if (!items.containsKey(productId)) return;
    items[productId] = items[productId]!
        .copyWith(quantity: items[productId]!.quantity + 1);
    state = CartState(
      storeId: state.storeId,
      storeName: state.storeName,
      items: items,
    );
  }

  void clearCart() => state = const CartState();
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
