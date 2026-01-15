import 'dart:math';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;


enum TimeUnit {
  day,
  month
}


DateTime getStartOfCurrentMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1, 0, 0, 0, 0, 0);
}

/// Get the end date of the current month (last day at 23:59:59.999)
DateTime getEndOfCurrentMonth() {
  final now = DateTime.now();
  // Get the first day of next month, then subtract 1 millisecond
  final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
  return firstDayNextMonth.subtract(const Duration(milliseconds: 1));
}

/// Get the default end date for graphs:
/// - If today is the last day of the month, return end of today
/// - Otherwise, return end of tomorrow (today + 1 day)
DateTime getDefaultEndDate() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  // Check if today is the last day of the month (tomorrow is a different month)
  final isLastDayOfMonth = tomorrow.month != now.month;

  if (isLastDayOfMonth) {
    // Return end of today (23:59:59.999)
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  } else {
    // Return end of tomorrow (23:59:59.999)
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59, 999);
  }
}

/// Get both start and end dates as a record (Dart 3.0+)
({DateTime start, DateTime end}) getCurrentMonthRange() {
  return (
  start: getStartOfCurrentMonth(),
  end: getEndOfCurrentMonth(),
  );
}

/// Get default range
({DateTime start, DateTime end}) getDefaultDateRange() {
  return (
  start: getStartOfCurrentMonth(),
  end: getDefaultEndDate(),
  );
}
/// Get both start and end dates as a record (Dart 3.0+)
({DateTime start, DateTime end}) getCustomMonthRange() {
  return (
  start: getStartOfCurrentMonth(),
  end: getEndOfCurrentMonth(),
  );
}


bool isPartOfSameTimePeriod({required DateTime a, required DateTime b, required TimeUnit timeUnit}){
  if(timeUnit == TimeUnit.day){
    return (a.day == b.day) && (a.month == b.month) && (a.year == b.year);
  }
  else if(timeUnit == TimeUnit.month){
    return (a.month == b.month) && (a.year == b.year);
  }
  else{
    throw InvalidDataException("Invalid Time Unit");
  }
}

DateTime createNextSeriesDateTime({required DateTime previousDate, required TimeUnit timeUnit}) {
  if(timeUnit == TimeUnit.day){
    return DateTime(previousDate.year, previousDate.month, previousDate.day+1);
  } else if(timeUnit == TimeUnit.month) {
    return DateTime(previousDate.year, previousDate.month+1, previousDate.day);
  }else {
    throw InvalidDataException("Invalid Time Unit");
  }
}

int getScaleInPowerOf10(double ip){
  int scale = 0;
  while(ip/pow(10, scale) >= 10) {
    scale += 1;
  }
  return scale;
}

String getDisplayTextForAmount(double value){
  int scale = getScaleInPowerOf10(value);

  if(scale < 3){
    return value.toStringAsFixed(0);
  } else if(scale < 5) {
    value = value/1000;
    return "${value.toStringAsFixed(0)}K";
  } else if(scale < 7) {
    value = value/100000;
    return "${value.toStringAsFixed(0)}L";
  } else {
    value = value/10000000;
    return "${value.toStringAsFixed(0)}Cr";
  }
}

String getDisplayTextForDate(DateTime date, TimeUnit timeUnit, DateTime rangeStart, DateTime rangeEnd){
  if(timeUnit == TimeUnit.day){
    if(rangeStart.year == rangeEnd.year){
      String abvMonthName = DateFormat("MMM").format(date);
      return "${date.day} $abvMonthName";
    }else {
      return "${date.day}/${date.month}/${date.year.toString().substring(2)}";
    }
  } else if(timeUnit == TimeUnit.month){
    String abvMonthName = DateFormat("MMM").format(date);
    if(rangeStart.year == rangeEnd.year){
      return abvMonthName;
    }else {
      return "$abvMonthName'${date.year.toString().substring(2)}";
    }
  } else {
    throw InvalidDataException("Time Unit not supported");
  }
}

T? nullIfIndexOutOfRange<T>(List<T> list, int index) {
  if (index < 0 || index >= list.length) {
    return null;
  } else {
    return list[index];
  }
}

