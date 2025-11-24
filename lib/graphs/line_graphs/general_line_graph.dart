import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';
import 'package:cashew_graphs/logic/helpers.dart';
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
  // final Function(int?)? onTouchedIndex;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  int? touchedValue = null;


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

            String lineTouchToolTipHeading = "${widget.getLineTouchToolTipHeadingFunction(lineBarSpot.x)}\n";

            return LineTooltipItem(
              "",
              TextStyle(),
              children: [
                // if (dateRange != null &&
                //     index == 0)
                if (index == 0)
                  TextSpan(
                    text: lineTouchToolTipHeading,
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

  FlGridData get gridData => const FlGridData(show: true);

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: Border(
      bottom: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3), width: 3,),
      left: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3), width: 3),
      right: const BorderSide(color: Colors.transparent),
      top: const BorderSide(color: Colors.transparent),
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
    super.key
  });

  final String graphTitle;
  final List<LineChartBarData> graphLines;
  final double maxX;
  final double maxY;
  final GetTitleWidgetFunction leftTitleWidgets;
  final GetTitleWidgetFunction bottomTitleWidgets;
  final Function getLineTouchToolTipHeadingFunction;

  @override
  State<StatefulWidget> createState() => GeneralLineChartState();
}

class GeneralLineChartState extends State<GeneralLineChart> {

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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 6),
                  child: _LineChart(graphLines: widget.graphLines,
                    maxX: widget.maxX, maxY: widget.maxY,
                    leftTitleWidgets: widget.leftTitleWidgets,
                    bottomTitleWidgets: widget.bottomTitleWidgets,
                    getLineTouchToolTipHeadingFunction: widget.getLineTouchToolTipHeadingFunction,
                  ),
                ),
              ),
              const SizedBox(
                height: 17,
              ),
              Text(
                widget.graphTitle,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 17,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
