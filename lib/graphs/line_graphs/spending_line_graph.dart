import 'package:cashew_graphs/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cashew_graphs/graphs/line_graphs/general_line_graph.dart';
import 'package:cashew_graphs/logic/helpers.dart';

// Top-level function for isolate computation
LineGraphData _computeGraphLines(({
  List<TransactionWithCategory> transactionsWithCategory,
  List<TransactionCategory> categories,
  TimeUnit timeUnit,
  DateTime startDateTime,
  DateTime endDateTime,
  GraphType graphType
}) params) {
  Map<String,List<({DateTime date, double amount})>> graphLinesDict =
      getGraphLinesDict(
        transactionsWithCategory: params.transactionsWithCategory,
        timeUnit: params.timeUnit,
        rangeStart: params.startDateTime,
        rangeEnd: params.endDateTime
      );

  // List<LineChartBarData> graphLines;
  // double maxY;
  LineGraphData incompleteLineGraphDataGraphLinesAndMaxY = getGraphLinesAndMaxY(
    graphLinesDict: graphLinesDict,
    categories: params.categories,
    timeUnit: params.timeUnit,
    startDateTime: params.startDateTime,
    endDateTime: params.endDateTime,
    graphType: params.graphType
  );

  double maxX = getMaxX(startDateTime: params.startDateTime,
      endDateTime: params.endDateTime, timeUnit: params.timeUnit);

  LineGraphData finalLineGraphData = LineGraphData(maxX: maxX,
      maxY: incompleteLineGraphDataGraphLinesAndMaxY.maxY,
      graphLines: incompleteLineGraphDataGraphLinesAndMaxY.graphLines);
  return finalLineGraphData;
}

class TimeRangedSpendingLineGraph extends StatefulWidget{
  const TimeRangedSpendingLineGraph({
    required this.database,
    required this.startDateTime,
    required this.endDateTime,
    required this.timeUnit,
    required this.graphType,
    super.key
  });

  final FinanceDatabase database;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final TimeUnit timeUnit;
  final GraphType graphType;
  @override
  State<TimeRangedSpendingLineGraph> createState() => _TimeRangedSpendingLineGraphState();
}

class _TimeRangedSpendingLineGraphState extends State<TimeRangedSpendingLineGraph> {


  late Future<LineGraphData> _lineGraphDataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _lineGraphDataFuture = _fetchDataAndProcessLineGraphData();
    });
  }

  Future<LineGraphData> _fetchDataAndProcessLineGraphData() async {
    // Fetch data from database
    final results = await Future.wait([
      widget.database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
        (t) => t.dateCreated.isBetweenValues(widget.startDateTime, widget.endDateTime)
      ),
      widget.database.getAllCategories(),
    ]);

    final transactionsWithCategory = results[0] as List<TransactionWithCategory>;
    final categories = results[1] as List<TransactionCategory>;

    // Process graph lines in a separate isolate using compute
    return await compute(_computeGraphLines, (
      transactionsWithCategory: transactionsWithCategory,
      categories: categories,
      timeUnit: widget.timeUnit,
      startDateTime: widget.startDateTime,
      endDateTime: widget.endDateTime,
      graphType: widget.graphType
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LineGraphData>(
      future: _lineGraphDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final lineGraphData = snapshot.data!;

        return GeneralLineChart(
          graphTitle: "Monthly Per Day",
          graphLines: lineGraphData.graphLines,
          maxX: lineGraphData.maxX,
          maxY: lineGraphData.maxY
        );
      },
    );
  }
}

