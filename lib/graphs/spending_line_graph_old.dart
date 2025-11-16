import 'package:fl_chart/fl_chart.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:flutter/material.dart';

class _LineChart extends StatefulWidget {
  const _LineChart({
    required this.isShowingMainData,
    required this.spots
    // this.onTouchedIndex
  });

  final bool isShowingMainData;
  final List<List<FlSpot>> spots;
  // final Function(int?)? onTouchedIndex;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  // bool loaded = false;
  int? touchedValue = null;

  // @override
  // void initState() {
  //   super.initState();
  //   Future.delayed(Duration.zero, () {
  //     setState(() {
  //       loaded = true;
  //     });
  //   });
  // }


  @override
  Widget build(BuildContext context) {
    return LineChart(
      widget.isShowingMainData? sampleData1: sampleData2,
      duration: const Duration(milliseconds: 250),
    );
  }

  LineChartData get sampleData1 => LineChartData(
    lineTouchData: lineTouchData1,
    gridData: gridData,
    titlesData: titlesData1,
    borderData: borderData,
    lineBarsData: lineBarsData1,
    minX: 0,
    maxX: 14,
    maxY: 4,
    minY: 0,
  );

  LineChartData get sampleData2 => LineChartData(
    lineTouchData: lineTouchData3,
    gridData: gridData,
    titlesData: titlesData2,
    borderData: borderData,
    lineBarsData: lineBarsData2,
    minX: 0,
    maxX: 14,
    maxY: 6,
    minY: 0,
  );

