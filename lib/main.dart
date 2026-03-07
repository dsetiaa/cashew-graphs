import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/graphs/pie_charts/spending_pie_chart.dart';
import 'package:cashew_graphs/logic/category_color_manager.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';
import 'package:cashew_graphs/presentation/pages/category_color_settings_page.dart' show SettingsPage;
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:cashew_graphs/presentation/widgets/filter_dialog.dart';
import 'package:cashew_graphs/presentation/widgets/month_selector.dart';
import 'package:cashew_graphs/presentation/widgets/spend_summary.dart';
import 'package:cashew_graphs/presentation/widgets/transaction_list.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graphs/line_graphs/spending_line_graph.dart';
import 'package:cashew_graphs/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CategoryColorManager.initialize();
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
      title: 'CashFlew',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MyHomePage(title: 'CashFlew💸'),
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
  ({
    double totalSpend,
    int transactionCount,
    List<TransactionWithCategory> filteredTransactions,
    List<TransactionWithCategory> allTransactions,
    List<TransactionCategory> categories,
  })? _data;
  late DateTime _selectedMonth;
  final _monthSelectorKey = GlobalKey<MonthSelectorState>();

  FinanceDatabase? _database;
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    final defaultDateRange = getDefaultDateRange();
    _filterSettings = FilterSettings(
      startDate: defaultDateRange.start,
      endDate: defaultDateRange.end,
      showTotal: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final database = Provider.of<FinanceDatabase>(context);
    if (_database != database) {
      _database = database;
      _refreshData();
    }
  }

  void _selectMonth(DateTime month) {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    _selectedMonth = month;
    _filterSettings = _filterSettings.copyWith(
      startDate: DateTime(month.year, month.month, 1),
      endDate: isCurrentMonth
          ? getDefaultEndDate()
          : DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1)),
    );
    _refreshData();
    _monthSelectorKey.currentState?.scrollToMonth(_selectedMonth);
  }

  Future<void> _fetchData(int generation) async {
    final database = _database!;
    final nameFilter = _filterSettings.transactionNameFilter.trim();
    final results = await Future.wait([
      database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
        (t) {
          var filter = t.dateCreated.isBetweenValues(_filterSettings.startDate, _filterSettings.endDate);
          if (nameFilter.isNotEmpty) {
            filter = filter & t.name.lower().like('%${nameFilter.toLowerCase()}%');
          }
          return filter;
        },
      ),
      database.getAllCategories(),
    ]);

    if (!mounted || generation != _fetchGeneration) return;

    final allTransactions = results[0] as List<TransactionWithCategory>;
    final categories = results[1] as List<TransactionCategory>;
    _categories = categories;

    double totalSpend = 0;
    final filtered = <TransactionWithCategory>[];
    for (final twc in allTransactions) {
      if (showCategory(
        category: twc.category,
        selectedCategoriesPks: _filterSettings.selectedCategoryPks,
        showSubcategories: false,
      )) {
        totalSpend += twc.transaction.amount.abs();
        filtered.add(twc);
      }
    }

    filtered.sort((a, b) => b.transaction.dateCreated.compareTo(a.transaction.dateCreated));

    setState(() {
      _data = (
        totalSpend: totalSpend,
        transactionCount: filtered.length,
        filteredTransactions: filtered,
        allTransactions: allTransactions,
        categories: categories,
      );
    });
  }

  Future<void> _showFilterDialog() async {
    if (_categories.isEmpty && _database != null) {
      _categories = await _database!.getAllCategories();
    }

    if (!mounted) return;

    final result = await FilterDialog.show(
      context: context,
      initialSettings: _filterSettings,
      categories: _categories,
    );

    if (result != null) {
      _filterSettings = result;
      _selectedMonth = DateTime(result.startDate.year, result.startDate.month);
      _refreshData();
      _monthSelectorKey.currentState?.scrollToMonth(_selectedMonth);
    }
  }



  void _refreshData() {
    if (_database == null) return;
    final generation = ++_fetchGeneration;
    _fetchData(generation).catchError((e) {
      debugPrint('Failed to fetch data: $e');
    });
  }

  Widget _buildChartCard({required Widget child}) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.itemsBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.chartBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: child,
      ),
    );
  }

  Widget _buildLoadingPlaceholder({double height = 300}) {
    return SizedBox(
      height: height,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.itemsBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('CashFlew💸', style: AppTypography.titleMedium),
              ),
              const Divider(color: AppColors.chartBorder, height: 1),
              ListTile(
                leading: const Icon(Icons.home, color: AppColors.mainTextColor2),
                title: Text('Home', style: AppTypography.bodyLarge),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: AppColors.mainTextColor2),
                title: Text('Settings', style: AppTypography.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ).then((_) => setState(() {}));
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTypography.titleMedium,
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
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
                    _data = null;
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
            MonthSelector(
              key: _monthSelectorKey,
              selectedMonth: _selectedMonth,
              onMonthSelected: _selectMonth,
            ),
            const SizedBox(height: AppSpacing.md),
            SpendSummary(data: _data),
            const SizedBox(height: AppSpacing.sectionGap),
            _buildChartCard(
              child: (_isLoadingDatabase || _data == null)
                  ? _buildLoadingPlaceholder()
                  : TimeRangedSpendingLineGraph(
                      transactions: _data!.allTransactions,
                      categories: _data!.categories,
                      startDateTime: _filterSettings.startDate,
                      endDateTime: _filterSettings.endDate,
                      timeUnit: _filterSettings.timeUnit,
                      graphType: _filterSettings.lineGraphType,
                      showTotal: _filterSettings.showTotal,
                      selectedCategoriesPks: _filterSettings.selectedCategoryPks,
                      showSubcategories: _filterSettings.showSubcategories,
                    ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _buildChartCard(
              child: (_isLoadingDatabase || _data == null)
                  ? _buildLoadingPlaceholder()
                  : TimeRangedSpendingPieChart(
                      transactions: _data!.allTransactions,
                      categories: _data!.categories,
                      startDateTime: _filterSettings.startDate,
                      endDateTime: _filterSettings.endDate,
                      selectedCategoriesPks: _filterSettings.selectedCategoryPks,
                      showSubcategories: _filterSettings.showSubcategories,
                    ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _buildChartCard(
              child: (_isLoadingDatabase || _data == null)
                  ? _buildLoadingPlaceholder()
                  : TimeRangedSpendingLineGraph(
                      transactions: _data!.allTransactions,
                      categories: _data!.categories,
                      startDateTime: _filterSettings.startDate,
                      endDateTime: _filterSettings.endDate,
                      timeUnit: _filterSettings.timeUnit,
                      graphType: _filterSettings.lineGraphType,
                      showTotal: _filterSettings.showTotal,
                      selectedCategoriesPks: _filterSettings.selectedCategoryPks,
                      showSubcategories: _filterSettings.showSubcategories,
                      showTransactionCount: true,
                    ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            TransactionList(data: _data),
          ],
        ),
        ),
      ),
    );
  }
}
