
import 'dart:async';
import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart' show RangeValues;

import 'package:cashew_graphs/database/databaseGlobal.dart';
part 'tables.g.dart';

// transaction, category


int schemaVersionGlobal = 46;

// To update and migrate the database, check the README

// Character Limits
const int NAME_LIMIT = 250;
const int NOTE_LIMIT = 500;
const int COLOUR_LIMIT = 50;

// Query Constants
const int DEFAULT_LIMIT = 100000;
const int DEFAULT_OFFSET = 0;

enum BudgetReoccurence { custom, daily, weekly, monthly, yearly }

enum TransactionSpecialType {
  upcoming,
  subscription,
  repetitive,
  credit, //lent, withdraw, owed
  debt, //borrowed, deposit, owe
}

enum ObjectiveType {
  goal,
  loan, //income==true ? lent (loan) : borrowed
}

enum SharedOwnerMember {
  owner,
  member,
}

enum ExpenseIncome {
  income,
  expense,
}

enum PaidStatus {
  paid,
  notPaid,
  skipped,
}

// You should explain what each one does to the user in ViewBudgetTransactionFilterInfo
// Implement the default and behavior here: onlyShowIfFollowsFilters
// Also add the default to the onboarding page budget creation: OnBoardingPageBodyState
enum BudgetTransactionFilters {
  addedToOtherBudget,
  sharedToOtherBudget,
  includeIncome, //disabled by default (as set by the function below: isFilterSelectedWithDefaults -> offByDefault)
  includeDebtAndCredit, //disabled by default (as set by the function below:isFilterSelectedWithDefaults ->  offByDefault)
  addedToObjective,
  defaultBudgetTransactionFilters, //if default is in the list, use the default behavior
  includeBalanceCorrection, //disabled by default
}

enum HomePageWidgetDisplay {
  WalletSwitcher,
  WalletList,
  NetWorth,
  AllSpendingSummary, //Income/Expense homescreen
  PieChart,
}

List<HomePageWidgetDisplay> defaultWalletHomePageWidgetDisplay = [
  HomePageWidgetDisplay.WalletSwitcher,
  HomePageWidgetDisplay.WalletList,
];

bool isFilterSelectedWithDefaults(
    List<BudgetTransactionFilters>? filters, BudgetTransactionFilters filter) {
  if (filters == null) return true;

  List<BudgetTransactionFilters> offByDefault = [
    BudgetTransactionFilters.includeIncome,
    BudgetTransactionFilters.includeDebtAndCredit,
    BudgetTransactionFilters.includeBalanceCorrection,
  ];

  if (filters
      .contains(BudgetTransactionFilters.defaultBudgetTransactionFilters)) {
    if (offByDefault.contains(filter)) {
      return false;
    }
    return true;
  } else {
    return filters.contains(filter);
  }
}

enum ThemeSetting { dark, light }

enum MethodAdded {
  email,
  shared,
  csv,
  preview,
  appLink,
}

enum SharedStatus { waiting, shared, error }

class IntListInColumnConverter extends TypeConverter<List<int>, String> {
  const IntListInColumnConverter();
  @override
  List<int> fromSql(String string_from_db) {
    return new List<int>.from(json.decode(string_from_db));
  }

  @override
  String toSql(List<int> ints) {
    return json.encode(ints);
  }
}

class BudgetTransactionFiltersListInColumnConverter
    extends TypeConverter<List<BudgetTransactionFilters>, String> {
  const BudgetTransactionFiltersListInColumnConverter();
  @override
  List<BudgetTransactionFilters> fromSql(String string_from_db) {
    List<int> ints = List<int>.from(json.decode(string_from_db));
    List<BudgetTransactionFilters> filters = ints
        .where((i) => i >= 0 && i < BudgetTransactionFilters.values.length)
        .map((i) => BudgetTransactionFilters.values[i])
        .toList();
    return filters;
  }

  @override
  String toSql(List<BudgetTransactionFilters> filters) {
    List<int> ints = filters.map((filter) => filter.index).toList();
    return json.encode(ints);
  }
}

class HomePageWidgetDisplayListInColumnConverter
    extends TypeConverter<List<HomePageWidgetDisplay>, String> {
  const HomePageWidgetDisplayListInColumnConverter();
  @override
  List<HomePageWidgetDisplay> fromSql(String string_from_db) {
    List<int> ints = List<int>.from(json.decode(string_from_db));
    List<HomePageWidgetDisplay> widgetDisplays = ints
        .where((i) => i >= 0 && i < HomePageWidgetDisplay.values.length)
        .map((i) => HomePageWidgetDisplay.values[i])
        .toList();
    return widgetDisplays;
  }

  @override
  String toSql(List<HomePageWidgetDisplay> filters) {
    List<int> ints = filters.map((filter) => filter.index).toList();
    return json.encode(ints);
  }
}

class StringListInColumnConverter extends TypeConverter<List<String>, String> {
  const StringListInColumnConverter();
  @override
  List<String> fromSql(String string_from_db) {
    List<dynamic> dynamicList = List<dynamic>.from(json.decode(string_from_db));
    List<String> stringList =
    dynamicList.map((dynamic item) => item.toString()).toList();
    return stringList;
  }

  @override
  String toSql(List<String> strings) {
    return json.encode(strings);
  }
}

class DoubleListInColumnConverter extends TypeConverter<List<double>, String> {
  const DoubleListInColumnConverter();
  @override
  List<double> fromSql(String string_from_db) {
    return new List<double>.from(json.decode(string_from_db));
  }

