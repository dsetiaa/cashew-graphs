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
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Future<({double totalSpend, int transactionCount, List<TransactionWithCategory> transactions})>? _summaryFuture;

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

  Future<({double totalSpend, int transactionCount, List<TransactionWithCategory> transactions})> _fetchSummary(FinanceDatabase database) async {
    final nameFilter = _filterSettings.transactionNameFilter.trim();
    final allTransactions = await database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
      (t) {
        var filter = t.dateCreated.isBetweenValues(_filterSettings.startDate, _filterSettings.endDate);
        if (nameFilter.isNotEmpty) {
          filter = filter & t.name.lower().like('%${nameFilter.toLowerCase()}%');
        }
        return filter;
      },
    );

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

    // Sort by date descending (newest first)
    filtered.sort((a, b) => b.transaction.dateCreated.compareTo(a.transaction.dateCreated));

    return (totalSpend: totalSpend, transactionCount: filtered.length, transactions: filtered);
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



  void _refreshSummary(FinanceDatabase database) {
    _summaryFuture = _fetchSummary(database);
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<FinanceDatabase>(context);
    _refreshSummary(database);
    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.itemsBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Spending Analytics', style: AppTypography.titleMedium),
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
            // Summary Box
            FutureBuilder<({double totalSpend, int transactionCount, List<TransactionWithCategory> transactions})>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                final totalSpend = snapshot.data?.totalSpend;
                final transactionCount = snapshot.data?.transactionCount;
                final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.itemsBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.chartBorder.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.cardPadding,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Total Spend', style: AppTypography.labelMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              totalSpend != null
                                  ? currencyFormat.format(totalSpend)
                                  : '—',
                              style: AppTypography.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.chartBorder.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Transactions', style: AppTypography.labelMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              transactionCount != null
                                  ? NumberFormat('#,###').format(transactionCount)
                                  : '—',
                              style: AppTypography.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sectionGap),
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
            const SizedBox(height: AppSpacing.sectionGap),
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
                showTransactionCount: true
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            // Transaction List
            FutureBuilder<({double totalSpend, int transactionCount, List<TransactionWithCategory> transactions})>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.itemsBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.chartBorder.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  );
                }

                final transactions = snapshot.data?.transactions ?? [];
                final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
                final dateFormat = DateFormat('MMM d, yyyy');

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.itemsBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.chartBorder.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transactions', style: AppTypography.chartTitle),
                      const SizedBox(height: AppSpacing.md),
                      if (transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(
                            child: Text('No transactions found', style: AppTypography.bodyMedium),
                          ),
                        )
                      else
                        Builder(builder: (context) {
                          // Build flat list: date headers interleaved with transactions
                          final items = <Object>[]; // String = date header, TransactionWithCategory = row
                          String? lastDate;
                          for (final twc in transactions) {
                            final dateStr = dateFormat.format(twc.transaction.dateCreated);
                            if (dateStr != lastDate) {
                              items.add(dateStr);
                              lastDate = dateStr;
                            }
                            items.add(twc);
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              if (item is String) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    top: index == 0 ? 0 : AppSpacing.md,
                                    bottom: AppSpacing.xs,
                                  ),
                                  child: Text(item, style: AppTypography.labelLarge),
                                );
                              }
                              final twc = item as TransactionWithCategory;
                              final t = twc.transaction;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.pageBackground.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.name,
                                              style: AppTypography.bodyLarge,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${twc.category.name}${twc.subCategory != null ? ' > ${twc.subCategory!.name}' : ''}',
                                              style: AppTypography.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        '${t.income ? '+' : '-'}${currencyFormat.format(t.amount.abs())}',
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: t.income ? AppColors.contentColorGreen : AppColors.contentColorRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}
