import 'package:flutter/material.dart';
import '../config/theme.dart';

class LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String xp;
  final bool isYou;

  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.name,
    required this.xp,
    this.isYou = false,
  });

  @override
  Widget build(BuildContext context) {
    final medal =
        rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.card(
        radius: 14,
        color: isYou ? AppColors.emeraldSoft : AppColors.surface,
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: medal != null
              ? Text(medal, style: const TextStyle(fontSize: 18))
              : Text('$rank',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isYou ? AppColors.emerald : AppColors.textMuted)),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isYou
                ? AppColors.emerald.withOpacity(0.15)
                : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(name[0].toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isYou ? AppColors.emerald : AppColors.textSecondary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(isYou ? '$name (you)' : name,
              style: TextStyle(
                  fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isYou ? AppColors.emerald : AppColors.textPrimary)),
        ),
        Text('$xp XP',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isYou ? AppColors.emerald : AppColors.textSecondary)),
      ]),
    );
  }
}
