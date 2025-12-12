import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/graphs/pie_charts/general_pie_chart.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';

// Top-level function for isolate computation
List<CategoryWithTotal> _computePieSlices(({
List<TransactionWithCategory> transactionsWithCategory,
List<TransactionCategory> categories,
DateTime startDateTime,
DateTime endDateTime,
}) params) {
  Map<TransactionCategory,({int transactionCount, double totalAmount})> pieChartData = {};
  //TODO: figure out how to show subcategories
  for(TransactionWithCategory t in params.transactionsWithCategory){
    final existing = pieChartData[t.category];
    if(existing != null){
      pieChartData[t.category] = (
        transactionCount: existing.transactionCount + 1,
        totalAmount: existing.totalAmount + t.transaction.amount,
      );
    } else {
      pieChartData[t.category] = (
        transactionCount: 1,
        totalAmount: t.transaction.amount,
      );
    }
  }

  List<CategoryWithTotal> pieSlices = [];

  pieChartData.forEach((transactionCategory, data){
    pieSlices.add(CategoryWithTotal(category: transactionCategory, total: data.totalAmount.abs()));
  });

  pieSlices.sort((a,b) => (a.total < b.total)? 1: 0);
  return pieSlices;
}

class TimeRangedSpendingPieChart extends StatefulWidget{
  const TimeRangedSpendingPieChart({
    required this.database,
    required this.startDateTime,
    required this.endDateTime,
    super.key
  });

  final FinanceDatabase database;
  final DateTime startDateTime;
  final DateTime endDateTime;
  @override
  State<TimeRangedSpendingPieChart> createState() => _TimeRangedSpendingPieChartState();
}

class _TimeRangedSpendingPieChartState extends State<TimeRangedSpendingPieChart> {


  late Future<List<CategoryWithTotal>> _pieChartDataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Add this method!
  @override
  void didUpdateWidget(TimeRangedSpendingPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the database instance changed
    if (oldWidget.database != widget.database) {
      // It changed! Reload the data using the NEW database
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _pieChartDataFuture = _fetchDataAndProcessPieChartData();
    });
  }

  Future<List<CategoryWithTotal>> _fetchDataAndProcessPieChartData() async {
    // Fetch data from database
    final results = await Future.wait([
      widget.database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
              (t) => t.dateCreated.isBetweenValues(widget.startDateTime, widget.endDateTime)
      ),
      widget.database.getAllCategories(),
    ]);

    final transactionsWithCategory = results[0] as List<TransactionWithCategory>;
    final categories = results[1] as List<TransactionCategory>;

    return await compute(_computePieSlices, (
    transactionsWithCategory: transactionsWithCategory,
    categories: categories,
    startDateTime: widget.startDateTime,
    endDateTime: widget.endDateTime,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryWithTotal>>(
      future: _pieChartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pieChartData = snapshot.data!;

        return GeneralPieChart(
          totalSpent: 100,
          data: pieChartData,
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

