import 'package:flutter/material.dart';
import '../config/theme.dart';

class StatsHero extends StatelessWidget {
  final int totalXp;
  final int streak;
  final int booksRead;
  final String totalHours;

  const StatsHero({
    super.key,
    required this.totalXp,
    required this.streak,
    required this.booksRead,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('📊 ', style: TextStyle(fontSize: 18)),
              const Text('Your Reading Stats',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${totalHours}h read',
                    style: TextStyle(
                        color: AppColors.emerald.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              _StatPill(
                  value: '$totalXp',
                  label: 'XP Earned',
                  icon: '⭐',
                  bg: AppColors.goldSoft,
                  fg: AppColors.gold),
              const SizedBox(width: 10),
              _StatPill(
                  value: '$streak',
                  label: 'Day Streak',
                  icon: '🔥',
                  bg: const Color(0xFFFFF7ED),
                  fg: Colors.orange),
              const SizedBox(width: 10),
              _StatPill(
                  value: '$booksRead',
                  label: 'Books Read',
                  icon: '📚',
                  bg: AppColors.emeraldSoft,
                  fg: AppColors.emerald),
            ]),
          ],
        ),
      );
}

class _StatPill extends StatelessWidget {
  final String value, label, icon;
  final Color bg, fg;
  const _StatPill({
    required this.value,
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 5),
            Text(value,
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
          ]),
        ),
      );
}
