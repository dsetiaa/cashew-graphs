import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:cashew_graphs/database/tables.dart';

class GeneralPieChart extends StatefulWidget {
  const GeneralPieChart({
    required this.data,
    required this.totalSpent,
    this.showSubcategories = true,
    super.key,
  });

  final List<CategoryWithTotalAndSubs> data;
  final double totalSpent;
  final bool showSubcategories;

  @override
  State<StatefulWidget> createState() => _GeneralPieChartState();
}

class _GeneralPieChartState extends State<GeneralPieChart> {
  int touchedInnerIndex = -1;
  int touchedOuterIndex = -1;

  // Chart dimensions
  static const double innerCenterRadius = 60.0;
  static const double innerRingRadius = 45.0;
  static const double ringGap = 3.0;
  static const double outerRingRadius = 30.0;

  // Calculated bounds
  double get innerRingStart => innerCenterRadius;
  double get innerRingEnd => innerCenterRadius + innerRingRadius;
  double get outerRingStart => innerRingEnd + ringGap;
  double get outerRingEnd => outerRingStart + outerRingRadius;

  Color _getCategoryColor(TransactionCategory category) {
    return category.colour != null
        ? Color(int.parse(category.colour!.substring(4), radix: 16) + 0xFF000000)
        : Theme.of(context).colorScheme.primary;
  }

  Color _getSubcategoryColor(Color parentColor, int index, int total, bool isUncategorized) {
    if (isUncategorized) {
      return parentColor;
    }
    final hsl = HSLColor.fromColor(parentColor);
    final lightnessOffset = 0.1 + (index * 0.12);
    final newLightness = (hsl.lightness + lightnessOffset).clamp(0.3, 0.85);
    return hsl.withLightness(newLightness).toColor();
  }

  List<({CategoryWithTotal sub, int parentIndex, Color parentColor})> _getFlattenedSubcategories() {
    List<({CategoryWithTotal sub, int parentIndex, Color parentColor})> result = [];
    for (int i = 0; i < widget.data.length; i++) {
      final parentColor = _getCategoryColor(widget.data[i].category);
      for (final sub in widget.data[i].subcategories) {
        result.add((sub: sub, parentIndex: i, parentColor: parentColor));
      }
    }
    return result;
  }

  // Calculate which segment was touched based on angle
  int _getSegmentAtAngle(double angle, List<double> segmentValues) {
    if (segmentValues.isEmpty) return -1;

    final total = segmentValues.fold<double>(0, (sum, v) => sum + v);
    if (total == 0) return -1;

    // Normalize angle to 0-360, starting from -90 degrees (top)
    double normalizedAngle = (angle + 90) % 360;
    if (normalizedAngle < 0) normalizedAngle += 360;

    double accumulated = 0;
    for (int i = 0; i < segmentValues.length; i++) {
      final segmentAngle = (segmentValues[i] / total) * 360;
      accumulated += segmentAngle;
      if (normalizedAngle <= accumulated) {
        return i;
      }
    }
    return segmentValues.length - 1;
  }

  void _handleTap(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Calculate angle in degrees
    double angle = math.atan2(dy, dx) * 180 / math.pi;

    final flattenedSubs = _getFlattenedSubcategories();

    setState(() {
      // Check which ring was touched based on distance from center
      // Use generous bounds for better touch detection
      final showOuterRing = widget.showSubcategories && flattenedSubs.isNotEmpty;
      if (showOuterRing && distance >= outerRingStart - 5 && distance <= outerRingEnd + 20) {
        // Outer ring touched
        final values = flattenedSubs.map((s) => s.sub.total).toList();
        touchedOuterIndex = _getSegmentAtAngle(angle, values);
        touchedInnerIndex = -1;
      } else if (distance >= innerRingStart - 10 && distance < (showOuterRing ? outerRingStart - 5 : innerRingEnd + 20)) {
        // Inner ring touched
        final values = widget.data.map((d) => d.total).toList();
        touchedInnerIndex = _getSegmentAtAngle(angle, values);
        touchedOuterIndex = -1;
      } else if (distance < innerRingStart - 10) {
        // Center tapped - clear selection
        touchedInnerIndex = -1;
        touchedOuterIndex = -1;
      }
      // If tapped way outside, don't change selection
    });
  }

