// lib/screens/bookstore_cart_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../services/cart_service.dart';

const String _base = 'http://10.56.119.103:8000';

class BookstoreCartScreen extends StatefulWidget {
  const BookstoreCartScreen({super.key});

  @override
  State<BookstoreCartScreen> createState() => _BookstoreCartScreenState();
}

class _BookstoreCartScreenState extends State<BookstoreCartScreen> {
  final _cart = CartService();
  final _addressCtrl = TextEditingController();
  bool _placing = false;
  String? _error;

  @override
  void dispose() { _addressCtrl.dispose(); super.dispose(); }

  Future<String?> _getToken() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: 'access_token');  // ← matches _accessKey in ApiService
  }

  Future<void> _placeOrder() async {
    if (_cart.items.isEmpty) return;

    final token = await _getToken();
    if (token == null) {
      setState(() => _error = 'You must be logged in to place an order.');
      return;
    }

    setState(() { _placing = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse('$_base/api/orders/place/'),
        headers: {
          'Content-Type':  'application/json',
          'X-Tenant-Slug': _cart.currentStore!.slug,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': _cart.items.map((i) => {
            'book_id':  i.book.id,
            'quantity': i.quantity,
          }).toList(),
          'delivery_address': _addressCtrl.text,
          'payment_method':   'mobile_money',
        }),
      );

      if (res.statusCode == 201) {
        _cart.clear();
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Order Placed! 🎉'),
            content: const Text(
                'Your order has been received. '
                    'The store will contact you to confirm delivery.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final body = jsonDecode(res.body);
        setState(() {
          _error = body['error'] ?? 'Failed to place order';
          _placing = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _placing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _cart.items.isEmpty
          ? const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Your cart is empty',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
      )
          : Column(
        children: [
          // Store banner
          if (_cart.currentStore != null)
            Container(
              color: const Color(0xFF0D1B2A),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(children: [
                const Icon(Icons.store_outlined,
                    color: Color(0xFF6EE7B7), size: 16),
                const SizedBox(width: 6),
                Text('From: ${_cart.currentStore!.name}',
                    style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cart.items.length,
              itemBuilder: (_, i) => _CartTile(
                item:     _cart.items[i],
                onRemove: () => setState(() => _cart.removeBook(_cart.items[i].book.id)),
                onQtyChange: (q) => setState(
                        () => _cart.updateQty(_cart.items[i].book.id, q)),
              ),
            ),
          ),

          // Checkout panel
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Delivery address',
                    hintText:  'e.g. Kampala, Nakasero Road',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon:
                    const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      'UGX ${_cart.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: Color(0xFF059669)),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _placing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _placing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Place Order',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;
  const _CartTile({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.book.coverUrl.isNotEmpty
                ? Image.network(item.book.coverUrl,
                width: 50, height: 68, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 50, height: 68,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.book, color: Colors.grey)))
                : Container(
                width: 50, height: 68,
                color: Colors.grey.shade100,
                child: const Icon(Icons.book, color: Colors.grey)),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.book.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('UGX ${item.book.effectivePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // Qty controls
          Row(children: [
            GestureDetector(
              onTap: () => onQtyChange(item.quantity - 1),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.remove, size: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('${item.quantity}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            GestureDetector(
              onTap: () => onQtyChange(item.quantity + 1),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.add,
                    size: 16, color: Color(0xFF059669)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}