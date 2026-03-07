import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatefulWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  State<MonthSelector> createState() => MonthSelectorState();
}

class MonthSelectorState extends State<MonthSelector> {
  late final ScrollController _scrollController;
  late final DateTime _referenceMonth;

  static const _monthItemWidth = 72.0;
  static const _monthCount = 1200;

  int get _currentMonthIndex => _monthCount - 1;

  DateTime _monthFromIndex(int index) {
    final offset = index - _currentMonthIndex;
    return DateTime(_referenceMonth.year, _referenceMonth.month + offset);
  }

  int _indexFromMonth(DateTime month) {
    return _currentMonthIndex +
        (month.year - _referenceMonth.year) * 12 +
        (month.month - _referenceMonth.month);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _referenceMonth = DateTime(now.year, now.month);
    final initialOffset = _indexFromMonth(widget.selectedMonth) * _monthItemWidth;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToMonth(widget.selectedMonth, animate: false));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToMonth(DateTime month, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final index = _indexFromMonth(month);
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (index * _monthItemWidth - screenWidth / 2 + _monthItemWidth / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _monthCount,
        itemExtent: _monthItemWidth,
        itemBuilder: (context, index) {
          final month = _monthFromIndex(index);
          final isSelected = month.year == widget.selectedMonth.year &&
              month.month == widget.selectedMonth.month;
          final isCurrentMonth = index == _currentMonthIndex;
          final label = isCurrentMonth
              ? 'Now'
              : (month.year == _referenceMonth.year
                  ? DateFormat('MMM').format(month)
                  : DateFormat('MMM yy').format(month));
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => widget.onMonthSelected(month),
              child: Container(
                width: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.itemsBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.chartBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.contentColorBlack
                        : AppColors.mainTextColor2,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