  LineTouchData get lineTouchData1 => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (touchedSpot) =>
          Colors.blueGrey.withValues(alpha: 0.8),
    ),
  );

  FlTitlesData get titlesData1 => FlTitlesData(
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

  List<LineChartBarData> get lineBarsData1 => [
    lineChartBarData1_1,
    lineChartBarData1_2,
    lineChartBarData1_3,
  ];

  LineTouchData get lineTouchData2 => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (touchedSpot) =>
          Colors.redAccent.withValues(alpha: 0.1),
      getTooltipItems: (List<LineBarSpot> touchedSpots) {
        if (touchedSpots.isNotEmpty) {
          return [
            LineTooltipItem(touchedSpots[0].x.toString(), TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold))
          ] + touchedSpots.map((LineBarSpot touchedSpot) {
            final textStyle = TextStyle(
              color: touchedSpot.bar.gradient?.colors.first ??
                  touchedSpot.bar.color ??
                  Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );
            return LineTooltipItem(touchedSpot.y.toString(), textStyle);
          }).toList();
        } else {
          return touchedSpots.map((LineBarSpot touchedSpot) {
            final textStyle = TextStyle(
              color: touchedSpot.bar.gradient?.colors.first ??
                  touchedSpot.bar.color ??
                  Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );
            return LineTooltipItem(touchedSpot.y.toString(), textStyle);
          }).toList();
        }
        }
    ),
    enabled: true,
  );

  LineTouchData get lineTouchData3 => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (touchedSpot) =>
          Colors.redAccent.withValues(alpha: 0.1),
      getTooltipItems: (List<LineBarSpot> touchedSpots) {

        return touchedSpots.asMap().entries.map((entry) {
          LineBarSpot lineBarSpot = entry.value;
          int index = entry.key;
          // hide touch data for the overage line
          if (lineBarSpot.bar.color == Colors.transparent) {
            return null;
          }
          // DateTimeRange? dateRange;
          // try {
          //   List<DateTimeRange> dateRanges = widget.dateRanges
          //       .take(widget.spots.first.length)
          //       .toList();
          //   dateRange = dateRanges[
          //   dateRanges.length - 1 - (touchedSpots.first.x).round()];
          // } catch (e) {
          //   print(
          //       "Error with date ranges passed in, length mismatched that of lines: " +
          //           e.toString());
          // }

          String startAndEndDateString = "DATE: ${lineBarSpot.x}\n";
          // if (dateRange != null) {
          //   String startDateString =
          //   getWordedDateShort(dateRange.start);
          //   String endDateString = getWordedDateShort(dateRange.end);
          //   if (startDateString == endDateString) {
          //     startAndEndDateString = getWordedDateShort(
          //         dateRange.start,
          //         includeYear:
          //         dateRange.start.year != DateTime.now().year);
          //   } else {
          //     startAndEndDateString =
          //         getWordedDateShort(dateRange.start) +
          //             " – " +
          //             getWordedDateShort(dateRange.end,
          //                 includeYear: dateRange.end.year !=
          //                     DateTime.now().year);
          //   }
          //   startAndEndDateString = startAndEndDateString + "\n";
          // }

          return LineTooltipItem(
            "",
            TextStyle(),
            children: [
              // if (dateRange != null &&
              //     index == 0)
                if (index == 0)
                TextSpan(
                  text: startAndEndDateString,
                  style: TextStyle(
                    // color: getColor(context, "black").withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamilyFallback: ['Inter'],
                  ),
                ),
              TextSpan(
                //TODO: implement convert to money, checkout provider
                // text: convertToMoney(
                //     Provider.of<AllWallets>(context, listen: false),
                //     lineBarSpot.y == -1e-14 ? 0 : lineBarSpot.y),
                text: "${lineBarSpot.y == -1e-14 ? 0 : lineBarSpot.y}",
                style: TextStyle(
                  // color: lineBarSpot.bar.color ==
                  //     lightenPastel(widget.color, amount: 0.3)
                  //     ? getColor(context, "black").withOpacity(0.8)
                  //     : lineBarSpot.bar.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamilyFallback: ['Inter'],
                  height: index == 0 &&
                      touchedSpots.length > 1
                      ? 1.8
                      : null,
                ),
              ),
            ],
          );
        }).toList();
      // },
        if (touchedSpots.isNotEmpty) {
          return [
            LineTooltipItem(touchedSpots[0].x.toString(), TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold))
          ] + touchedSpots.map((LineBarSpot touchedSpot) {
            final textStyle = TextStyle(
              color: touchedSpot.bar.gradient?.colors.first ??
                  touchedSpot.bar.color ??
                  Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );
            return LineTooltipItem(touchedSpot.y.toString(), textStyle);
          }).toList();
        } else {
          return touchedSpots.map((LineBarSpot touchedSpot) {
            final textStyle = TextStyle(
              color: touchedSpot.bar.gradient?.colors.first ??
                  touchedSpot.bar.color ??
                  Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );
            return LineTooltipItem(touchedSpot.y.toString(), textStyle);
          }).toList();
        }
        }
    ),
    enabled: true,
  );

  // LineTouchData get myLineTouchData => LineTouchData(
  //   touchCallback:
  //       (FlTouchEvent event, LineTouchResponse? touchResponse) {
  //     if (!event.isInterestedForInteractions || touchResponse == null) {
  //       if (touchedValue != null) if (widget.onTouchedIndex != null)
  //         widget.onTouchedIndex!(null);
  //       touchedValue = null;
  //       return;
  //     }
  //
  //     // Correct the x value, because not all loaded periods may be shown in the graph
  //     // because we remove the zero values
  //     double value = (widget.originalDateRanges.length -
  //         (widget.spots.firstOrNull ?? []).length) +
  //         touchResponse.lineBarSpots![0].x;
  //     if (touchedValue != value.toInt()) if (widget.onTouchedIndex !=
  //         null) widget.onTouchedIndex!(value.toInt());
  //
  //     if (event.runtimeType == FlLongPressStart) {
  //       HapticFeedback.selectionClick();
  //     } else if (touchedValue != value.toInt() &&
  //         (event.runtimeType == FlLongPressMoveUpdate ||
  //             event.runtimeType == FlPanUpdateEvent)) {
  //       HapticFeedback.selectionClick();
  //     }
  //
  //     touchedValue = value.toInt();
  //   },
  //   enabled: true,
  //   touchSpotThreshold: 1000,
  //   getTouchedSpotIndicator:
  //       (LineChartBarData barData, List<int> spotIndexes) {
  //     return spotIndexes.map((index) {
  //       return TouchedSpotIndicatorData(
  //         FlLine(
  //           color: (widget.extraCategorySpots.keys.length <= 0
  //               ? widget.color
  //               : barData.color) ??
  //               Theme.of(context).colorScheme.primary,
  //           strokeWidth: 2,
  //           dashArray: [2, 2],
  //         ),
  //         FlDotData(
  //           show: true,
  //           getDotPainter: (spot, percent, barData, index) =>
  //               FlDotCirclePainter(
  //                 radius: 3,
  //                 color: (widget.extraCategorySpots.keys.length <= 0 &&
  //                     widget.lineColors == null
  //                     ? widget.color.withOpacity(0.9)
  //                     : barData.color) ??
  //                     Theme.of(context).colorScheme.primary,
  //                 strokeWidth: 2,
  //                 strokeColor:
  //                 (widget.extraCategorySpots.keys.length <= 0 &&
  //                     widget.lineColors == null
  //                     ? widget.color.withOpacity(0.9)
  //                     : barData.color) ??
  //                     Theme.of(context).colorScheme.primary,
  //               ),
  //         ),
  //       );
  //     }).toList();
  //   },
  //   touchTooltipData: LineTouchTooltipData(
  //     maxContentWidth: 170,
  //     getTooltipColor: (_) =>
  //     widget.extraCategorySpots.keys.length <= 0 &&
  //         (widget.lineColors == null ||
  //             (widget.lineColors?.length ?? 0) <= 0)
  //         ? widget.color.withOpacity(0.7)
  //         : dynamicPastel(
  //       context,
  //       getColor(context, "white"),
  //       inverse: true,
  //       amountLight: 0.2,
  //       amountDark: 0.05,
  //     ).withOpacity(0.8),
  //     tooltipRoundedRadius: 8,
  //     fitInsideVertically: true,
  //     fitInsideHorizontally: true,
  //     tooltipPadding:
  //     EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 6),
  //     getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
  //       return lineBarsSpot.asMap().entries.map((entry) {
  //         LineBarSpot lineBarSpot = entry.value;
  //         int index = entry.key;
  //         // hide touch data for the overage line
  //         if (lineBarSpot.bar.color == Colors.transparent) {
  //           return null;
  //         }
  //         DateTimeRange? dateRange;
  //         try {
  //           List<DateTimeRange> dateRanges = widget.dateRanges
  //               .take(widget.spots.first.length)
  //               .toList();
  //           dateRange = dateRanges[
  //           dateRanges.length - 1 - (lineBarsSpot.first.x).round()];
  //         } catch (e) {
  //           print(
  //               "Error with date ranges passed in, length mismatched that of lines: " +
  //                   e.toString());
  //         }
  //
  //         String startAndEndDateString = "";
  //         if (dateRange != null && widget.showDateOnHover) {
  //           String startDateString =
  //           getWordedDateShort(dateRange.start);
  //           String endDateString = getWordedDateShort(dateRange.end);
  //           if (startDateString == endDateString) {
  //             startAndEndDateString = getWordedDateShort(
  //                 dateRange.start,
  //                 includeYear:
  //                 dateRange.start.year != DateTime.now().year);
  //           } else {
  //             startAndEndDateString =
  //                 getWordedDateShort(dateRange.start) +
  //                     " – " +
  //                     getWordedDateShort(dateRange.end,
  //                         includeYear: dateRange.end.year !=
  //                             DateTime.now().year);
  //           }
  //           startAndEndDateString = startAndEndDateString + "\n";
  //         }
  //
  //         return LineTooltipItem(
  //           "",
  //           TextStyle(),
  //           children: [
  //             if (dateRange != null &&
  //                 index == 0)
  //               TextSpan(
  //                 text: startAndEndDateString,
  //                 style: TextStyle(
  //                   color: getColor(context, "black").withOpacity(0.8),
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 12,
  //                   fontFamilyFallback: ['Inter'],
  //                 ),
  //               ),
  //             TextSpan(
  //               text: convertToMoney(
  //                   Provider.of<AllWallets>(context, listen: false),
  //                   lineBarSpot.y == -1e-14 ? 0 : lineBarSpot.y),
  //               style: TextStyle(
  //                 color: lineBarSpot.bar.color ==
  //                     lightenPastel(widget.color, amount: 0.3)
  //                     ? getColor(context, "black").withOpacity(0.8)
  //                     : lineBarSpot.bar.color,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 12,
  //                 fontFamilyFallback: ['Inter'],
  //                 height: index == 0 &&
  //                     widget.showDateOnHover &&
  //                     lineBarsSpot.length > 1
  //                     ? 1.8
  //                     : null,
  //               ),
  //             ),
  //           ],
  //         );
  //       }).toList();
  //     },
  //   ),
  // )

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

  List<LineChartBarData> get lineBarsData2 => [
    lineChartBarData2_1,
    lineChartBarData2_2,
    lineChartBarData2_3,
  ];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = '1m';
        break;
      case 2:
        text = '2m';
        break;
      case 3:
        text = '3m';
        break;
      case 4:
        text = '5m';
        break;
      case 5:
        text = '6m';
        break;
      default:
        return Container();
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  SideTitles leftTitles() => SideTitles(
    getTitlesWidget: leftTitleWidgets,
    showTitles: true,
    interval: 1,
    reservedSize: 40,
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 2:
        text = const Text('SEPT', style: style);
        break;
      case 7:
        text = const Text('OCT', style: style);
        break;
      case 12:
        text = const Text('DEC', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: text,
    );
  }

  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 32,
    interval: 1,
    getTitlesWidget: bottomTitleWidgets,
  );

  FlGridData get gridData => const FlGridData(show: false);

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: Border(
      bottom: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.2), width: 4),
      left: const BorderSide(color: Colors.transparent),
      right: const BorderSide(color: Colors.transparent),
      top: const BorderSide(color: Colors.transparent),
    ),
  );

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
    isCurved: true,
    color: AppColors.contentColorGreen,
    barWidth: 8,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(1, 1),
      FlSpot(3, 1.5),
      FlSpot(5, 1.4),
      FlSpot(7, 3.4),
      FlSpot(10, 2),
      FlSpot(12, 2.2),
      FlSpot(13, 1.8),
    ],
  );

  LineChartBarData get lineChartBarData1_2 => LineChartBarData(
    isCurved: true,
    color: AppColors.contentColorPink,
    barWidth: 8,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: false,
      color: AppColors.contentColorPink.withValues(alpha: 0),
    ),
    spots: const [
      FlSpot(1, 1),
      FlSpot(3, 2.8),
      FlSpot(7, 1.2),
      FlSpot(10, 2.8),
      FlSpot(12, 2.6),
      FlSpot(13, 3.9),
    ],
  );

  LineChartBarData get lineChartBarData1_3 => LineChartBarData(
    isCurved: true,
    color: AppColors.contentColorCyan,
    barWidth: 8,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(1, 2.8),
      FlSpot(3, 1.9),
      FlSpot(6, 3),
      FlSpot(10, 1.3),
      FlSpot(13, 2.5),
    ],
  );

  LineChartBarData get lineChartBarData2_1 => LineChartBarData(
    isCurved: true,
    curveSmoothness: 0,
    color: AppColors.contentColorGreen.withValues(alpha: 0.5),
    barWidth: 3,
    isStrokeCapRound: false,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(1, 1),
      FlSpot(3, 4),
      FlSpot(5, 1.8),
      FlSpot(7, 5),
      FlSpot(10, 2),
      FlSpot(12, 2.2),
      FlSpot(13, 1.8),
    ],
  );

  LineChartBarData get lineChartBarData2_2 => LineChartBarData(
    isCurved: true,
    curveSmoothness: 0,
    color: AppColors.contentColorPink.withValues(alpha: 0.5),
    barWidth: 3,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(1, 1),
      FlSpot(3, 2.8),
      FlSpot(7, 1.2),
      FlSpot(10, 2.8),
      FlSpot(12, 2.6),
      FlSpot(13, 3.9),
    ],
  );

  LineChartBarData get lineChartBarData2_3 => LineChartBarData(
    isCurved: true,
    curveSmoothness: 0,
    color: AppColors.contentColorCyan.withValues(alpha: 0.5),
    barWidth: 3,
    isStrokeCapRound: false,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(1, 3.8),
      FlSpot(3, 1.9),
      FlSpot(6, 5),
      FlSpot(10, 3.3),
      FlSpot(13, 4.5),
    ],
  );
}

class LineChartSample1 extends StatefulWidget {
  const LineChartSample1({super.key});

  @override
  State<StatefulWidget> createState() => LineChartSample1State();
}

class LineChartSample1State extends State<LineChartSample1> {
  late bool isShowingMainData;

  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.23,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(
                height: 37,
              ),
              const Text(
                'Monthly Sales',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 37,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 6),
                  child: _LineChart(isShowingMainData: isShowingMainData, spots: [],),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color:
              Colors.white.withValues(alpha: isShowingMainData ? 1.0 : 0.5),
            ),
            onPressed: () {
              setState(() {
                isShowingMainData = !isShowingMainData;
              });
            },
          )
        ],
      ),
    );
  }
}