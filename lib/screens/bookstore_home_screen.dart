// lib/screens/bookstore_home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/store.dart';
import 'store_books_screen.dart';
import 'bookstore_cart_screen.dart';
import '../services/cart_service.dart';

const String _base = 'http://10.56.119.103:8000'; // change for physical device

class BookstoreHomeScreen extends StatefulWidget {
  const BookstoreHomeScreen({super.key});

  @override
  State<BookstoreHomeScreen> createState() => _BookstoreHomeScreenState();
}

class _BookstoreHomeScreenState extends State<BookstoreHomeScreen> {
  List<BookStore> _stores  = [];
  bool _loading            = true;
  String? _error;
  Position? _userPosition;
  final _cart = CartService();

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Get user location
      _userPosition = await _getUserLocation();

      // 2. Fetch stores
      final res = await http.get(Uri.parse('$_base/api/stores/'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final stores = data.map((j) => BookStore.fromJson(j)).toList();

        // 3. Calculate distances
        if (_userPosition != null) {
          for (final store in stores) {
            if (store.latitude != null && store.longitude != null) {
              final meters = Geolocator.distanceBetween(
                _userPosition!.latitude,
                _userPosition!.longitude,
                store.latitude!,
                store.longitude!,
              );
              store.distanceKm = meters / 1000;
            }
          }
          // Sort by distance
          stores.sort((a, b) =>
              (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
        }

        setState(() { _stores = stores; _loading = false; });
      } else {
        setState(() { _error = 'Failed to load stores'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Position?> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('BookStore',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BookstoreCartScreen())),
              ),
              if (_cart.itemCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFF059669), shape: BoxShape.circle),
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : _error != null
          ? Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadStores, child: const Text('Retry')),
        ],
      ))
          : RefreshIndicator(
        color: const Color(0xFF059669),
        onRefresh: _loadStores,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Location banner
            if (_userPosition == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.location_off, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location unavailable — distances cannot be shown. Enable location for the best experience.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ]),
              ),

            const Text('Nearby Bookstores',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: Color(0xFF111827))),
            const SizedBox(height: 4),
            Text('${_stores.length} stores available',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),

            ..._stores.map((store) => _StoreCard(
              store: store,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreBooksScreen(store: store),
                ),
              ).then((_) => setState(() {})), // refresh cart count
            )),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final BookStore store;
  final VoidCallback onTap;
  const _StoreCard({required this.store, required this.onTap});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) { return const Color(0xFF059669); }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(store.primaryColor);
    final hasLogo = store.logoUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // ── Header banner ──
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: hasLogo
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    store.logoUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _letterAvatar(color),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return _letterAvatar(color);
                    },
                  ),
                )
                    : _letterAvatar(color),
              ),
            ),

            // ── Store info ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827))),
                        if (store.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: Color(0xFF6B7280)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(store.address,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (store.distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(store.distanceText,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      const SizedBox(height: 6),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _letterAvatar(Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          store.name[0].toUpperCase(),
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color),
        ),
      ),
    );
  }
}