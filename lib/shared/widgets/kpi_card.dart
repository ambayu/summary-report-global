import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool highlight;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: highlight
              ? const LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.primaryDark],
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: highlight ? Colors.white : AppColors.primaryRed),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: highlight ? Colors.white70 : AppColors.mutedGray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlight ? Colors.white : AppColors.textDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: highlight ? Colors.white70 : AppColors.mutedGray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
