import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/graphs/pie_charts/general_pie_chart.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cashew_graphs/graphs/line_graphs/general_line_graph.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';

// Top-level function for isolate computation
LineGraphData _computeGraphLines(({
List<TransactionWithCategory> transactionsWithCategory,
List<TransactionCategory> categories,
TimeUnit timeUnit,
DateTime startDateTime,
DateTime endDateTime,
LineGraphType graphType
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
  LineGraphData incompleteLineGraphDataGraphLinesAndMaxY = getGraphLinesLineLabelsAndMaxY(
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
      graphLines: incompleteLineGraphDataGraphLinesAndMaxY.graphLines,
      lineLabels: incompleteLineGraphDataGraphLinesAndMaxY.lineLabels);
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
  final LineGraphType graphType;
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

        return GeneralPieChart(
          totalSpent: 100,
          data: [
            CategoryWithTotal(category: TransactionCategory(categoryPk: "1", name: "1", dateCreated: DateTime(2025), order: 1, income: false), total: 10),
            CategoryWithTotal(category: TransactionCategory(categoryPk: "2", name: "2", dateCreated: DateTime(2025), order: 1, income: false), total: 20),
            CategoryWithTotal(category: TransactionCategory(categoryPk: "3", name: "3", dateCreated: DateTime(2025), order: 1, income: false), total: 30),
            CategoryWithTotal(category: TransactionCategory(categoryPk: "4", name: "4", dateCreated: DateTime(2025), order: 1, income: false), total: 40),
          ],
        );
        //   (
        //   graphTitle: "Monthly Per Day",
        //   graphLines: lineGraphData.graphLines,
        //   lineLabels: lineGraphData.lineLabels,
        //   maxX: lineGraphData.maxX,
        //   maxY: lineGraphData.maxY,
        //   leftTitleWidgets: getYAxisTitleWidgets,
        //   bottomTitleWidgets: (value, meta) => getXAxisTitleWidgets(value, meta, widget.timeUnit, widget.startDateTime, widget.endDateTime),
        //   getLineTouchToolTipHeadingFunction: (x) => getLineTouchToolTipHeading(x, widget.startDateTime, widget.endDateTime, widget.timeUnit),
        // );
      },
    );
  }
}

