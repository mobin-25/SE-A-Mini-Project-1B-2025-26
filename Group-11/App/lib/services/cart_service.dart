import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // ➕ Add item to cart
  void addToCart(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  // ❌ Remove item
  void removeFromCart(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // 🧹 Clear cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // 💰 Total price
  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.price;
    }
    return total;
  }
}