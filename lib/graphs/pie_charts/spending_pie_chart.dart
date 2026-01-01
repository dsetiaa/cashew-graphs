import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/graphs/pie_charts/general_pie_chart.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';

// Top-level function for isolate computation - returns hierarchical data for sunburst chart
List<CategoryWithTotalAndSubs> _computePieSlices(({
  List<TransactionWithCategory> transactionsWithCategory,
  List<TransactionCategory> categories,
  DateTime startDateTime,
  DateTime endDateTime,
  Set<String>? selectedCategoriesPks,
}) params) {
  // Build hierarchical data: main category -> subcategories
  // Key: main category PK, Value: category data with subcategory breakdown
  Map<String, ({
    TransactionCategory category,
    int transactionCount,
    double totalAmount,
    Map<String, ({TransactionCategory? subCategory, int count, double amount})> subcategories,
  })> hierarchicalData = {};

  for (TransactionWithCategory t in params.transactionsWithCategory) {
    final mainCategoryPk = t.category.categoryPk;
    final subCategoryPk = t.subCategory?.categoryPk ?? 'uncategorized';

    if (!hierarchicalData.containsKey(mainCategoryPk)) {
      hierarchicalData[mainCategoryPk] = (
        category: t.category,
        transactionCount: 0,
        totalAmount: 0.0,
        subcategories: {},
      );
    }

    final existing = hierarchicalData[mainCategoryPk]!;
    final existingSub = existing.subcategories[subCategoryPk];

    // Update subcategory data
    final updatedSubs = Map<String, ({TransactionCategory? subCategory, int count, double amount})>.from(existing.subcategories);
    if (existingSub != null) {
      updatedSubs[subCategoryPk] = (
        subCategory: t.subCategory,
        count: existingSub.count + 1,
        amount: existingSub.amount + t.transaction.amount,
      );
    } else {
      updatedSubs[subCategoryPk] = (
        subCategory: t.subCategory,
        count: 1,
        amount: t.transaction.amount,
      );
    }

    // Update main category totals
    hierarchicalData[mainCategoryPk] = (
      category: t.category,
      transactionCount: existing.transactionCount + 1,
      totalAmount: existing.totalAmount + t.transaction.amount,
      subcategories: updatedSubs,
    );
  }

  // Convert to List<CategoryWithTotalAndSubs>
  List<CategoryWithTotalAndSubs> pieSlices = [];

  hierarchicalData.forEach((categoryPk, data) {
    if (showCategory(
      category: data.category,
      selectedCategoriesPks: params.selectedCategoriesPks,
      showSubcategories: false,
    )) {
      // Build subcategory list
      List<CategoryWithTotal> subcategoryList = [];

      data.subcategories.forEach((subPk, subData) {
        if (subPk == 'uncategorized') {
          // For uncategorized, use the main category but mark as uncategorized
          subcategoryList.add(CategoryWithTotal(
            category: data.category,
            total: subData.amount.abs(),
            transactionCount: subData.count,
            isUncategorized: true,
          ));
        } else {
          subcategoryList.add(CategoryWithTotal(
            category: subData.subCategory!,
            total: subData.amount.abs(),
            transactionCount: subData.count,
          ));
        }
      });

      // Sort subcategories by total (descending)
      subcategoryList.sort((a, b) => b.total.compareTo(a.total));

      pieSlices.add(CategoryWithTotalAndSubs(
        category: data.category,
        total: data.totalAmount.abs(),
        transactionCount: data.transactionCount,
        subcategories: subcategoryList,
      ));
    }
  });

  // Sort main categories by total (descending)
  pieSlices.sort((a, b) => b.total.compareTo(a.total));
  return pieSlices;
}

class TimeRangedSpendingPieChart extends StatefulWidget{
  const TimeRangedSpendingPieChart({
    required this.database,
    required this.startDateTime,
    required this.endDateTime,
    required this.transactionNameFilter,
    this.selectedCategoriesPks,
    this.showSubcategories = true,
    super.key
  });

  final FinanceDatabase database;
  final DateTime startDateTime;
  final DateTime endDateTime;
  /// null = all categories, empty = none, non-empty = specific categories
  final Set<String>? selectedCategoriesPks;
  final String transactionNameFilter;
  final bool showSubcategories;
  @override
  State<TimeRangedSpendingPieChart> createState() => _TimeRangedSpendingPieChartState();
}

class _TimeRangedSpendingPieChartState extends State<TimeRangedSpendingPieChart> {


  late Future<List<CategoryWithTotalAndSubs>> _pieChartDataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(TimeRangedSpendingPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if any parameters changed that require reloading data
    if (oldWidget.database != widget.database ||
        oldWidget.startDateTime != widget.startDateTime ||
        oldWidget.endDateTime != widget.endDateTime ||
        oldWidget.selectedCategoriesPks != widget.selectedCategoriesPks ||
        oldWidget.transactionNameFilter != widget.transactionNameFilter) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _pieChartDataFuture = _fetchDataAndProcessPieChartData();
    });
  }

  Future<List<CategoryWithTotalAndSubs>> _fetchDataAndProcessPieChartData() async {
    // Fetch data from database
    final nameFilter = widget.transactionNameFilter;
    final results = await Future.wait([
      widget.database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
              (t) {
                var filter = t.dateCreated.isBetweenValues(widget.startDateTime, widget.endDateTime);
                if (nameFilter.isNotEmpty) {
                  filter = filter & t.name.lower().like('%${nameFilter.toLowerCase()}%');
                }
                return filter;
              }
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
    selectedCategoriesPks: widget.selectedCategoriesPks,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryWithTotalAndSubs>>(
      future: _pieChartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading chart...',
                    style: AppTypography.labelMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 320,
            child: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.contentColorRed,
                ),
              ),
            ),
          );
        }

        final pieChartData = snapshot.data!;
        final totalSpent = pieChartData.fold<double>(0, (sum, item) => sum + item.total);

        return GeneralPieChart(
          totalSpent: totalSpent,
          data: pieChartData,
          showSubcategories: widget.showSubcategories,
        );
      },
    );
  }
}

