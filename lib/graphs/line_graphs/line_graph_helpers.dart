import 'dart:math';

import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/logic/constants.dart' as Constants;
import 'package:cashew_graphs/presentation/resources/app_typography.dart';

enum LineGraphType {
  perTimeUnit,
  aggregate
}

class LineGraphData{
  final double maxX;
  final double maxY;
  final List<LineChartBarData> graphLines;
  final List<String> lineLabels;

  LineGraphData({
    required this.maxX,
    required this.maxY,
    required this.graphLines,
    required this.lineLabels,
  });
}


/// Returns true if the category should be shown based on selection.
/// null = all categories, empty = none, non-empty = specific categories
bool showCategory({required String categoryPk, required Set<String>? selectedCategoriesPks}){
  if (selectedCategoriesPks == null) return true; // null = all selected
  return selectedCategoriesPks.contains(categoryPk);
}


Map<String,List<({DateTime date, double amount})>> getGraphLinesDict({
  required List<TransactionWithCategory> transactionsWithCategory,
  required TimeUnit timeUnit, required DateTime rangeStart, required DateTime rangeEnd,
  required bool showTotal, required Set<String>? selectedCategoriesPks})
{
  Map<String,List<({DateTime date, double amount})>> graphLinesDict = {};
  for(TransactionWithCategory twc in transactionsWithCategory) {
    if(!showCategory(categoryPk: twc.category.categoryPk,
        selectedCategoriesPks: selectedCategoriesPks)){
      continue;
    }
    for (String categoryPk in [twc.category.categoryPk, Constants.SUM_OF_ALL_CATEGORIES_DUMMY_PK]) {
      //If some data points exist for that category
      if (graphLinesDict[categoryPk] != null) {
        //Add transaction amount to point if both correspond to same time period
        if (isPartOfSameTimePeriod(a: graphLinesDict[categoryPk]!.last.date,
            b: twc.transaction.dateCreated, timeUnit: timeUnit)) {
          var lastRecord = graphLinesDict[categoryPk]!.last;
          graphLinesDict[categoryPk]![graphLinesDict[categoryPk]!.length -
              1] = (
          date: lastRecord.date,
          amount: lastRecord.amount + twc.transaction.amount
          );
        } else {
          // Add intermediate points
          while(!isPartOfSameTimePeriod(
              a: createNextSeriesDateTime(
                  previousDate: graphLinesDict[categoryPk]!.last.date,
                  timeUnit: timeUnit),
              b: twc.transaction.dateCreated, timeUnit: timeUnit))
          {
            graphLinesDict[categoryPk]!.add((
            date: createNextSeriesDateTime(
                previousDate: graphLinesDict[categoryPk]!.last.date,
                timeUnit: timeUnit),
            amount: 0
            ));
          }

          // Add transaction data point
          graphLinesDict[categoryPk]!.add((
          date: twc.transaction.dateCreated,
          amount: twc.transaction.amount
          ));
        }
      } else {
        // If no data points exist for that category

        // Add start point
        if(!isPartOfSameTimePeriod(a: rangeStart, b: twc.transaction.dateCreated, timeUnit: timeUnit)){
          graphLinesDict[categoryPk] = [(date: rangeStart, amount: 0)];

          while(!isPartOfSameTimePeriod(
              a: createNextSeriesDateTime(
                  previousDate: graphLinesDict[categoryPk]!.last.date,
                  timeUnit: timeUnit),
              b: twc.transaction.dateCreated, timeUnit: timeUnit))
          {
            graphLinesDict[categoryPk]!.add((
            date: createNextSeriesDateTime(
                previousDate: graphLinesDict[categoryPk]!.last.date,
                timeUnit: timeUnit),
            amount: 0
            ));
          }

          // Add transaction data
          graphLinesDict[categoryPk]!.add((date: twc.transaction.dateCreated, amount: twc.transaction.amount));
        }else {
          graphLinesDict[categoryPk] = [(date: twc.transaction.dateCreated, amount: twc.transaction.amount)];
        }


      }
    }
  }

  graphLinesDict.forEach((categoryPk, perTimeUnitDataList){
    while(!isPartOfSameTimePeriod(
        a: perTimeUnitDataList.last.date,
        b: rangeEnd, timeUnit: timeUnit)){
      perTimeUnitDataList.add((
      date: createNextSeriesDateTime(
          previousDate: perTimeUnitDataList.last.date,
          timeUnit: timeUnit),
      amount: 0
      ));
    }
  });
  return graphLinesDict;
}


int getXCoordinateForDateInRange({required DateTime date, required TimeUnit timeUnit,
  required DateTime rangeStart}){
  if(timeUnit == TimeUnit.day){
    return 1 + DateTime(date.year, date.month, date.day, 1).difference(DateTime(rangeStart.year, rangeStart.month, rangeStart.day)).inDays;
  } else if(timeUnit == TimeUnit.month){
    return 1 + (date.month-rangeStart.month) + (date.year-rangeStart.year)*12;
  } else{
    throw InvalidDataException("Invalid Time Unit");
  }
}

double getMaxX({required DateTime startDateTime, required DateTime endDateTime,
  required TimeUnit timeUnit})
{
  return getXCoordinateForDateInRange(date: endDateTime, timeUnit: timeUnit,
      rangeStart: startDateTime).toDouble() + 1;
}

