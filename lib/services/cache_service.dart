import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _profileKey = 'cached_profile';
  static const String _statsKey = 'cached_stats';
  static const String _currentlyReadingKey = 'cached_currently_reading';
  static const String _booksKey = 'cached_books';
  static const String _lastSyncKey = 'last_sync_time';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Profile
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    final p = await prefs;
    await p.setString(_profileKey, jsonEncode(profile));
    await _updateLastSync();
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    final p = await prefs;
    final data = p.getString(_profileKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Stats
  Future<void> cacheStats(Map<String, dynamic> stats) async {
    final p = await prefs;
    await p.setString(_statsKey, jsonEncode(stats));
  }

  Future<Map<String, dynamic>?> getCachedStats() async {
    final p = await prefs;
    final data = p.getString(_statsKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Currently Reading
  Future<void> cacheCurrentlyReading(List<dynamic> books) async {
    final p = await prefs;
    await p.setString(_currentlyReadingKey, jsonEncode(books));
  }

  Future<List<dynamic>?> getCachedCurrentlyReading() async {
    final p = await prefs;
    final data = p.getString(_currentlyReadingKey);
    if (data != null) {
      return jsonDecode(data) as List<dynamic>;
    }
    return null;
  }

  // Books Library
  Future<void> cacheBooks(List<dynamic> books) async {
    final p = await prefs;
    await p.setString(_booksKey, jsonEncode(books));
  }

  Future<List<dynamic>?> getCachedBooks() async {
    final p = await prefs;
    final data = p.getString(_booksKey);
    if (data != null) {
      return jsonDecode(data) as List<dynamic>;
    }
    return null;
  }

  // Last sync time
  Future<void> _updateLastSync() async {
    final p = await prefs;
    await p.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSyncTime() async {
    final p = await prefs;
    final timestamp = p.getInt(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<String> getLastSyncText() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return 'Never synced';
    
    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Clear all cache
  Future<void> clearCache() async {
    final p = await prefs;
    await p.remove(_profileKey);
    await p.remove(_statsKey);
    await p.remove(_currentlyReadingKey);
    await p.remove(_booksKey);
    await p.remove(_lastSyncKey);
  }
}