  @override
  Widget build(BuildContext context) {
    final flattenedSubs = _getFlattenedSubcategories();
    final showOuterRing = widget.showSubcategories && flattenedSubs.isNotEmpty;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTap(details.localPosition, constraints.biggest),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring (subcategories)
                    if (showOuterRing)
                      IgnorePointer(
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(enabled: false),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 1,
                            centerSpaceRadius: outerRingStart,
                            sections: _buildOuterSections(flattenedSubs),
                            startDegreeOffset: -90,
                          ),
                        ),
                      ),
                    // Inner ring (main categories)
                    IgnorePointer(
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(enabled: false),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: innerCenterRadius,
                          sections: _buildInnerSections(),
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    // Center content
                    IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '₹${widget.totalSpent.toStringAsFixed(0)}',
                            style: AppTypography.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTooltip(flattenedSubs),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: List.generate(
            widget.data.length >= 5 ? 5 : widget.data.length,
            (i) => _buildLegendItem(i),
          ),
        ),
      ],
    );
  }

  Widget _buildTooltip(List<({CategoryWithTotal sub, int parentIndex, Color parentColor})> flattenedSubs) {
    String? label;
    double? amount;
    double? percent;
    Color? color;

    if (touchedInnerIndex >= 0 && touchedInnerIndex < widget.data.length) {
      final item = widget.data[touchedInnerIndex];
      label = item.category.name;
      amount = item.total;
      percent = widget.totalSpent > 0 ? (item.total / widget.totalSpent * 100) : 0;
      color = _getCategoryColor(item.category);
    } else if (touchedOuterIndex >= 0 && touchedOuterIndex < flattenedSubs.length) {
      final item = flattenedSubs[touchedOuterIndex];
      final parentName = widget.data[item.parentIndex].category.name;
      label = item.sub.isUncategorized ? '$parentName - Uncategorised' : item.sub.category.name;
      amount = item.sub.total;
      percent = widget.totalSpent > 0 ? (item.sub.total / widget.totalSpent * 100) : 0;
      final parentCategory = widget.data[item.parentIndex];
      final subIndex = parentCategory.subcategories.indexOf(item.sub);
      color = _getSubcategoryColor(
        item.parentColor,
        subIndex,
        parentCategory.subcategories.length,
        item.sub.isUncategorized,
      );
    }

    if (label == null) {
      return const SizedBox(height: 40);
    }

    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '₹${amount!.toStringAsFixed(0)} (${percent!.toStringAsFixed(1)}%)',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildInnerSections() {
    return List.generate(widget.data.length, (i) {
      final bool isTouched = i == touchedInnerIndex;
      final double radius = isTouched ? innerRingRadius + 5 : innerRingRadius;
      final Color color = _getCategoryColor(widget.data[i].category);

      return PieChartSectionData(
        color: color,
        value: widget.totalSpent == 0
            ? 1
            : (widget.data[i].total / widget.totalSpent).abs(),
        title: '',
        radius: radius,
        borderSide: isTouched
            ? const BorderSide(color: AppColors.contentColorWhite, width: 2)
            : BorderSide.none,
      );
    });
  }

  List<PieChartSectionData> _buildOuterSections(
    List<({CategoryWithTotal sub, int parentIndex, Color parentColor})> flattenedSubs,
  ) {
    return List.generate(flattenedSubs.length, (i) {
      final item = flattenedSubs[i];
      final bool isTouched = i == touchedOuterIndex;
      final double radius = isTouched ? outerRingRadius + 5 : outerRingRadius;

      final parentCategory = widget.data[item.parentIndex];
      final subIndex = parentCategory.subcategories.indexOf(item.sub);

      final Color color = _getSubcategoryColor(
        item.parentColor,
        subIndex,
        parentCategory.subcategories.length,
        item.sub.isUncategorized,
      );

      return PieChartSectionData(
        color: color,
        value: widget.totalSpent == 0
            ? 1
            : (item.sub.total / widget.totalSpent).abs(),
        title: '',
        radius: radius,
        borderSide: isTouched
            ? const BorderSide(color: AppColors.contentColorWhite, width: 2)
            : BorderSide.none,
      );
    });
  }

  Widget _buildLegendItem(int index) {
    final color = _getCategoryColor(widget.data[index].category);
    final isSelected = touchedInnerIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          touchedInnerIndex = touchedInnerIndex == index ? -1 : index;
          touchedOuterIndex = -1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              widget.data[index].category.name,
              style: AppTypography.legendText.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