  @override
  String toSql(List<double> doubles) {
    return json.encode(doubles);
  }
}

enum DeleteLogType {
  TransactionWallet,
  TransactionCategory,
  Budget,
  CategoryBudgetLimit,
  Transaction,
  TransactionAssociatedTitle,
  ScannerTemplate,
  Objective,
  Unused, // Was for the scanner template, but is now unused
}

enum UpdateLogType {
  TransactionWallet,
  TransactionCategory,
  Budget,
  CategoryBudgetLimit,
  Transaction,
  TransactionAssociatedTitle,
  ScannerTemplate,
  Objective,
  Unused, // Was for the scanner template, but is now unused
}

@DataClassName('DeleteLog')
class DeleteLogs extends Table {
  TextColumn get deleteLogPk => text().clientDefault(() => uuid.v4())();
  TextColumn get entryPk => text()();
  IntColumn get type => intEnum<DeleteLogType>()();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {deleteLogPk};
}

@DataClassName('TransactionWallet')
class Wallets extends Table {
  TextColumn get walletPk => text().clientDefault(() => uuid.v4())();
  TextColumn get name => text().withLength(max: NAME_LIMIT)();
  TextColumn get colour => text().withLength(max: COLOUR_LIMIT).nullable()();
  TextColumn get iconName => text().nullable()(); // Money symbol
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => new DateTime.now())();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  IntColumn get order => integer()();
  TextColumn get currency => text().nullable()();
  TextColumn get currencyFormat => text().nullable()();
  IntColumn get decimals => integer().withDefault(Constant(2))();
  TextColumn get homePageWidgetDisplay => text()
      .nullable()
      .withDefault(const Constant(null))
      .map(const HomePageWidgetDisplayListInColumnConverter())();

  @override
  Set<Column> get primaryKey => {walletPk};
}

