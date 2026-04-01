import 'package:flutter/material.dart';
import '../config/theme.dart';

class AppTopBar extends StatelessWidget {
  final String displayName;
  final int streak;
  final bool streakLit;
  final int unreadCount;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;

  const AppTopBar({
    super.key,
    required this.displayName,
    required this.streak,
    required this.streakLit,
    required this.unreadCount,
    required this.onAvatarTap,
    required this.onNotificationTap,
    required this.onSearchTap,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.ink,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 18,
          right: 10,
          bottom: 14,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald.withOpacity(0.15),
                  border: Border.all(
                      color: AppColors.emerald.withOpacity(0.4), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_greeting(),
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.emerald.withOpacity(0.8),
                          fontStyle: FontStyle.italic)),
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Opacity(
                opacity: streakLit ? 1.0 : 0.3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 22)),
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: streakLit
                            ? const Color(0xFFFB923C)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _TopBarButton(
                icon: Icons.notifications_outlined,
                badgeCount: unreadCount,
                onTap: onNotificationTap),
            _TopBarButton(icon: Icons.search_rounded, onTap: onSearchTap),
          ],
        ),
      );
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;
  const _TopBarButton({
    required this.icon,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (badgeCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
