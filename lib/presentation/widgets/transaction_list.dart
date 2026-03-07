import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatefulWidget {
  final ({
    double totalSpend,
    int transactionCount,
    List<TransactionWithCategory> filteredTransactions,
    List<TransactionWithCategory> allTransactions,
    List<TransactionCategory> categories,
  })? data;

  const TransactionList({
    super.key,
    required this.data,
  });

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  static const _pageSize = 50;
  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _visibleCount = _pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.itemsBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.chartBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final transactions = widget.data!.filteredTransactions;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');

    // Build items list only up to _visibleCount transactions
    final items = <Object>[];
    String? lastDate;
    int txCount = 0;
    for (final twc in transactions) {
      if (txCount >= _visibleCount) break;
      final dateStr = dateFormat.format(twc.transaction.dateCreated);
      if (dateStr != lastDate) {
        items.add(dateStr);
        lastDate = dateStr;
      }
      items.add(twc);
      txCount++;
    }
    final hasMore = txCount < transactions.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.itemsBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.chartBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transactions', style: AppTypography.chartTitle),
          const SizedBox(height: AppSpacing.md),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text('No transactions found', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _visibleCount += _pageSize;
                          });
                        },
                        child: Text(
                          'Show more (${transactions.length - txCount} remaining)',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final item = items[index];
                if (item is String) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : AppSpacing.md,
                      bottom: AppSpacing.xs,
                    ),
                    child: Text(item, style: AppTypography.labelLarge),
                  );
                }
                final twc = item as TransactionWithCategory;
                final t = twc.transaction;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: AppTypography.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${twc.category.name}${twc.subCategory != null ? ' > ${twc.subCategory!.name}' : ''}',
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${t.income ? '+' : '-'}${currencyFormat.format(t.amount.abs())}',
                          style: AppTypography.bodyLarge.copyWith(
                            color: t.income ? AppColors.contentColorGreen : AppColors.contentColorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