Future<File> preprocessCsvFile({required File csvFile}) async {
  final uuid = Uuid();

  // Parse CSV
  String fileData = await csvFile.readAsString();
  List<List<dynamic>> rows = const CsvToListConverter().convert(fileData);

  if (rows.isEmpty) {
    throw Exception('CSV file is empty');
  }

  // Skip header row
  final dataRows = rows.skip(1).toList();

  // CSV column indices
  const int colAccount = 0;
  const int colAmount = 1;
  const int colCurrency = 2;
  const int colTitle = 3;
  const int colNote = 4;
  const int colDate = 5;
  const int colIncome = 6;
  // const int colType = 7; // ignored
  const int colCategoryName = 8;
  const int colSubcategoryName = 9;
  const int colColor = 10;
  const int colIcon = 11;
  const int colEmoji = 12;
  // const int colBudget = 13; // ignored
  // const int colObjective = 14; // ignored

  // Build maps of unique entities
  Map<String, String> walletPks = {}; // wallet name -> pk
  Map<String, String> categoryPks = {}; // category name -> pk
  Map<String, String> subcategoryPks = {}; // "parentName|subName" -> pk
  Map<String, Map<String, dynamic>> categoryData = {}; // category name -> {color, icon, emoji, income}
  Map<String, Map<String, dynamic>> subcategoryData = {}; // "parentName|subName" -> {color, icon, emoji, income, parentPk}

  // First pass: collect unique entities
  for (var row in dataRows) {
    final account = row[colAccount]?.toString() ?? 'Bank';
    final categoryName = row[colCategoryName]?.toString() ?? '';
    final subcategoryName = row[colSubcategoryName]?.toString() ?? '';
    final color = row[colColor]?.toString() ?? '';
    final icon = row[colIcon]?.toString() ?? '';
    final emoji = row[colEmoji]?.toString() ?? '';
    final income = row[colIncome]?.toString().toLowerCase() == 'true';
    final currency = row[colCurrency]?.toString() ?? 'INR';

    // Wallet
    if (!walletPks.containsKey(account)) {
      walletPks[account] = uuid.v4();
    }

    // Main category
    if (categoryName.isNotEmpty && !categoryPks.containsKey(categoryName)) {
      categoryPks[categoryName] = uuid.v4();
      categoryData[categoryName] = {
        'color': color,
        'icon': icon,
        'emoji': emoji.isEmpty ? null : emoji,
        'income': income,
        'currency': currency,
      };
    }

    // Subcategory
    if (subcategoryName.isNotEmpty && categoryName.isNotEmpty) {
      final subKey = '$categoryName|$subcategoryName';
      if (!subcategoryPks.containsKey(subKey)) {
        subcategoryPks[subKey] = uuid.v4();
        subcategoryData[subKey] = {
          'color': color,
          'icon': icon,
          'emoji': emoji.isEmpty ? null : emoji,
          'income': income,
          'parentPk': categoryPks[categoryName],
        };
      }
    }
  }

  // Create temp database file
  final tempDir = await getTemporaryDirectory();
  final dbPath = p.join(tempDir.path, 'import_${DateTime.now().millisecondsSinceEpoch}.db');

  // Create and open database
  final db = sqlite3.sqlite3.open(dbPath);

  try {
    // Set schema version to match drift's expected version (46)
    // This is critical - drift uses this to determine if migrations are needed
    db.execute('PRAGMA user_version = 46;');

    // Create tables (matching drift schema)
    db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        wallet_pk TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colour TEXT,
        icon_name TEXT,
        date_created INTEGER NOT NULL,
        date_time_modified INTEGER,
        "order" INTEGER NOT NULL,
        currency TEXT,
        currency_format TEXT,
        decimals INTEGER DEFAULT 2,
        home_page_widget_display TEXT
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        category_pk TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colour TEXT,
        icon_name TEXT,
        emoji_icon_name TEXT,
        date_created INTEGER NOT NULL,
        date_time_modified INTEGER,
        "order" INTEGER NOT NULL,
        income INTEGER DEFAULT 0,
        method_added INTEGER,
        main_category_pk TEXT REFERENCES categories(category_pk)
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        transaction_pk TEXT PRIMARY KEY,
        paired_transaction_fk TEXT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT NOT NULL,
        category_fk TEXT NOT NULL REFERENCES categories(category_pk),
        sub_category_fk TEXT REFERENCES categories(category_pk),
        wallet_fk TEXT NOT NULL REFERENCES wallets(wallet_pk),
        date_created INTEGER NOT NULL,
        date_time_modified INTEGER,
        original_date_due INTEGER,
        income INTEGER DEFAULT 0,
        period_length INTEGER,
        reoccurrence INTEGER,
        end_date INTEGER,
        upcoming_transaction_notification INTEGER DEFAULT 1,
        type INTEGER,
        paid INTEGER DEFAULT 0,
        created_another_future_transaction INTEGER DEFAULT 0,
        skip_paid INTEGER DEFAULT 0,
        method_added INTEGER,
        transaction_owner_email TEXT,
        transaction_original_owner_email TEXT,
        shared_key TEXT,
        shared_old_key TEXT,
        shared_status INTEGER,
        shared_date_updated INTEGER,
        shared_reference_budget_pk TEXT,
        objective_fk TEXT,
        objective_loan_fk TEXT,
        budget_fks_exclude TEXT
      )
    ''');

    // Create other required tables (empty)
    db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        budget_pk TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        colour TEXT,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        wallet_fks TEXT,
        category_fks TEXT,
        category_fks_exclude TEXT,
        income INTEGER DEFAULT 0,
        archived INTEGER DEFAULT 0,
        added_transactions_only INTEGER DEFAULT 0,
        period_length INTEGER NOT NULL,
        reoccurrence INTEGER,
        date_created INTEGER NOT NULL,
        date_time_modified INTEGER,
        pinned INTEGER DEFAULT 0,
        "order" INTEGER NOT NULL,
        wallet_fk TEXT,
        budget_transaction_filters TEXT,
        member_transaction_filters TEXT,
        shared_key TEXT,
        shared_owner_member INTEGER,
        shared_date_updated INTEGER,
        shared_members TEXT,
        shared_all_members_ever TEXT,
        is_absolute_spending_limit INTEGER DEFAULT 0
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS objectives (
        objective_pk TEXT PRIMARY KEY,
        type INTEGER DEFAULT 0,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        "order" INTEGER NOT NULL,
        colour TEXT,
        date_created INTEGER NOT NULL,
        end_date INTEGER,
        date_time_modified INTEGER,
        icon_name TEXT,
        emoji_icon_name TEXT,
        income INTEGER DEFAULT 0,
        pinned INTEGER DEFAULT 1,
        archived INTEGER DEFAULT 0,
        wallet_fk TEXT
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS associated_titles (
        associated_title_pk TEXT PRIMARY KEY,
        category_fk TEXT NOT NULL REFERENCES categories(category_pk),
        title TEXT NOT NULL,
        date_created INTEGER NOT NULL,
        date_time_modified INTEGER,
        "order" INTEGER NOT NULL,
        is_exact_match INTEGER DEFAULT 0
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS category_budget_limits (
        category_limit_pk TEXT PRIMARY KEY,
        category_fk TEXT NOT NULL,
        budget_fk TEXT NOT NULL,
        amount REAL NOT NULL,
        date_time_modified INTEGER,
        wallet_fk TEXT
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS delete_logs (
        delete_log_pk TEXT PRIMARY KEY,
        entry_pk TEXT NOT NULL,
        type INTEGER NOT NULL,
        date_time_modified INTEGER NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS scanner_templates (
        scanner_template_pk TEXT PRIMARY KEY,
        date_created INTEGER NOT NULL,
        date_time_modified INTEGER,
        template_name TEXT NOT NULL,
        contains TEXT NOT NULL,
        title_transaction_before TEXT NOT NULL,
        title_transaction_after TEXT NOT NULL,
        amount_transaction_before TEXT NOT NULL,
        amount_transaction_after TEXT NOT NULL,
        default_category_fk TEXT NOT NULL,
        wallet_fk TEXT,
        ignore INTEGER DEFAULT 0
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        settings_pk INTEGER PRIMARY KEY AUTOINCREMENT,
        settings_j_s_o_n TEXT NOT NULL,
        date_updated INTEGER NOT NULL
      )
    ''');

    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert wallets
    int walletOrder = 0;
    final walletStmt = db.prepare('''
      INSERT INTO wallets (wallet_pk, name, date_created, "order", currency, decimals)
      VALUES (?, ?, ?, ?, ?, 2)
    ''');

    // Get currency for each wallet from first transaction
    Map<String, String> walletCurrencies = {};
    for (var row in dataRows) {
      final account = row[colAccount]?.toString() ?? 'Bank';
      if (!walletCurrencies.containsKey(account)) {
        walletCurrencies[account] = row[colCurrency]?.toString() ?? 'INR';
      }
    }

    for (var entry in walletPks.entries) {
      walletStmt.execute([entry.value, entry.key, now, walletOrder++, walletCurrencies[entry.key] ?? 'INR']);
    }
    walletStmt.dispose();

    // Insert main categories
    int categoryOrder = 0;
    final categoryStmt = db.prepare('''
      INSERT INTO categories (category_pk, name, colour, icon_name, emoji_icon_name, date_created, "order", income, main_category_pk)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL)
    ''');

    for (var entry in categoryPks.entries) {
      final data = categoryData[entry.key]!;
      categoryStmt.execute([
        entry.value,
        entry.key,
        data['color']?.toString().isNotEmpty == true ? data['color'] : null,
        data['icon']?.toString().isNotEmpty == true ? data['icon'] : null,
        data['emoji'],
        now,
        categoryOrder++,
        data['income'] == true ? 1 : 0,
      ]);
    }
    categoryStmt.dispose();

    // Insert subcategories
    final subcategoryStmt = db.prepare('''
      INSERT INTO categories (category_pk, name, colour, icon_name, emoji_icon_name, date_created, "order", income, main_category_pk)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    for (var entry in subcategoryPks.entries) {
      final data = subcategoryData[entry.key]!;
      final subName = entry.key.split('|')[1];
      subcategoryStmt.execute([
        entry.value,
        subName,
        data['color']?.toString().isNotEmpty == true ? data['color'] : null,
        data['icon']?.toString().isNotEmpty == true ? data['icon'] : null,
        data['emoji'],
        now,
        categoryOrder++,
        data['income'] == true ? 1 : 0,
        data['parentPk'],
      ]);
    }
    subcategoryStmt.dispose();

    // Insert transactions
    final transactionStmt = db.prepare('''
      INSERT INTO transactions (
        transaction_pk, name, amount, note, category_fk, sub_category_fk, wallet_fk,
        date_created, date_time_modified, income, paid
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    ''');

    for (var row in dataRows) {
      final account = row[colAccount]?.toString() ?? 'Bank';
      final amount = double.tryParse(row[colAmount]?.toString() ?? '0') ?? 0;
      final title = row[colTitle]?.toString() ?? '';
      final note = row[colNote]?.toString() ?? '';
      final dateStr = row[colDate]?.toString() ?? '';
      final income = row[colIncome]?.toString().toLowerCase() == 'true';
      final categoryName = row[colCategoryName]?.toString() ?? '';
      final subcategoryName = row[colSubcategoryName]?.toString() ?? '';

      // Parse date - drift stores DateTime as SECONDS since epoch, not milliseconds!
      int dateSeconds = now ~/ 1000;
      if (dateStr.isNotEmpty) {
        try {
          dateSeconds = DateTime.parse(dateStr).millisecondsSinceEpoch ~/ 1000;
        } catch (_) {
          dateSeconds = now ~/ 1000;
        }
      }

      final walletPk = walletPks[account] ?? walletPks.values.first;
      final categoryPk = categoryPks[categoryName];

      if (categoryPk == null) continue; // Skip if no category

      String? subCategoryPk;
      if (subcategoryName.isNotEmpty) {
        subCategoryPk = subcategoryPks['$categoryName|$subcategoryName'];
      }

      transactionStmt.execute([
        uuid.v4(),
        title,
        amount,
        note,
        categoryPk,
        subCategoryPk,
        walletPk,
        dateSeconds,
        dateSeconds,
        income ? 1 : 0,
      ]);
    }
    transactionStmt.dispose();

  } finally {
    db.dispose();
  }

  return File(dbPath);
}
