import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;

    switch (status) {
      case TransactionStatus.lunas:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
      case TransactionStatus.pending:
        bg = AppColors.primaryRed.withValues(alpha: 0.12);
        fg = AppColors.primaryRed;
      case TransactionStatus.splitBill:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
      case TransactionStatus.refund:
      case TransactionStatus.batal:
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
