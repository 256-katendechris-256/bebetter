// lib/screens/store_books_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/store.dart';
import '../models/bookstore_book.dart';
import '../services/cart_service.dart';
import 'bookstore_cart_screen.dart';

const String _base = 'http://10.56.119.103:8000';

class StoreBooksScreen extends StatefulWidget {
  final BookStore store;
  const StoreBooksScreen({super.key, required this.store});

  @override
  State<StoreBooksScreen> createState() => _StoreBooksScreenState();
}

class _StoreBooksScreenState extends State<StoreBooksScreen> {
  List<BookstoreBook> _books = [];
  bool _loading = true;
  String? _error;
  final _cart = CartService();

  Color get _color {
    try {
      return Color(int.parse(
          'FF${widget.store.primaryColor.replaceAll('#', '')}', radix: 16));
    } catch (_) { return const Color(0xFF059669); }
  }

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('$_base/api/books/'),
        headers: {'X-Tenant-Slug': widget.store.slug},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _books = data.map((j) => BookstoreBook.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Failed to load books'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _addToCart(BookstoreBook book) {
    final added = _cart.addBook(book, widget.store);
    if (!added) {
      // Cart has items from another store
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Different store'),
          content: Text(
              'Your cart has items from ${_cart.currentStore?.name}. '
                  'Clear cart and add from ${widget.store.name}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                _cart.clear();
                _cart.addBook(book, widget.store);
                Navigator.pop(context);
                setState(() {});
                _showAddedSnackbar(book);
              },
              child: const Text('Clear & Add',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      setState(() {});
      _showAddedSnackbar(book);
    }
  }

  void _showAddedSnackbar(BookstoreBook book) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${book.title} added to cart'),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: SnackBarAction(
        label: 'View Cart',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BookstoreCartScreen())),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: Text(widget.store.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BookstoreCartScreen()))
                    .then((_) => setState(() {})),
              ),
              if (_cart.itemCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: _color, shape: BoxShape.circle),
                    child: Text('${_cart.itemCount}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _books.isEmpty
          ? const Center(child: Text('No books available in this store'))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing:  12,
        ),
        itemCount: _books.length,
        itemBuilder: (_, i) => _BookCard(
          book:     _books[i],
          color:    _color,
          onAddToCart: () => _addToCart(_books[i]),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookstoreBook book;
  final Color color;
  final VoidCallback onAddToCart;
  const _BookCard({
    required this.book,
    required this.color,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: book.coverUrl.isNotEmpty
                  ? Image.network(book.coverUrl, width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(color))
                  : _placeholder(color),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(book.author,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(book.formattedPrice,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                    GestureDetector(
                      onTap: book.stock > 0 ? onAddToCart : null,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: book.stock > 0
                              ? color
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add,
                            color: book.stock > 0
                                ? Colors.white
                                : Colors.grey,
                            size: 16),
                      ),
                    ),
                  ],
                ),
                if (book.stock == 0)
                  const Text('Out of stock',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color color) => Container(
    color: color.withOpacity(0.08),
    child: Center(child: Icon(Icons.book, size: 40, color: color.withOpacity(0.4))),
  );
}