LineGraphData getGraphLinesLineLabelsAndMaxY({
  required Map<String,List<({DateTime date, double amount})>> graphLinesDict,
  required List<TransactionCategory> categories, required DateTime startDateTime,
  required DateTime endDateTime, required TimeUnit timeUnit,
  required LineGraphType graphType, required bool showTotal,
  required Set<String>? selectedCategories})
{
  List<LineChartBarData> graphLines = [];
  List<String> lineLabels = [];
  double maxY = 0;

  graphLinesDict.forEach((categoryPk, perTimeUnitDataList){
    Color lineColor;
    String lineLabel;
    bool showLine;
    if(categoryPk != Constants.SUM_OF_ALL_CATEGORIES_DUMMY_PK) {
      TransactionCategory matchedCategory = categories.firstWhere((tk) =>
      tk.categoryPk == categoryPk);
      lineColor = (matchedCategory.colour != null)? Color(int.parse(matchedCategory.colour!.substring(4), radix: 16) + 0xFF000000) : Colors.white38; //TODO: make function to get color
      lineLabel = matchedCategory.name;
      showLine = showCategory(categoryPk: matchedCategory.categoryPk, selectedCategoriesPks: selectedCategories);
    } else {
      lineColor = Colors.black;
      lineLabel = "TOTAL";
      showLine = showTotal;
    }

    List<FlSpot> spots = [];
    perTimeUnitDataList.asMap().forEach((i, dataPoint){
      double yCoordinate = dataPoint.amount.abs();
      if(graphType == LineGraphType.aggregate){
        if(i > 0){
          yCoordinate += spots.last.y;
        }
      }
      if(showLine) maxY = max(yCoordinate, maxY);
      spots.add(FlSpot(
          getXCoordinateForDateInRange(date: dataPoint.date,
              timeUnit: timeUnit, rangeStart: startDateTime).toDouble(),
          yCoordinate
      ));
    });

    graphLines.add(
        LineChartBarData(
            show: showLine,
            isCurved: true,
            curveSmoothness: 0,
            color: lineColor.withOpacity(0.9),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: false,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.25),
                  lineColor.withOpacity(0.05),
                  lineColor.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            spots:spots
        )
    );

    lineLabels.add(lineLabel);
  });

  maxY = (maxY*1.02).ceilToDouble();
  return LineGraphData(maxX: 0, graphLines: graphLines, lineLabels: lineLabels, maxY: maxY);
}

Widget getXAxisTitleWidgets(double value, TitleMeta meta, TimeUnit timeUnit, DateTime rangeStart, DateTime rangeEnd) {
  final style = AppTypography.chartAxisLabel;
  Widget text;
  int rangeEndIndex = getXCoordinateForDateInRange(date: rangeEnd, timeUnit: timeUnit, rangeStart: rangeStart);
  int midPoint = ((1+rangeEndIndex)/2).floor();
  List<int> indexesToDisplay = [1, ((1+midPoint)/2).floor(), midPoint, ((midPoint+rangeEndIndex)/2).floor(), rangeEndIndex];

  if(indexesToDisplay.contains(value.toInt())){
    text =  Text(
        getDisplayTextForDate(
            getDateTimeFromStartTimeAndIndex(index: value.toInt(),
                rangeStart: rangeStart, timeUnit: timeUnit
            ),
            timeUnit, rangeStart, rangeEnd
        ),
        style: style);
  } else {
    text = const Text('');
  }

  return SideTitleWidget(
    meta: meta,
    space: 8,
    child: text,
  );
}

int getStepSizeInScale(double max, int scalePower){
  if(max/pow(10, scalePower) < 3 && scalePower > 0){
  return 2*pow(10, scalePower-1).toInt();
  } else if(max/pow(10, scalePower) > 5.5){
    return 2*pow(10, scalePower).toInt();
  }
  return pow(10, scalePower).toInt();
}

Widget getYAxisTitleWidgets(double value, TitleMeta meta) {
  final style = AppTypography.chartAxisLabel;

  double max = meta.max;
  int scale = getScaleInPowerOf10(max);
  int yAxisStep = getStepSizeInScale(max, scale);

  String text;
  List<int> displayValues = List<int>.generate(5, (i) => (i+1)*yAxisStep);
  if(displayValues.contains(value.toInt())){
    text = getDisplayTextForAmount(value);
  } else {
    text = '';
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

DateTime getDateTimeFromStartTimeAndIndex({required int index,
required DateTime rangeStart, required TimeUnit timeUnit}){
  if(timeUnit == TimeUnit.day){
    return DateTime(rangeStart.year, rangeStart.month, rangeStart.day).add(Duration(days:index-1));
  }else if(timeUnit == TimeUnit.month){
    return DateTime(rangeStart.year + ((index-1)/12).floor(), rangeStart.month + (index-1)%12).add(Duration());
  }else {
    throw InvalidDataException("");
  }
}

String getLineTouchToolTipHeading(double xCoordinate, DateTime rangeStart, DateTime rangeEnd, TimeUnit timeUnit){
  return getDisplayTextForDate(
      getDateTimeFromStartTimeAndIndex(index: xCoordinate.toInt(),
          rangeStart: rangeStart, timeUnit: timeUnit
      ),
      timeUnit, rangeStart, rangeEnd
  );
}
