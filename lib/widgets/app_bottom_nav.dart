import 'package:flutter/material.dart';
import '../config/theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.emoji_events_rounded, label: 'League'),
    (icon: Icons.menu_book_rounded, label: 'Library'),
    (icon: Icons.chat_bubble_rounded, label: 'Chat'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.ink,
        padding: EdgeInsets.only(
            top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final active = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.emerald.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabs[i].icon,
                        size: 24,
                        color: active
                            ? AppColors.emerald
                            : Colors.white.withOpacity(0.35)),
                    const SizedBox(height: 4),
                    Text(_tabs[i].label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color: active
                                ? AppColors.emerald
                                : Colors.white.withOpacity(0.35))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 4,
                      width: active ? 4 : 0,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: const BoxDecoration(
                          color: AppColors.emerald, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}
