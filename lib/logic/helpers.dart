import 'dart:math';

import 'package:cashew_graphs/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cashew_graphs/logic/constants.dart' as Constants;
import 'package:flutter/material.dart';

enum TimeUnit {
  day,
  month
}

enum GraphType {
  perTimeUnit,
  aggregate
}

class LineGraphData{
  final double maxX;
  final double maxY;
  final List<LineChartBarData> graphLines;

  LineGraphData({
    required this.maxX,
    required this.maxY,
    required this.graphLines
  });
}


DateTime getStartOfCurrentMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1, 0, 0, 0, 0, 0);
}

/// Get the end date of the current month (last day at 23:59:59.999)
DateTime getEndOfCurrentMonth() {
  final now = DateTime.now();
  // Get the first day of next month, then subtract 1 millisecond
  final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
  return firstDayNextMonth.subtract(const Duration(milliseconds: 1));
}

/// Get both start and end dates as a record (Dart 3.0+)
({DateTime start, DateTime end}) getCurrentMonthRange() {
  return (
  start: getStartOfCurrentMonth(),
  end: getEndOfCurrentMonth(),
  );
}
/// Get both start and end dates as a record (Dart 3.0+)
({DateTime start, DateTime end}) getCustomMonthRange() {
  return (
  start: getStartOfCurrentMonth(),
  end: getEndOfCurrentMonth(),
  );
}


bool isPartOfSameTimePeriod({required DateTime a, required DateTime b, required TimeUnit timeUnit}){
  if(timeUnit == TimeUnit.day){
    return (a.day == b.day) && (a.month == b.month) && (a.year == b.year);
  }
  else if(timeUnit == TimeUnit.month){
    return (a.month == b.month) && (a.year == b.year);
  }
  else{
    throw InvalidDataException("Invalid Time Unit");
  }
}

DateTime createNextSeriesDateTime({required DateTime previousDate, required TimeUnit timeUnit}) {
  if(timeUnit == TimeUnit.day){
    return DateTime(previousDate.year, previousDate.month, previousDate.day+1);
  } else if(timeUnit == TimeUnit.month) {
    return DateTime(previousDate.year, previousDate.month+1, previousDate.day);
  }else {
    throw InvalidDataException("Invalid Time Unit");
  }
}

Map<String,List<({DateTime date, double amount})>> getGraphLinesDict({
  required List<TransactionWithCategory> transactionsWithCategory,
  required TimeUnit timeUnit, required DateTime rangeStart, required DateTime rangeEnd})
{
  Map<String,List<({DateTime date, double amount})>> graphLinesDict = {};
  for(TransactionWithCategory twc in transactionsWithCategory) {
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
          graphLinesDict[categoryPk] = [(
              date: rangeStart,
              amount: 0
          )];
        }
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

        // Add transaction data
        graphLinesDict[categoryPk]!.add((date: twc.transaction.dateCreated, amount: twc.transaction.amount));
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

LineGraphData getGraphLinesAndMaxY({
  required Map<String,List<({DateTime date, double amount})>> graphLinesDict,
  required List<TransactionCategory> categories, required DateTime startDateTime,
  required DateTime endDateTime, required TimeUnit timeUnit,
  required GraphType graphType})
{
  List<LineChartBarData> graphLines = [];
  double maxY = 0;

  graphLinesDict.forEach((categoryPk, perTimeUnitDataList){
    Color lineColor;
    if(categoryPk != Constants.SUM_OF_ALL_CATEGORIES_DUMMY_PK) {
      TransactionCategory matchedCategory = categories.firstWhere((tk) =>
      tk.categoryPk == categoryPk);
      lineColor = (matchedCategory.colour != null)? Color(int.parse(matchedCategory.colour!.substring(4), radix: 16) + 0xFF000000) : Colors.white38;
    } else {
      lineColor = Colors.black;
    }

    List<FlSpot> spots = [];
    perTimeUnitDataList.asMap().forEach((i, dataPoint){
      double yCoordinate = dataPoint.amount.abs();
      if(graphType == GraphType.aggregate){
        if(i > 0){
          yCoordinate += spots.last.y;
        }
      }
      maxY = max(yCoordinate, maxY);
      spots.add(FlSpot(
          getXCoordinateForDateInRange(date: dataPoint.date,
              timeUnit: timeUnit, rangeStart: startDateTime).toDouble(),
          yCoordinate
      ));
    });

    graphLines.add(
        LineChartBarData(
          isCurved: true,
          curveSmoothness: 0,
          color: lineColor.withValues(alpha: 0.5),
          barWidth: 3,
          isStrokeCapRound: false,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          spots:spots
        )
    );
  });

  maxY = (maxY*1.02).ceilToDouble();
  return LineGraphData(maxX: 0, graphLines: graphLines, maxY: maxY);
}
