import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/graphs/pie_charts/spending_pie_chart.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:cashew_graphs/presentation/widgets/filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graphs/line_graphs/spending_line_graph.dart';
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
  late FilterSettings _filterSettings;
  List<TransactionCategory> _categories = [];
  bool _isLoadingDatabase = false;

  @override
  void initState() {
    super.initState();
    final defaultDateRange = getDefaultDateRange();
    _filterSettings = FilterSettings(
      startDate: defaultDateRange.start,
      endDate: defaultDateRange.end,
      showTotal: true,
    );
  }

  Future<void> _loadCategories(FinanceDatabase database) async {
    if (_categories.isEmpty) {
      _categories = await database.getAllCategories();
    }
  }

  Future<void> _showFilterDialog(FinanceDatabase database) async {
    await _loadCategories(database);

    if (!mounted) return;

    final result = await FilterDialog.show(
      context: context,
      initialSettings: _filterSettings,
      categories: _categories,
    );

    if (result != null) {
      setState(() {
        _filterSettings = result;
      });
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
            onPressed: () => _showFilterDialog(database),
            icon: const Icon(
              Icons.filter_alt_rounded,
              color: AppColors.mainTextColor2,
            ),
            tooltip: 'Filter',
          ),
          const SizedBox(width: AppSpacing.sm,),
          IconButton(
            onPressed: () {
              DatabaseProvider.of(context).importDatabase(
                onLoadingStart: () {
                  setState(() {
                    _isLoadingDatabase = true;
                  });
                },
                onLoadingEnd: () {
                  setState(() {
                    _isLoadingDatabase = false;
                  });
                },
              );
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
                  color: AppColors.chartBorder.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: _isLoadingDatabase
                  ? SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading database...', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    )
                  : TimeRangedSpendingLineGraph(
                      database: database,
                      startDateTime: _filterSettings.startDate,
                      endDateTime: _filterSettings.endDate,
                      timeUnit: _filterSettings.timeUnit,
                      graphType: _filterSettings.lineGraphType,
                      showTotal: _filterSettings.showTotal,
                      selectedCategoriesPks: _filterSettings.selectedCategoryPks,
                      transactionNameFilter: _filterSettings.transactionNameFilter.trim(),
                      showSubcategories: _filterSettings.showSubcategories,
                    ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            // Pie Chart Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.itemsBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.chartBorder.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: _isLoadingDatabase
                  ? SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading database...', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    )
                  : TimeRangedSpendingPieChart(
                      database: database,
                      startDateTime: _filterSettings.startDate,
                      endDateTime: _filterSettings.endDate,
                      selectedCategoriesPks: _filterSettings.selectedCategoryPks,
                      transactionNameFilter: _filterSettings.transactionNameFilter.trim(),
                      showSubcategories: _filterSettings.showSubcategories,
                    ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
