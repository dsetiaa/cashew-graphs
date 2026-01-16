import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:drift/drift.dart' hide Column;
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
  LineGraphType graphType,
  bool showTotal,
  Set<String>? selectedCategoriesPks,
  bool showSubcategories,
  bool showTransactionCount
}) params) {
  Map<String,List<({DateTime date, double amount})>> graphLinesDict =
      getGraphLinesDict(
        transactionsWithCategory: params.transactionsWithCategory,
        timeUnit: params.timeUnit,
        rangeStart: params.startDateTime,
        rangeEnd: params.endDateTime,
        showTotal: params.showTotal,
        selectedCategoriesPks: params.selectedCategoriesPks,
        showSubcategories: params.showSubcategories,
        showTransactionCount: params.showTransactionCount,
      );

  // List<LineChartBarData> graphLines;
  // double maxY;
  LineGraphData incompleteLineGraphDataGraphLinesAndMaxY = getGraphLinesLineLabelsAndMaxY(
    graphLinesDict: graphLinesDict,
    categories: params.categories,
    timeUnit: params.timeUnit,
    startDateTime: params.startDateTime,
    endDateTime: params.endDateTime,
    graphType: params.graphType,
    showTotal: params.showTotal,
    selectedCategories: params.selectedCategoriesPks,
    showSubcategories: params.showSubcategories
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
    required this.showTotal,
    required this.transactionNameFilter,
    required this.showSubcategories,
    this.selectedCategoriesPks,
    this.showTransactionCount = false,
    super.key
  });

  final FinanceDatabase database;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final TimeUnit timeUnit;
  final LineGraphType graphType;
  final bool showTotal;
  /// null = all categories, empty = none, non-empty = specific categories
  final Set<String>? selectedCategoriesPks;
  final String transactionNameFilter;
  final bool showSubcategories;
  final bool showTransactionCount;
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

  @override
  void didUpdateWidget(TimeRangedSpendingLineGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if any parameters changed that require reloading data
    if (oldWidget.database != widget.database ||
        oldWidget.startDateTime != widget.startDateTime ||
        oldWidget.endDateTime != widget.endDateTime ||
        oldWidget.timeUnit != widget.timeUnit ||
        oldWidget.graphType != widget.graphType ||
        oldWidget.showTotal != widget.showTotal ||
        oldWidget.selectedCategoriesPks != widget.selectedCategoriesPks ||
        oldWidget.transactionNameFilter != widget.transactionNameFilter ||
        oldWidget.showSubcategories != widget.showSubcategories
    ) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _lineGraphDataFuture = _fetchDataAndProcessLineGraphData();
    });
  }

  Future<LineGraphData> _fetchDataAndProcessLineGraphData() async {
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

    // Process graph lines in a separate isolate using compute
    return await compute(_computeGraphLines, (
      transactionsWithCategory: transactionsWithCategory,
      categories: categories,
      timeUnit: widget.timeUnit,
      startDateTime: widget.startDateTime,
      endDateTime: widget.endDateTime,
      graphType: widget.graphType,
      showTotal: widget.showTotal,
      selectedCategoriesPks: widget.selectedCategoriesPks,
      showSubcategories: widget.showSubcategories,
    showTransactionCount: widget.showTransactionCount
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LineGraphData>(
      future: _lineGraphDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 280,
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
            height: 280,
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

        final lineGraphData = snapshot.data!;

        return GeneralLineChart(
          graphTitle: "Monthly Per Day",
          graphLines: lineGraphData.graphLines,
          lineLabels: lineGraphData.lineLabels,
          maxX: lineGraphData.maxX,
          maxY: lineGraphData.maxY,
          leftTitleWidgets: getYAxisTitleWidgets,
          bottomTitleWidgets: (value, meta) => getXAxisTitleWidgets(value, meta, widget.timeUnit, widget.startDateTime, widget.endDateTime),
          getLineTouchToolTipHeadingFunction: (x) => getLineTouchToolTipHeading(x, widget.startDateTime, widget.endDateTime, widget.timeUnit),
          showTransactionCount: widget.showTransactionCount,
        );
      },
    );
  }
}

