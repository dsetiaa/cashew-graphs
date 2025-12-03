import 'dart:math';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';


enum TimeUnit {
  day,
  month
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

int getScaleInPowerOf10(double ip){
  int scale = 0;
  while(ip/pow(10, scale) >= 10) {
    scale += 1;
  }
  return scale;
}

String getDisplayTextForAmount(double value){
  int scale = getScaleInPowerOf10(value);

  if(scale < 3){
    return value.toStringAsFixed(0);
  } else if(scale < 5) {
    value = value/1000;
    return "${value.toStringAsFixed(0)}K";
  } else if(scale < 7) {
    value = value/100000;
    return "${value.toStringAsFixed(0)}L";
  } else {
    value = value/10000000;
    return "${value.toStringAsFixed(0)}Cr";
  }
}

String getDisplayTextForDate(DateTime date, TimeUnit timeUnit, DateTime rangeStart, DateTime rangeEnd){
  if(timeUnit == TimeUnit.day){
    if(rangeStart.year == rangeEnd.year){
      String abvMonthName = DateFormat("MMM").format(date);
      return "${date.day} $abvMonthName";
    }else {
      return "${date.day}/${date.month}/${date.year.toString().substring(2)}";
    }
  } else if(timeUnit == TimeUnit.month){
    String abvMonthName = DateFormat("MMM").format(date);
    if(rangeStart.year == rangeEnd.year){
      return abvMonthName;
    }else {
      return "$abvMonthName'${date.year.toString().substring(2)}";
    }
  } else {
    throw InvalidDataException("Time Unit not supported");
  }
}

T? nullIfIndexOutOfRange<T>(List<T> list, int index) {
  if (index < 0 || index >= list.length) {
    return null;
  } else {
    return list[index];
  }
}
