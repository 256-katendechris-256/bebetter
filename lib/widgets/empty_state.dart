import 'package:flutter/material.dart';
import '../config/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: const Color(0xFFD1D5DB)),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(sub,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
