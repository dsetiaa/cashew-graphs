import 'package:cashew_graphs/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cashew_graphs/graphs/line_graphs/general_line_graph.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';

import 'package:cashew_graphs/logic/helpers.dart';

class MonthlyPerDaySpending extends StatefulWidget{
  const MonthlyPerDaySpending({
    required this.database,
    super.key
  });

  final FinanceDatabase database;
  @override
  State<MonthlyPerDaySpending> createState() => _MonthlyPerDaySpendingState();
}

class _MonthlyPerDaySpendingState extends State<MonthlyPerDaySpending> {


  late Future<({List<TransactionWithCategory> transactionsWithCategory,
                List<TransactionCategory> categories})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }


  Future<({List<TransactionWithCategory> transactionsWithCategory, List<TransactionCategory> categories})> _fetchData() async {
    final monthRange = getCurrentMonthRange();
    final results = await Future.wait([
      widget.database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
            // (t) => t.dateCreated.isBetweenValues(monthRange.start, monthRange.end)
            (t) => t.dateCreated.isBetweenValues(DateTime(2025, 9, 1, 0, 0, 0, 0, 0), DateTime(2025, 10 + 1, 1).subtract(const Duration(milliseconds: 1)))
      ),
      widget.database.getAllCategories(),
    ]);

    return (
    transactionsWithCategory: results[0] as List<TransactionWithCategory>,
    categories: results[1] as List<TransactionCategory>,
    );
  }

  List<LineChartBarData> getGraphLinesFromTransactions(List<TransactionWithCategory> txns, List<TransactionCategory> categories){
    List<LineChartBarData> graphLines = [];
    Map<String,Map<int,int>> graphLinesDict = {};
    for(TransactionWithCategory txn in txns){

    }

    LineChartBarData lineChartBarData2_1 = LineChartBarData(
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

    LineChartBarData lineChartBarData2_2 = LineChartBarData(
      isCurved: true,
      curveSmoothness: 0,
      color: AppColors.contentColorPink.withValues(alpha: 0.5),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      spots: const [
        FlSpot(1, 2),
        FlSpot(3, 3.8),
        FlSpot(7, 2.2),
        FlSpot(10, 4.8),
        FlSpot(12, 3.6),
        FlSpot(13, 4.9),
      ],
    );

    LineChartBarData lineChartBarData2_3 = LineChartBarData(
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

    LineChartBarData lineChartBarData2_4 = LineChartBarData(
      isCurved: true,
      curveSmoothness: 0,
      color: AppColors.contentColorOrange.withValues(alpha: 0.5),
      barWidth: 3,
      isStrokeCapRound: false,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      spots: const [
        FlSpot(2, 3.8),
        // FlSpot(4, 5.8),
      ],
    );

    return [
      lineChartBarData2_1,
      lineChartBarData2_2,
      lineChartBarData2_3,
      lineChartBarData2_4
    ];

  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // final transactions = snapshot.data ?? [];
        final data = snapshot.data!;
        final transactionsWithCategory = data.transactionsWithCategory;
        final categories = data.categories;

        print("printing transactions");
        for(TransactionWithCategory twc in transactionsWithCategory) {
          print("Transaction: AMT: ${twc.transaction.amount}, DATE: ${twc.transaction.dateCreated}, SUBCATEGORY: ${twc.subCategory?.name}, CATEGORY : ${twc.category.name}");
        }
        print("fin");

        return GeneralLineChart(graphTitle: "Monthly Per Day", graphLines: getGraphLinesFromTransactions(transactionsWithCategory, categories));
      },
    );
  }
}

