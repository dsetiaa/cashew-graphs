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