@DataClassName('Transaction')
class Transactions extends Table {
  TextColumn get transactionPk => text().clientDefault(() => uuid.v4())();
  TextColumn get pairedTransactionFk => text()
      .references(Transactions, #transactionPk)
      .withDefault(const Constant(null))
      .nullable()();
  TextColumn get name => text().withLength(max: NAME_LIMIT)();
  RealColumn get amount => real()();
  TextColumn get note => text().withLength(max: NOTE_LIMIT)();
  TextColumn get categoryFk => text().references(Categories, #categoryPk)();
  TextColumn get subCategoryFk => text()
      .references(Categories, #categoryPk)
      .withDefault(const Constant(null))
      .nullable()();
  TextColumn get walletFk =>
      text().references(Wallets, #walletPk).withDefault(const Constant("0"))();
  // TextColumn get labelFks =>
  //     text().map(const IntListInColumnConverter()).nullable()();
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => new DateTime.now())();
  // DateTimeColumn get dateTimeCreated =>
  //     dateTime().withDefault(Constant(DateTime.now())).nullable()();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  // The original date the transaction was due. When a transaction is paid, the date gets set to the current time
  // This stores the original date it was supposed to be due on.
  DateTimeColumn get originalDateDue =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  BoolColumn get income => boolean().withDefault(const Constant(false))();
  // Subscriptions and Repetitive payments
  IntColumn get periodLength => integer().nullable()();
  IntColumn get reoccurrence => intEnum<BudgetReoccurence>().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get upcomingTransactionNotification =>
      boolean().withDefault(const Constant(true)).nullable()();
  IntColumn get type => intEnum<TransactionSpecialType>().nullable()();
  // For credit and debts, paid will be true initially, then false when it is received/paid
  // this is the opposite of what is expected - but taht's because we only want it to count for the totals
  // until it is recieved/paid off resulting in a net of 0
  BoolColumn get paid => boolean().withDefault(const Constant(false))();
  // If user sets to paid and then un pays it will not create a new transaction
  BoolColumn get createdAnotherFutureTransaction =>
      boolean().withDefault(const Constant(false)).nullable()();
  BoolColumn get skipPaid => boolean().withDefault(const Constant(false))();
  // methodAdded will be shared if downloaded from shared server
  IntColumn get methodAdded => intEnum<MethodAdded>().nullable()();
  // Attributes to configure sharing of transactions:
  // Note: a transaction has not been published until methodAdded is shared and sharedKey is not null
  TextColumn get transactionOwnerEmail => text().nullable()();
  TextColumn get transactionOriginalOwnerEmail => text().nullable()();
  TextColumn get sharedKey => text().nullable()();
  TextColumn get sharedOldKey => text()
      .nullable()(); // when a transaction removed shared, this will be sharedKey
  IntColumn get sharedStatus => intEnum<SharedStatus>().nullable()();
  DateTimeColumn get sharedDateUpdated => dateTime().nullable()();
  // the budget this transaction belongs to
  TextColumn get sharedReferenceBudgetPk => text().nullable()();
  TextColumn get objectiveFk =>
      text().references(Objectives, #objectivePk).nullable()();
  TextColumn get objectiveLoanFk =>
      text().references(Objectives, #objectivePk).nullable()();
  TextColumn get budgetFksExclude =>
      text().map(const StringListInColumnConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {transactionPk};
}

@DataClassName('TransactionCategory')
class Categories extends Table {
  TextColumn get categoryPk => text().clientDefault(() => uuid.v4())();
  TextColumn get name => text().withLength(max: NAME_LIMIT)();
  TextColumn get colour => text().withLength(max: COLOUR_LIMIT).nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get emojiIconName => text().nullable()();
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => new DateTime.now())();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  IntColumn get order => integer()();
  BoolColumn get income => boolean().withDefault(const Constant(false))();
  IntColumn get methodAdded => intEnum<MethodAdded>().nullable()();
  // If mainCategoryPk is null, it is a main category and can have sub categories
  // If mainCategoryPk is NOT null, it is a subcategory
  TextColumn get mainCategoryPk => text()
      .references(Categories, #categoryPk)
      .withDefault(const Constant(null))
      .nullable()();

  // Attributes to configure sharing of transactions:
  // sharedKey will have the key referencing the entry in the firebase database, if this is null, it is not shared
  // TextColumn get sharedKey => text().nullable()();
  // IntColumn get sharedOwnerMember => intEnum<SharedOwnerMember>().nullable()();
  // DateTimeColumn get sharedDateUpdated => dateTime().nullable()();
  // TextColumn get sharedMembers =>
  //     text().map(const StringListInColumnConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {categoryPk};
}

@DataClassName('CategoryBudgetLimit')
class CategoryBudgetLimits extends Table {
  TextColumn get categoryLimitPk => text().clientDefault(() => uuid.v4())();
  TextColumn get categoryFk => text().references(Categories, #categoryPk)();
  TextColumn get budgetFk => text().references(Budgets, #budgetPk)();
  RealColumn get amount => real()();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  TextColumn get walletFk =>
      text().references(Wallets, #walletPk).withDefault(const Constant("0"))();

  @override
  Set<Column> get primaryKey => {categoryLimitPk};
}

//If a title is in a smart label, automatically choose this category
// For e.g. for Food category
// smartLabels = ["apple", "pear"]
// Then when user sets title to pineapple, it will set the category to Food. Because "apple" is in "pineapple".
@DataClassName('TransactionAssociatedTitle')
class AssociatedTitles extends Table {
  TextColumn get associatedTitlePk => text().clientDefault(() => uuid.v4())();
  TextColumn get categoryFk => text().references(Categories, #categoryPk)();
  TextColumn get title => text().withLength(max: NAME_LIMIT)();
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => new DateTime.now())();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  IntColumn get order => integer()();
  BoolColumn get isExactMatch => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {associatedTitlePk};
}

// @DataClassName('TransactionLabel')
// class Labels extends Table {
//   IntColumn get label_pk => integer().autoIncrement()();
//   TextColumn get name => text().withLength(max: NAME_LIMIT)();
//   IntColumn get categoryFk => integer().references(Categories, #categoryPk)();
//   DateTimeColumn get dateCreated =>
//       dateTime().clientDefault(() => new DateTime.now())();
//   DateTimeColumn get dateTimeModified =>
//       dateTime().withDefault(Constant(DateTime.now())).nullable()();
//   IntColumn get order => integer()();
// }

@DataClassName('Budget')
class Budgets extends Table {
  TextColumn get budgetPk => text().clientDefault(() => uuid.v4())();
  TextColumn get name => text().withLength(max: NAME_LIMIT)();
  RealColumn get amount => real()();
  TextColumn get colour => text()
      .withLength(max: COLOUR_LIMIT)
      .nullable()(); // if null we are using the themes color
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get walletFks =>
      text().map(const StringListInColumnConverter()).nullable()();
  TextColumn get categoryFks =>
      text().map(const StringListInColumnConverter()).nullable()();
  TextColumn get categoryFksExclude =>
      text().map(const StringListInColumnConverter()).nullable()();
  // BoolColumn get allCategoryFks => boolean()();
  BoolColumn get income => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  BoolColumn get addedTransactionsOnly =>
      boolean().withDefault(const Constant(false))();
  IntColumn get periodLength => integer()();
  IntColumn get reoccurrence => intEnum<BudgetReoccurence>().nullable()();
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => new DateTime.now())();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  IntColumn get order => integer()();
  TextColumn get walletFk =>
      text().references(Wallets, #walletPk).withDefault(const Constant("0"))();
  TextColumn get budgetTransactionFilters => text()
      .nullable()
      .withDefault(const Constant(null))
      .map(const BudgetTransactionFiltersListInColumnConverter())();
  TextColumn get memberTransactionFilters => text()
      .nullable()
      .withDefault(const Constant(null))
      .map(const StringListInColumnConverter())();
  // Attributes to configure sharing of transactions:
  // sharedKey will have the key referencing the entry in the firebase database, if this is null, it is not shared
  TextColumn get sharedKey => text().nullable()();
  IntColumn get sharedOwnerMember => intEnum<SharedOwnerMember>().nullable()();
  DateTimeColumn get sharedDateUpdated => dateTime().nullable()();
  TextColumn get sharedMembers =>
      text().map(const StringListInColumnConverter()).nullable()();
  TextColumn get sharedAllMembersEver =>
      text().map(const StringListInColumnConverter()).nullable()();
  BoolColumn get isAbsoluteSpendingLimit =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {budgetPk};
}
// Server entry

@DataClassName('AppSetting')
class AppSettings extends Table {
  // We can keep it as an IntColumn, there will only ever be one entry at id 0
  IntColumn get settingsPk => integer().autoIncrement()();
  TextColumn get settingsJSON =>
      text()(); // This is the JSON stored as a string for shared prefs 'userSettings'
  DateTimeColumn get dateUpdated =>
      dateTime().clientDefault(() => new DateTime.now())();
}

@DataClassName('ScannerTemplate')
class ScannerTemplates extends Table {
  TextColumn get scannerTemplatePk => text().clientDefault(() => uuid.v4())();
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => new DateTime.now())();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  TextColumn get templateName => text().withLength(max: NAME_LIMIT)();
  TextColumn get contains => text().withLength(max: NAME_LIMIT)();
  TextColumn get titleTransactionBefore => text().withLength(max: NAME_LIMIT)();
  TextColumn get titleTransactionAfter => text().withLength(max: NAME_LIMIT)();
  TextColumn get amountTransactionBefore =>
      text().withLength(max: NAME_LIMIT)();
  TextColumn get amountTransactionAfter => text().withLength(max: NAME_LIMIT)();
  TextColumn get defaultCategoryFk =>
      text().references(Categories, #categoryPk)();
  TextColumn get walletFk =>
      text().references(Wallets, #walletPk).withDefault(const Constant("0"))();
  // TODO: if it contains certain keyword ignore these emails
  BoolColumn get ignore => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {scannerTemplatePk};
}

// Objective, savings jars, payment goals, installments, targets etc.
@DataClassName('Objective')
class Objectives extends Table {
  TextColumn get objectivePk => text().clientDefault(() => uuid.v4())();
  IntColumn get type => intEnum<ObjectiveType>().withDefault(Constant(0))();
  TextColumn get name => text().withLength(max: NAME_LIMIT)();
  RealColumn get amount => real()();
  IntColumn get order => integer()();
  TextColumn get colour => text()
      .withLength(max: COLOUR_LIMIT)
      .nullable()(); // if null we are using the themes color
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => new DateTime.now())();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now())).nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get emojiIconName => text().nullable()();
  BoolColumn get income => boolean().withDefault(const Constant(false))();
  BoolColumn get pinned => boolean().withDefault(const Constant(true))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get walletFk =>
      text().references(Wallets, #walletPk).withDefault(const Constant("0"))();

  @override
  Set<Column> get primaryKey => {objectivePk};
}

class TransactionWithCategory {
  final TransactionCategory category;
  final Transaction transaction;
  final TransactionWallet? wallet;
  final Budget? budget;
  final Objective? objective;
  final TransactionCategory? subCategory;
  final Objective? objectiveLoan;
  TransactionWithCategory({
    required this.category,
    required this.transaction,
    this.wallet,
    this.budget,
    this.objective,
    this.subCategory,
    required this.objectiveLoan,
  });
}

class TransactionActivityLog {
  final DateTime dateTime;
  final Transaction? transaction;
  final TransactionWithCategory? transactionWithCategory;
  final DeleteLog? deleteLog;

  TransactionActivityLog({
    required this.dateTime,
    required this.transaction,
    this.transactionWithCategory,
    this.deleteLog,
  });
}

class CategoryWithDetails {
  final TransactionCategory category;
  final int? numberTransactions;
  CategoryWithDetails({
    required this.category,
    this.numberTransactions,
  });
}

class WalletWithDetails {
  final TransactionWallet wallet;
  final double? totalSpent;
  final int? numberTransactions;
  WalletWithDetails({
    required this.wallet,
    this.totalSpent,
    this.numberTransactions,
  });
}

class AllWallets {
  final List<TransactionWallet> list;
  final Map<String, TransactionWallet> indexedByPk;
  AllWallets({required this.list, required this.indexedByPk});

  bool allContainSameCurrency() {
    if (list.isEmpty) {
      return false;
    }
    final String? firstCurrency = list.first.currency;
    return list.every((wallet) => wallet.currency == firstCurrency);
  }

  bool containsMultipleAccountsWithSameCurrency() {
    if (list.isEmpty) {
      return false;
    }

    final Set<String> uniqueCurrencies = {};

    for (TransactionWallet wallet in list) {
      final String? currency = wallet.currency;

      if (uniqueCurrencies.contains(currency)) {
        return true;
      } else {
        uniqueCurrencies.add(currency!);
      }
    }

    return false;
  }
}

class SelectedWalletPk with ChangeNotifier {
  String selectedWalletPk;
  SelectedWalletPk({required this.selectedWalletPk});
}

class CategoryWithTotal {
  final TransactionCategory category;
  final CategoryBudgetLimit? categoryBudgetLimit;
  final double total;
  final int transactionCount;

  CategoryWithTotal({
    required this.category,
    required this.total,
    this.transactionCount = 0,
    this.categoryBudgetLimit,
  });

  @override
  String toString() {
    return 'CategoryWithTotal {'
        'category: ${category.name}, '
        'total: $total, '
        '}';
  }

  CategoryWithTotal copyWith({
    TransactionCategory? category,
    CategoryBudgetLimit? categoryBudgetLimit,
    double? total,
    int? transactionCount,
  }) {
    return CategoryWithTotal(
      category: category ?? this.category,
      categoryBudgetLimit: categoryBudgetLimit ?? this.categoryBudgetLimit,
      total: total ?? this.total,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }
}


// bool canAddToBudget(bool? income, TransactionSpecialType? transactionType) {
//   return income != true &&
//       transactionType != TransactionSpecialType.credit &&
//       transactionType != TransactionSpecialType.debt;
// }

// when adding a new table, make sure to enable syncing and that
// all relevant delete queries create delete logs
// Modify processSyncLogs to process the update/creation and delete!
// Modify syncData to process the newly created!
@DriftDatabase(tables: [
  Wallets,
  Transactions,
  Categories,
  CategoryBudgetLimits,
  // Labels,
  AssociatedTitles,
  Budgets,
  AppSettings,
  ScannerTemplates,
  DeleteLogs,
  Objectives,
])
class FinanceDatabase extends _$FinanceDatabase {

  FinanceDatabase() : super(_openConnection());
  // FinanceDatabase(QueryExecutor e) : super(e);

  // you should bump this number whenever you change or add a table definition
  @override
  int get schemaVersion => schemaVersionGlobal;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      // Get the app's documents directory
      final dbFolder = await getApplicationDocumentsDirectory();
      print("path");
      print(dbFolder.path);
      print("path end");
      final file = File(p.join(dbFolder.path, 'dummy-db.db'));

      print("Loading DB...");

      // Load the database file from assets
      final blob = await rootBundle.load('assets/dummy-db.db');
      final buffer = blob.buffer;

      // Write the database file to the documents directory
      await file.writeAsBytes(
          buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes)
      );

      print("Database copied from assets successfully");

      // This is the actual SQLite file path
      return NativeDatabase.createInBackground(file);
    });
  }


  Future<void> deleteEverything() {
    return transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }


  //get transactions that occurred on a given date
  (Stream<List<Transaction>>, Future<List<Transaction>>) getTransactionWithDate(
      DateTime date) {
    final SimpleSelectStatement<$TransactionsTable, Transaction> query =
    select(transactions)..where((tbl) => tbl.dateCreated.equals(date));
    return (query.watch(), query.get());
  }

  //watch all transactions sorted by date
  Stream<List<Transaction>> watchAllTransactions(
      {int? limit, DateTime? startDate, DateTime? endDate}) {
    return (select(transactions)
      ..where((tbl) {
        if (startDate != null && endDate != null) {
          return tbl.dateCreated.isBiggerOrEqualValue(startDate) &
          tbl.dateCreated.isSmallerOrEqualValue(endDate);
        } else {
          return tbl.walletFk.isNotNull();
        }
      })
      ..orderBy([(b) => OrderingTerm.desc(b.dateCreated)])
      ..limit(limit ?? DEFAULT_LIMIT))
        .watch();
  }

  // This gets all overdue subscription transactions
  (Stream<List<Transaction>>, Future<List<Transaction>>) getAllSubscriptions() {
    final query = select(transactions)
      ..orderBy([(t) => OrderingTerm.asc(t.dateCreated)])
      ..where(
            (transaction) =>
        transactions.paid.equals(false) &
        transactions.type
            .equals(TransactionSpecialType.subscription.index) &
        transactions.skipPaid.equals(false),
      );
    return (query.watch(), query.get());
  }


  // watch all budgets that have been created
  Stream<List<Budget>> watchAllBudgets({
    String? searchFor,
    int? limit,
    int? offset,
    bool hideArchived = false,
    bool archivedLast = false,
  }) {
    return (select(budgets)
      ..where((b) =>
      (hideArchived == true
          ? b.archived.equals(false)
          : Constant(true)) &
      (searchFor == null
          ? Constant(true)
          : b.name
          .collate(Collate.noCase)
          .like("%" + (searchFor) + "%")))
      ..orderBy([
        if (archivedLast) (b) => OrderingTerm.asc(b.archived),
            (b) => OrderingTerm.asc(b.order)
      ])
      ..limit(limit ?? DEFAULT_LIMIT, offset: offset ?? DEFAULT_OFFSET))
        .watch();
  }

  Stream<Budget> getBudget(String budgetPk) {
    return (select(budgets)..where((b) => b.budgetPk.equals(budgetPk)))
        .watchSingle();
  }

  Stream<Objective> getObjective(String objectivePk) {
    return (select(objectives)..where((o) => o.objectivePk.equals(objectivePk)))
        .watchSingle();
  }

  Stream<TransactionWallet> getWallet(String walletPk) {
    return (select(wallets)..where((w) => w.walletPk.equals(walletPk)))
        .watchSingle();
  }

  Future<int> getAmountOfBudgets() async {
    return (await select(budgets).get()).length;
  }

  Future<List<Transaction>> getAllPreviewTransactions() {
    return (select(transactions)
      ..where((tbl) =>
      tbl.methodAdded.equalsValue(MethodAdded.preview) &
      tbl.methodAdded.isNotNull()))
        .get();
  }


  Future<Map<String, TransactionCategory>> getAllCategoriesIndexed() async {
    List<TransactionCategory> allCategories = (await ((select(categories)
      ..orderBy([(w) => OrderingTerm.asc(w.order)]))
        .get()));
    Map<String, TransactionCategory> indexedByPk = {
      for (TransactionCategory category in allCategories)
        category.categoryPk: category,
    };
    return indexedByPk;
  }

  Stream<AllWallets> watchAllWalletsIndexed() {
    return (select(wallets)..orderBy([(w) => OrderingTerm.asc(w.order)]))
        .watch()
        .map((wallets) {
      Map<String, TransactionWallet> indexedByPk = {
        for (TransactionWallet wallet in wallets) wallet.walletPk: wallet,
      };
      return AllWallets(
        list: wallets,
        indexedByPk: indexedByPk,
      );
    });
  }

  Stream<List<TransactionWallet>> watchAllWallets(
      {String? searchFor, int? limit, int? offset}) {
    return (select(wallets)
      ..where((w) => (searchFor == null
          ? Constant(true)
          : w.name.collate(Collate.noCase).like("%" + (searchFor) + "%")))
      ..orderBy([(w) => OrderingTerm.asc(w.order)])
      ..limit(limit ?? DEFAULT_LIMIT, offset: offset ?? DEFAULT_OFFSET))
        .watch();
  }

  Stream<List<WalletWithDetails>> watchAllWalletsWithDetails(
      {String? searchFor,
        HomePageWidgetDisplay? homePageWidgetDisplay,
        bool mergeLikeCurrencies = false}) {
    JoinedSelectStatement<HasResultSet, dynamic> query;
    final totalCount = transactions.transactionPk.count();
    final totalSpent =
    transactions.amount.sum(filter: transactions.paid.equals(true));
    query = (select(wallets)
      ..where((w) => ((homePageWidgetDisplay != null
          ? w.homePageWidgetDisplay
          .contains(homePageWidgetDisplay.index.toString())
          : Constant(true)) &
      (searchFor == null
          ? Constant(true)
          : w.name
          .collate(Collate.noCase)
          .like("%" + (searchFor) + "%"))))
      ..orderBy([(w) => OrderingTerm.asc(w.order)]))
        .join([
      leftOuterJoin(
          transactions, transactions.walletFk.equalsExp(wallets.walletPk)),
    ])
    // ..where(transactions.walletFk.isNull() |
    //     onlyShowIfFollowCustomPeriodCycle(
    //         transactions, homePageWidgetDisplay != null,
    //         cycleSettingsExtension: homePageWidgetDisplay ==
    //                 HomePageWidgetDisplay.WalletSwitcher
    //             ? "Wallets"
    //             : homePageWidgetDisplay == HomePageWidgetDisplay.WalletList
    //                 ? "WalletsList"
    //                 : ""))
      ..groupBy(mergeLikeCurrencies ? [wallets.currency] : [wallets.walletPk])
      ..addColumns([totalCount, totalSpent]);

    return query.watch().map((rows) => rows.map((row) {
      return WalletWithDetails(
        wallet: row.readTable(wallets),
        numberTransactions: row.read(totalCount),
        totalSpent: row.read(totalSpent),
      );
    }).toList());
  }

  Stream<List<ScannerTemplate>> watchAllScannerTemplates(
      {int? limit, int? offset}) {
    return (select(scannerTemplates)
      ..orderBy([(s) => OrderingTerm.asc(s.dateCreated)])
      ..limit(limit ?? DEFAULT_LIMIT, offset: offset ?? DEFAULT_OFFSET))
        .watch();
  }

  Future<List<ScannerTemplate>> getAllScannerTemplates(
      {int? limit, int? offset}) {
    return (select(scannerTemplates)
      ..orderBy([(s) => OrderingTerm.asc(s.dateCreated)])
      ..limit(limit ?? DEFAULT_LIMIT, offset: offset ?? DEFAULT_OFFSET))
        .get();
  }

  Future<List<TransactionWallet>> getAllWallets({int? limit, int? offset}) {
    return (select(wallets)
      ..orderBy([(w) => OrderingTerm.asc(w.order)])
      ..limit(limit ?? DEFAULT_LIMIT, offset: offset ?? DEFAULT_OFFSET))
        .get();
  }

  Future<List<TransactionCategory>> getAllCategories({int? limit, int? offset}) {
    return (select(categories)
      ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  Future<List<TransactionWallet>> getAllNewWallets(DateTime lastSynced) {
    return (select(wallets)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future<List<Transaction>> getAllNewTransactions(DateTime lastSynced) {
    return (select(transactions)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future<List<TransactionWithCategory>>
  getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
      Expression<bool> Function($TransactionsTable) filter) async {
    final subCategories = alias(categories, 'subCategories');
    final $ObjectivesTable objectiveLoans = alias(objectives, 'objectiveLoans');
    final query = (select(transactions)
      ..where(filter)
      ..orderBy([(t) => OrderingTerm.desc(t.dateCreated)]))
        .join([
      innerJoin(
        categories,
        categories.categoryPk.equalsExp(transactions.categoryFk),
      ),
      innerJoin(
        wallets,
        wallets.walletPk.equalsExp(transactions.walletFk),
      ),
      leftOuterJoin(
        budgets,
        budgets.budgetPk.equalsExp(transactions.sharedReferenceBudgetPk),
      ),
      leftOuterJoin(
        objectives,
        objectives.objectivePk.equalsExp(transactions.objectiveFk),
      ),
      leftOuterJoin(
        objectiveLoans,
        objectiveLoans.objectivePk.equalsExp(transactions.objectiveLoanFk),
      ),
      leftOuterJoin(subCategories,
          subCategories.categoryPk.equalsExp(transactions.subCategoryFk)),
    ]);

    final rows = await query.get();

    return rows.map((row) {
      return TransactionWithCategory(
        category: row.readTable(categories),
        transaction: row.readTable(transactions),
        wallet: row.readTableOrNull(wallets),
        budget: row.readTableOrNull(budgets),
        objective: row.readTableOrNull(objectives),
        subCategory: row.readTableOrNull(subCategories),
        objectiveLoan: row.readTableOrNull(objectiveLoans),
      );
    }).toList();
  }


  Future<List<TransactionWithCategory>>
  getTransactionsWithCategoryWalletBudgetObjectiveSubCategoryInDateRange(
      Expression<bool> Function($TransactionsTable) filter) async {
    final subCategories = alias(categories, 'subCategories');
    final $ObjectivesTable objectiveLoans = alias(objectives, 'objectiveLoans');
    final query = (select(transactions)
      ..where(filter)
      ..orderBy([(t) => OrderingTerm.desc(t.dateCreated)]))
        .join([
      innerJoin(
        categories,
        categories.categoryPk.equalsExp(transactions.categoryFk),
      ),
      innerJoin(
        wallets,
        wallets.walletPk.equalsExp(transactions.walletFk),
      ),
      leftOuterJoin(
        budgets,
        budgets.budgetPk.equalsExp(transactions.sharedReferenceBudgetPk),
      ),
      leftOuterJoin(
        objectives,
        objectives.objectivePk.equalsExp(transactions.objectiveFk),
      ),
      leftOuterJoin(
        objectiveLoans,
        objectiveLoans.objectivePk.equalsExp(transactions.objectiveLoanFk),
      ),
      leftOuterJoin(subCategories,
          subCategories.categoryPk.equalsExp(transactions.subCategoryFk)),
    ]);

    final rows = await query.get();

    return rows.map((row) {
      return TransactionWithCategory(
        category: row.readTable(categories),
        transaction: row.readTable(transactions),
        wallet: row.readTableOrNull(wallets),
        budget: row.readTableOrNull(budgets),
        objective: row.readTableOrNull(objectives),
        subCategory: row.readTableOrNull(subCategories),
        objectiveLoan: row.readTableOrNull(objectiveLoans),
      );
    }).toList();
  }


  Future<List<TransactionCategory>> getAllNewCategories(DateTime lastSynced) {
    return (select(categories)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future<List<CategoryBudgetLimit>> getAllNewCategoryBudgetLimits(
      DateTime lastSynced) {
    return (select(categoryBudgetLimits)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future<List<TransactionAssociatedTitle>> getAllNewAssociatedTitles(
      DateTime lastSynced) {
    return (select(associatedTitles)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future<List<Budget>> getAllNewBudgets(DateTime lastSynced) {
    return (select(budgets)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future<List<Objective>> getAllNewObjectives(DateTime lastSynced) {
    return (select(objectives)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future<List<ScannerTemplate>> getAllNewScannerTemplates(DateTime lastSynced) {
    return (select(scannerTemplates)
      ..where((tbl) =>
      tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced) |
      tbl.dateTimeModified.isNull()))
        .get();
  }

  Future getAmountOfWallets() async {
    return (await select(budgets).get()).length;
  }

  Future moveWallet(String walletPk, int newPosition, int oldPosition) async {
    List<TransactionWallet> walletsList = await (select(wallets)
      ..orderBy([(w) => OrderingTerm.asc(w.order)]))
        .get();
    await batch((batch) {
      if (newPosition > oldPosition) {
        for (TransactionWallet wallet in walletsList) {
          batch.update(
            wallets,
            WalletsCompanion(
              order: Value(wallet.order - 1),
              dateTimeModified: Value(DateTime.now()),
            ),
            where: (w) =>
            w.walletPk.equals(wallet.walletPk) &
            w.order.isBiggerOrEqualValue(oldPosition) &
            w.order.isSmallerOrEqualValue(newPosition),
          );
        }
      } else {
        for (TransactionWallet wallet in walletsList) {
          batch.update(
            wallets,
            WalletsCompanion(
              order: Value(wallet.order + 1),
              dateTimeModified: Value(DateTime.now()),
            ),
            where: (w) =>
            w.walletPk.equals(wallet.walletPk) &
            w.order.isBiggerOrEqualValue(newPosition) &
            w.order.isSmallerOrEqualValue(oldPosition),
          );
        }
      }
      batch.update(
        wallets,
        WalletsCompanion(
          order: Value(newPosition),
          dateTimeModified: Value(DateTime.now()),
        ),
        where: (w) => w.walletPk.equals(walletPk),
      );
    });
  }

  Future<bool> shiftWallets(int direction, int pastIndexIncluding) async {
    List<TransactionWallet> walletsList = await (select(wallets)
      ..orderBy([(b) => OrderingTerm.asc(b.order)]))
        .get();
    if (direction == -1 || direction == 1) {
      for (TransactionWallet wallet in walletsList) {
        await (update(wallets)
          ..where(
                (w) =>
            w.order.isBiggerOrEqualValue(pastIndexIncluding) &
            w.walletPk.equals(wallet.walletPk),
          ))
            .write(
          WalletsCompanion(
            order: Value(wallet.order + direction),
            dateTimeModified: Value(DateTime.now()),
          ),
        );
      }
    } else {
      return false;
    }
    return true;
  }

  Future<List<DeleteLog>> getAllNewDeleteLogs(DateTime lastSynced) async {
    return (select(deleteLogs)
      ..where(
              (tbl) => tbl.dateTimeModified.isBiggerOrEqualValue(lastSynced)))
        .get();
  }

  Future<List<DeleteLog>> getAllDeleteLogs() async {
    return select(deleteLogs).get();
  }




  //Overwrite settings entry, it will always have id 0
  Future<int> createOrUpdateSettings(AppSetting setting) {
    return into(appSettings).insertOnConflictUpdate(setting);
  }

  Future<AppSetting> getSettings() {
    return (select(appSettings)..where((s) => s.settingsPk.equals(0)))
        .getSingle();
  }

  //create or update a new wallet
  Future<int> createOrUpdateWallet(TransactionWallet wallet,
      {DateTime? customDateTimeModified, bool insert = false}) {
    wallet = wallet.copyWith(name: wallet.name.trim());
    wallet = wallet.copyWith(
        dateTimeModified: Value(customDateTimeModified ?? DateTime.now()));
    WalletsCompanion companionToInsert = wallet.toCompanion(true);

    if (insert) {
      // Use auto incremented ID when inserting
      companionToInsert = companionToInsert.copyWith(
        walletPk: Value.absent(),
        homePageWidgetDisplay: Value(defaultWalletHomePageWidgetDisplay),
      );
    }

    return into(wallets)
        .insert((companionToInsert), mode: InsertMode.insertOrReplace);
  }

  //create or update a new wallet
  Future<int> createOrUpdateScannerTemplate(ScannerTemplate scannerTemplate,
      {bool insert = false}) {
    scannerTemplate =
        scannerTemplate.copyWith(dateTimeModified: Value(DateTime.now()));
    ScannerTemplatesCompanion companionToInsert =
    scannerTemplate.toCompanion(true);

    if (insert) {
      // Use auto incremented ID when inserting
      companionToInsert =
          companionToInsert.copyWith(scannerTemplatePk: Value.absent());
    }

    return into(scannerTemplates)
        .insert((companionToInsert), mode: InsertMode.insertOrReplace);
  }

  Future<int> createOrUpdateCategoryLimit(CategoryBudgetLimit categoryLimit,
      {bool insert = false}) async {
    double maxAmount = 999999999999;
    if (categoryLimit.amount >= maxAmount)
      categoryLimit = categoryLimit.copyWith(amount: maxAmount);
    else if (categoryLimit.amount <= -maxAmount)
      categoryLimit = categoryLimit.copyWith(amount: -maxAmount);

    categoryLimit =
        categoryLimit.copyWith(dateTimeModified: Value(DateTime.now()));

    CategoryBudgetLimitsCompanion companionToInsert =
    categoryLimit.toCompanion(true);

    if (insert) {
      // Use auto incremented ID when inserting
      companionToInsert =
          companionToInsert.copyWith(categoryLimitPk: Value.absent());
    }

    return into(categoryBudgetLimits)
        .insert((companionToInsert), mode: InsertMode.insertOrReplace);
  }

  Stream<List<TransactionAssociatedTitleWithCategory>> watchAllAssociatedTitles(
      {String? searchFor, int? limit, int? offset}) {
    return (select(associatedTitles).join([
      // Inner instead of outer because transaction category is required
      // If we do an outer join and the title does not have a category, the query will fail
      innerJoin(categories,
          categories.categoryPk.equalsExp(associatedTitles.categoryFk)),
    ])
      ..where(searchFor == null
          ? Constant(true)
          : associatedTitles.title
          .collate(Collate.noCase)
          .like("%" + (searchFor) + "%"))
      ..orderBy([OrderingTerm.desc(associatedTitles.order)])
        // ..limit(limit ?? DEFAULT_LIMIT, offset: offset ?? DEFAULT_OFFSET)
    )
        .watch()
        .map((rows) => rows.map((row) {
      return TransactionAssociatedTitleWithCategory(
        title: row.readTable(associatedTitles),
        category: row.readTable(categories),
        type: TitleType.TitleExists,
      );
    }).toList());
  }

  Future<List<TransactionAssociatedTitle>> getAllAssociatedTitles(
      {int? limit, int? offset}) {
    return (select(associatedTitles)
      ..orderBy([(t) => OrderingTerm.desc(t.order)])
        // ..limit(limit ?? DEFAULT_LIMIT, offset: offset ?? DEFAULT_OFFSET)
    )
        .get();
  }

  Future<List<Transaction>> getAllTransactionsInChronologicalOrder(
      {int? limit, int? offset}) {
    return (select(transactions)
    ..orderBy([(t) => OrderingTerm.asc(t.dateCreated)])

    ).get();
  }

  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) {
    return (select(transactions)
      ..where((t) => t.dateCreated.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.dateCreated)]))
        .get();
  }

}

class TotalWithCount {
  final double total;
  final int count;

  TotalWithCount({required this.total, required this.count});

  @override
  String toString() {
    return 'TotalWithCount(total: $total, count: $count)';
  }
}

class TransactionWithCount {
  final Transaction transaction;
  final int count;

  TransactionWithCount({required this.transaction, required this.count});

  @override
  String toString() {
    return 'TransactionWithCount(transaction: $transaction, count: $count)';
  }
}

class EarliestLatestDateTime {
  final DateTime earliest;
  final DateTime latest;

  EarliestLatestDateTime({required this.earliest, required this.latest});

  @override
  String toString() {
    return 'EarliestLatestDateTime(earliest: $earliest, latest: $latest)';
  }
}

enum TitleType {
  TitleExists,
  CategoryName,
  SubCategoryName,
  PartialTitleExists,
}

class TransactionAssociatedTitleWithCategory {
  final TransactionAssociatedTitle title;
  final TransactionCategory category;
  final TitleType type;
  final String? partialTitleString;

  TransactionAssociatedTitleWithCategory({
    required this.type,
    required this.title,
    required this.category,
    this.partialTitleString,
  });

  @override
  String toString() {
    return 'TransactionAssociatedTitleWithCategory(type: $type, title: $title, category: $category, partialTitleString: $partialTitleString)';
  }
}