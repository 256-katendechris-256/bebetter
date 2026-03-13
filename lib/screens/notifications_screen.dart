import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// ─── Colour tokens (same as dashboard) ───────────────────────────────────────
const Color kInk          = Color(0xFF0D1B2A);
const Color kEmerald      = Color(0xFF059669);
const Color kEmeraldSoft  = Color(0xFFECFDF5);
const Color kSurface      = Color(0xFFFFFFFF);
const Color kBg           = Color(0xFFF4F6F8);
const Color kBorder       = Color(0xFFE5E7EB);
const Color kTextPrimary  = Color(0xFF111827);
const Color kTextSecondary= Color(0xFF6B7280);
const Color kTextMuted    = Color(0xFF9CA3AF);
const Color kRed          = Color(0xFFEF4444);

BoxDecoration _card({double radius = 16}) => BoxDecoration(
  color      : kSurface,
  borderRadius: BorderRadius.circular(radius),
  boxShadow  : const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x06000000), blurRadius: 4,  offset: Offset(0, 1)),
  ],
);

// ─── Notification type meta ───────────────────────────────────────────────────
Map<String, Map<String, dynamic>> _typeMeta = {
  'streak'     : {'icon': Icons.local_fire_department_rounded, 'color': Color(0xFFF97316)},
  'league'     : {'icon': Icons.emoji_events_rounded,          'color': Color(0xFFF59E0B)},
  'goal'       : {'icon': Icons.menu_book_rounded,             'color': kEmerald},
  'achievement': {'icon': Icons.star_rounded,                  'color': Color(0xFF8B5CF6)},
  'bookclub'   : {'icon': Icons.chat_bubble_rounded,           'color': Color(0xFF3B82F6)},
};

// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api      = ApiService();
  List<dynamic>  _notifications = [];
  bool           _loading       = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getNotifications();
      if (res.statusCode == 200 && mounted) {
        setState(() => _notifications = res.data as List? ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(int id, int index) async {
    try {
      await _api.markNotificationRead(id);
      if (mounted) {
        setState(() => _notifications[index]['opened'] = true);
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      if (mounted) {
        setState(() {
          for (final n in _notifications) {
            n['opened'] = true;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteNotification(int id) async {
    try {
      await _api.deleteNotification(id);
      if (mounted) setState(() => _notifications.removeWhere((n) => n['id'] == id));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete notification')),
      );
    }
  }

  Future<void> _deleteAll() async {
    try {
      await _api.deleteAllNotifications();
      if (mounted) setState(() => _notifications.clear());
    } catch (_) {}
  }

  // Group notifications by date label
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<Map<String, dynamic>>>{};

    for (final n in _notifications) {
      final sentAt = DateTime.tryParse(n['sent_at'] ?? '') ?? now;
      final day    = DateTime(sentAt.year, sentAt.month, sentAt.day);

      String label;
      if (day == today)     label = 'Today';
      else if (day == yesterday) label = 'Yesterday';
      else                  label = 'Earlier';

      groups.putIfAbsent(label, () => []).add(Map<String, dynamic>.from(n));
    }
    return groups;
  }

  bool get _hasUnread => _notifications.any((n) => n['opened'] == false);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor         : kInk,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            color  : kInk,
            padding: EdgeInsets.only(
              top   : MediaQuery.of(context).padding.top + 12,
              left  : 8,
              right : 16,
              bottom: 14,
            ),
            child: Row(
              children: [
                IconButton(
                  icon     : const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Notifications',
                      style: TextStyle(
                          fontSize    : 18,
                          fontWeight  : FontWeight.w800,
                          color       : Colors.white,
                          letterSpacing: -0.3)),
                ),
                if (_hasUnread || _notifications.isNotEmpty)
                  Row(
                    children: [
                      if (_hasUnread)
                        GestureDetector(
                          onTap: _markAllRead,
                          child: Text('Mark all read',
                              style: TextStyle(
                                  fontSize  : 13,
                                  fontWeight: FontWeight.w600,
                                  color     : kEmerald.withOpacity(0.9))),
                        ),
                      if (_hasUnread) const SizedBox(width: 12),
                      if (_notifications.isNotEmpty)
                        GestureDetector(
                          onTap: _deleteAll,
                          child: const Text('Clear all',
                              style: TextStyle(
                                  fontSize  : 13,
                                  fontWeight: FontWeight.w600,
                                  color     : kRed)),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(color: kEmerald))
                : _notifications.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              color    : kEmerald,
              onRefresh: _load,
              child    : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped;
    final order   = ['Today', 'Yesterday', 'Earlier'];

    return ListView(
      padding : const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final label in order)
          if (grouped.containsKey(label)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child  : Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize    : 11,
                      fontWeight  : FontWeight.w700,
                      color       : kTextMuted,
                      letterSpacing: 0.9)),
            ),
            ...grouped[label]!.asMap().entries.map((e) {
              final n     = e.value;
              final index = _notifications.indexWhere(
                      (x) => x['id'] == n['id']);
              return _NotifTile(
                notif   : n,
                onTap   : () => _markRead(n['id'], index),
                onDelete: () => _deleteNotification(n['id']),
              );
            }),
          ],
      ],
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children    : [
        Icon(Icons.notifications_none_rounded,
            size: 60, color: kBorder),
        const SizedBox(height: 16),
        const Text('All caught up!',
            style: TextStyle(
                fontSize  : 17,
                fontWeight: FontWeight.w700,
                color     : kTextSecondary)),
        const SizedBox(height: 6),
        const Text('No notifications yet.',
            style: TextStyle(fontSize: 13, color: kTextMuted)),
      ],
    ),
  );
}

// ─── Single notification tile ─────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback          onTap;
  final VoidCallback          onDelete;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = notif['opened'] == false;
    final meta     = _typeMeta[notif['notif_type']] ?? _typeMeta['goal']!;
    final sentAt   = DateTime.tryParse(notif['sent_at'] ?? '');
    final timeAgo  = sentAt != null ? _timeAgo(sentAt) : '';

    return Dismissible(
      key        : Key('notif_${notif['id']}'),
      direction  : DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background : Container(
        margin    : const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color       : kRed,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding  : const EdgeInsets.only(right: 20),
        child    : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(height: 3),
            Text('Delete',
                style: TextStyle(
                    color     : Colors.white,
                    fontSize  : 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: isUnread ? onTap : null,
        child: Container(
          margin    : const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color       : isUnread ? kEmeraldSoft : kSurface,
            borderRadius: BorderRadius.circular(14),
            border      : isUnread
                ? const Border(left: BorderSide(color: kEmerald, width: 3))
                : null,
            boxShadow   : const [
              BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child  : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width : 40,
                height: 40,
                decoration: BoxDecoration(
                  color       : (meta['color'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(meta['icon'] as IconData,
                    color: meta['color'] as Color, size: 20),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif['title'] ?? '',
                              style: TextStyle(
                                  fontSize  : 14,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color     : kTextPrimary)),
                        ),
                        Text(timeAgo,
                            style: const TextStyle(
                                fontSize: 11, color: kTextMuted)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(notif['body'] ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: kTextSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}