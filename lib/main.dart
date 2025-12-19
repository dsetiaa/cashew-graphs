import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/graphs/pie_charts/spending_pie_chart.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graphs/line_graphs/spending_line_graph.dart';
import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';
import 'package:cashew_graphs/database_provider.dart';

void main() {
  // await loadCurrencyJSON();
  // runApp(const MyApp());
  runApp(
    const DatabaseProvider(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spending Analytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MyHomePage(title: 'Spending Analytics'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // late FinanceDatabase database;
  // late Future<({List<Transaction> transactions, List<TransactionCategory> categories})> _dataFuture;

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
  }

  void _applyDateFilter(DateTime? start, DateTime? end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      if (isStart) {
        _applyDateFilter(date, _endDate);
      } else {
        _applyDateFilter(_startDate, date);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final database = Provider.of<FinanceDatabase>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTypography.titleMedium,
        ),
        actions: [
          IconButton(
            onPressed: () {
              DatabaseProvider.of(context).importDatabase();
            },
            icon: const Icon(
              Icons.upload_file_outlined,
              color: AppColors.mainTextColor2,
            ),
            tooltip: 'Import Database',
          ),
          const SizedBox(width: AppSpacing.sm,),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Line Chart Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.itemsBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.chartBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: TimeRangedSpendingLineGraph(
                database: database,
                startDateTime: DateTime(2025, 9, 1, 0, 0, 0, 0, 0),
                endDateTime: DateTime(2025, 10 + 1, 1).subtract(const Duration(milliseconds: 1)),
                timeUnit: TimeUnit.day,
                graphType: LineGraphType.perTimeUnit,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            // Pie Chart Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.itemsBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.chartBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: TimeRangedSpendingPieChart(
                database: database,
                startDateTime: DateTime(2025, 9, 1, 0, 0, 0, 0, 0),
                endDateTime: DateTime(2025, 10 + 1, 1).subtract(const Duration(milliseconds: 1)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
