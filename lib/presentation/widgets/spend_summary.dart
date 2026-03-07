import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendSummary extends StatelessWidget {
  final Future<({double totalSpend, int transactionCount, List<TransactionWithCategory> transactions})>? summaryFuture;

  const SpendSummary({
    super.key,
    required this.summaryFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({double totalSpend, int transactionCount, List<TransactionWithCategory> transactions})>(
      future: summaryFuture,
      builder: (context, snapshot) {
        final totalSpend = snapshot.data?.totalSpend;
        final transactionCount = snapshot.data?.transactionCount;
        final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.itemsBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.chartBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Total Spend', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      totalSpend != null
                          ? currencyFormat.format(totalSpend)
                          : '—',
                      style: AppTypography.titleLarge,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.chartBorder.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Transactions', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      transactionCount != null
                          ? NumberFormat('#,###').format(transactionCount)
                          : '—',
                      style: AppTypography.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
