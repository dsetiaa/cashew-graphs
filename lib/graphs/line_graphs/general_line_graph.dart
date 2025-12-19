import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:flutter/material.dart';

class _LineChart extends StatefulWidget {
  const _LineChart({
    // required this.spots,
    required this.graphLines,
    required this.maxX,
    required this.maxY,
    required this.leftTitleWidgets,
    required this.bottomTitleWidgets,
    required this.getLineTouchToolTipHeadingFunction,
    required this.onTouchedLines,
    super.key
    // this.onTouchedIndex
  });

  // final List<List<FlSpot>> spots;
  final List<LineChartBarData> graphLines;
  final double maxX;
  final double maxY;
  final GetTitleWidgetFunction leftTitleWidgets;
  final GetTitleWidgetFunction bottomTitleWidgets;
  final Function getLineTouchToolTipHeadingFunction;
  final Function(List<LineBarSpot>?) onTouchedLines;
  // final Function(int?)? onTouchedIndex;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  int? touchedValue;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      chartData,
      duration: const Duration(milliseconds: 250),
    );
  }

  LineChartData get chartData => LineChartData(
    lineTouchData: lineTouchData,
    gridData: gridData,
    titlesData: titlesData2,
    borderData: borderData,
    lineBarsData: widget.graphLines,
    minX: 0,
    maxX: widget.maxX,
    maxY: widget.maxY,
    minY: 0,
  );

  LineTouchData get lineTouchData => LineTouchData(
    handleBuiltInTouches: true,
    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {

      if (touchResponse != null && touchResponse.lineBarSpots != null) {
        // Filter out transparent lines and sort by y value
        final validSpots = touchResponse.lineBarSpots!
            .where((spot) => spot.bar.color != Colors.transparent)
            .toList()
          ..sort((a, b) => b.y.compareTo(a.y));

        // Pass top 3 lines to parent
        widget.onTouchedLines(validSpots.toList());
      } else {
        widget.onTouchedLines(null);
      }
    },
    touchTooltipData: LineTouchTooltipData(
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      showOnTopOfTheChartBoxArea: true,
      tooltipPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      // tooltipMargin: AppSpacing.sm,
      getTooltipColor: (touchedSpot) => AppColors.chartTooltipBackground.withValues(alpha: 0.7),
      tooltipBorder: BorderSide(
        color: AppColors.primary.withOpacity(0.2),
        width: 1,
      ),
      getTooltipItems: (List<LineBarSpot> touchedSpots) {
        return touchedSpots.asMap().entries.map((entry) {
          LineBarSpot lineBarSpot = entry.value;
          int index = entry.key;
          if (lineBarSpot.bar.color == Colors.transparent) {
            return null;
          }

          if (!(index < 3 || lineBarSpot.y > 0)) {
            return null;
          }

          String lineTouchToolTipHeading = "${widget.getLineTouchToolTipHeadingFunction(lineBarSpot.x)}\n";

          return LineTooltipItem(
            "",
            const TextStyle(),
            children: [
              if (index == 0)
                TextSpan(
                  text: lineTouchToolTipHeading,
                  style: AppTypography.chartTooltipTitle,
                ),
              TextSpan(
                //TODO: implement convert to money, checkout provider
                // text: convertToMoney(
                //     Provider.of<AllWallets>(context, listen: false),
                //     lineBarSpot.y == -1e-14 ? 0 : lineBarSpot.y),
                text: (index < 3 || lineBarSpot.y > 0) ? "₹${lineBarSpot.y == -1e-14 ? 0 : lineBarSpot.y.toStringAsFixed(2)}" : "",
                style: AppTypography.chartTooltipValue.copyWith(
                  color: lineBarSpot.bar.color,
                  height: index == 0 && touchedSpots.length > 1 ? 1.8 : null,
                ),
              ),
            ],
          );
        }).toList();
      },
    ),
    enabled: true,
    // getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
    //   return spotIndexes.map((spotIndex) {
    //     return TouchedSpotIndicatorData(
    //       FlLine(
    //         color: AppColors.primary.withOpacity(0.3),
    //         strokeWidth: 1,
    //         dashArray: [5, 5],
    //       ),
    //       FlDotData(
    //         getDotPainter: (spot, percent, barData, index) {
    //           return FlDotCirclePainter(
    //             radius: 5,
    //             color: barData.color ?? AppColors.primary,
    //             strokeWidth: 2,
    //             strokeColor: AppColors.itemsBackground,
    //           );
    //         },
    //       ),
    //     );
    //   }).toList();
    // },
  );

  FlTitlesData get titlesData2 => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: bottomTitles,
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: leftTitles(),
    ),
  );

  SideTitles leftTitles() => SideTitles(
    getTitlesWidget: widget.leftTitleWidgets,
    showTitles: true,
    interval: getStepSizeInScale(widget.maxY, getScaleInPowerOf10(widget.maxY)).toDouble(),
    reservedSize: 40,
  );

  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 32,
    interval: 1,
    getTitlesWidget: widget.bottomTitleWidgets,
  );

  FlGridData get gridData => FlGridData(
    show: true,
    drawVerticalLine: true,
    drawHorizontalLine: true,
    // horizontalInterval: getStepSizeInScale(widget.maxY, getScaleInPowerOf10(widget.maxY)).toDouble(),
    // verticalInterval: getS,
    getDrawingHorizontalLine: (value) {
      return FlLine(
        color: AppColors.mainGridLineColor,
        strokeWidth: 1,
        dashArray: [5, 5],
      );
    },
    getDrawingVerticalLine: (value) {
      return FlLine(
        color: AppColors.mainGridLineColor,
        strokeWidth: 1,
        dashArray: [5, 5],
      );
    },
  );

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: const Border(
      bottom: BorderSide(
        color: AppColors.chartBorder,
        width: 1,
      ),
      left: BorderSide(
        color: AppColors.chartBorder,
        width: 1,
      ),
      right: BorderSide.none,
      top: BorderSide.none,
    ),
  );
}

