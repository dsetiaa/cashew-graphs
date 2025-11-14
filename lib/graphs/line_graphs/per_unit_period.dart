import 'package:cashew_graphs/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cashew_graphs/graphs/line_graphs/general_line_graph.dart';
import 'package:cashew_graphs/logic/helpers.dart';

class StartToEndPerUnitSpending extends StatefulWidget{
  const StartToEndPerUnitSpending({
    required this.database,
    required this.startDateTime,
    required this.endDateTime,
    required this.timeUnit,
    super.key
  });

  final FinanceDatabase database;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final TimeUnit timeUnit;
  @override
  State<StartToEndPerUnitSpending> createState() => _StartToEndPerUnitSpendingState();
}

class _StartToEndPerUnitSpendingState extends State<StartToEndPerUnitSpending> {


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
    final results = await Future.wait([
      widget.database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
        (t) => t.dateCreated.isBetweenValues(widget.startDateTime, widget.endDateTime)
      ),
      widget.database.getAllCategories(),
    ]);

    return (
    transactionsWithCategory: results[0] as List<TransactionWithCategory>,
    categories: results[1] as List<TransactionCategory>,
    );
  }

  List<LineChartBarData> getGraphLinesFromTransactions(List<TransactionWithCategory> transactionsWithCategory, List<TransactionCategory> categories){
    Map<String,List<({DateTime date, double amount})>> graphLinesDict =
    getGraphLinesDict(transactionsWithCategory: transactionsWithCategory,
        timeUnit: widget.timeUnit);
    List<LineChartBarData> graphLines = getGraphLines(
        graphLinesDict: graphLinesDict, categories: categories, timeUnit: widget.timeUnit,
        startDateTime: widget.startDateTime, endDateTime: widget.endDateTime );
    return graphLines;
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

        return GeneralLineChart(graphTitle: "Monthly Per Day",
            graphLines: getGraphLinesFromTransactions(transactionsWithCategory, categories));
      },
    );
  }
}