class GeneralLineChart extends StatefulWidget {
  const GeneralLineChart({
    required this.graphTitle,
    required this.graphLines,
    required this.maxX,
    required this.maxY,
    required this.leftTitleWidgets,
    required this.bottomTitleWidgets,
    required this.getLineTouchToolTipHeadingFunction,
    required this.lineLabels, // Optional line labels
    super.key
  });

  final String graphTitle;
  final List<LineChartBarData> graphLines;
  final double maxX;
  final double maxY;
  final GetTitleWidgetFunction leftTitleWidgets;
  final GetTitleWidgetFunction bottomTitleWidgets;
  final Function getLineTouchToolTipHeadingFunction;
  final List<String> lineLabels; // Labels for each line in graphLines

  @override
  State<StatefulWidget> createState() => GeneralLineChartState();
}

class GeneralLineChartState extends State<GeneralLineChart> {
  List<LineBarSpot>? touchedLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        AspectRatio(
          aspectRatio: 3 / 2,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md, left: AppSpacing.sm),
            child: _LineChart(
              graphLines: widget.graphLines,
              maxX: widget.maxX,
              maxY: widget.maxY,
              leftTitleWidgets: widget.leftTitleWidgets,
              bottomTitleWidgets: widget.bottomTitleWidgets,
              getLineTouchToolTipHeadingFunction: widget.getLineTouchToolTipHeadingFunction,
              onTouchedLines: (lines) {
                setState(() {
                  touchedLines = lines;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Animated Legend
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: touchedLines != null && touchedLines!.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: touchedLines!.map((spot) {
                      final lineIndex = spot.barIndex;
                      final label = widget.lineLabels[lineIndex];
                      if(spot.y == 0 && lineIndex >= 3) return Container();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: spot.bar.color?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: spot.bar.color?.withOpacity(0.3) ?? Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 3,
                              decoration: BoxDecoration(
                                color: spot.bar.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '$label: ₹${spot.y == -1e-14 ? "0" : spot.y.toStringAsFixed(2)}',
                              style: AppTypography.legendText.copyWith(
                                color: spot.bar.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.graphTitle,
          style: AppTypography.chartTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}