import 'package:cashew_graphs/logic/helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' hide Column;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// Import your database class
import 'package:cashew_graphs/database/tables.dart';

class DatabaseProvider extends StatefulWidget {
  final Widget child;
  const DatabaseProvider({super.key, required this.child});

  static DatabaseProviderState of(BuildContext context) {
    return context.findAncestorStateOfType<DatabaseProviderState>()!;
  }

  @override
  State<DatabaseProvider> createState() => DatabaseProviderState();
}

class DatabaseProviderState extends State<DatabaseProvider> {
  late FinanceDatabase _database;

  @override
  void initState() {
    super.initState();
    _database = FinanceDatabase();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> importDatabase({VoidCallback? onLoadingStart, VoidCallback? onLoadingEnd}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        onLoadingStart?.call();

        // Wait for the UI to render the loading indicator before starting heavy work
        await Future.delayed(const Duration(milliseconds: 50));

        final file = File(result.files.single.path!);

        // --- VALIDATION START ---
        // Get extension (e.g., ".db") and convert to lowercase
        final extension = p.extension(file.path).toLowerCase();
        const allowedExtensions = ['.db', '.sqlite', '.sqlite3', '.sql', '.csv'];

        if (!allowedExtensions.contains(extension)) {
          // Validation Failed: Show error and exit
          onLoadingEnd?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid file type ($extension). Please select a .db, .sqlite, .sqlite3, .sql, or .csv file.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final File dbFile;
        if(extension == ".csv"){
          dbFile = await preprocessCsvFile(csvFile: file);
        } else {
          dbFile = file;
        }
        // --- VALIDATION END ---

        final dbFolder = await getApplicationDocumentsDirectory();

        // Ensure this filename matches what you set in your FinanceDatabase class
        final targetPath = p.join(dbFolder.path, 'finance_app.db');

        // 1. Close old
        await _database.close();

        // 2. Overwrite file
        await dbFile.copy(targetPath);

        // 3. Create new instance & Rebuild
        setState(() {
          _database = FinanceDatabase();
        });
        onLoadingEnd?.call();

        print("Database Reloaded");
      }
    } catch (e) {
      onLoadingEnd?.call();
      print("Error importing: $e");
    }
  }

  Future<void> _debugPrintDatabaseContents() async {
    try {
      final transactions = await _database.getAllTransactionsInChronologicalOrder();
      final categories = await _database.getAllCategories();
      final wallets = await _database.getAllWallets();

      print("=== DATABASE DEBUG INFO ===");
      print("Total wallets: ${wallets.length}");
      for (var w in wallets) {
        print("  Wallet: ${w.name} (PK: ${w.walletPk})");
      }

      print("Total categories: ${categories.length}");
      for (var c in categories) {
        print("  Category: ${c.name} (PK: ${c.categoryPk}, mainCategoryPk: ${c.mainCategoryPk})");
      }

      print("Total transactions: ${transactions.length}");
      if (transactions.isNotEmpty) {
        print("First transaction:");
        final t = transactions.first;
        print("  Name: ${t.name}");
        print("  Amount: ${t.amount}");
        print("  DateCreated: ${t.dateCreated}");
        print("  CategoryFK: ${t.categoryFk}");
        print("  WalletFK: ${t.walletFk}");

        print("Last transaction:");
        final last = transactions.last;
        print("  Name: ${last.name}");
        print("  Amount: ${last.amount}");
        print("  DateCreated: ${last.dateCreated}");

        // Check date range
        final earliest = transactions.map((t) => t.dateCreated).reduce((a, b) => a.isBefore(b) ? a : b);
        final latest = transactions.map((t) => t.dateCreated).reduce((a, b) => a.isAfter(b) ? a : b);
        print("Date range: $earliest to $latest");
      }
      print("=== END DEBUG INFO ===");

      // Test the join query (same as used by graphs)
      if (transactions.isNotEmpty) {
        print("=== TESTING JOIN QUERY ===");
        final earliest = transactions.map((t) => t.dateCreated).reduce((a, b) => a.isBefore(b) ? a : b);
        final latest = transactions.map((t) => t.dateCreated).reduce((a, b) => a.isAfter(b) ? a : b);

        final joinedResults = await _database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
          (t) => t.dateCreated.isBiggerOrEqualValue(earliest) & t.dateCreated.isSmallerOrEqualValue(latest)
        );
        print("Join query returned ${joinedResults.length} transactions");
        if (joinedResults.isEmpty && transactions.isNotEmpty) {
          print("WARNING: Join query returned 0 results but raw query returned ${transactions.length}!");
          print("This suggests foreign key mismatch. Checking first transaction...");
          final first = transactions.first;
          final matchingCategory = categories.where((c) => c.categoryPk == first.categoryFk);
          final matchingWallet = wallets.where((w) => w.walletPk == first.walletFk);
          print("  Category FK '${first.categoryFk}' matches: ${matchingCategory.length} categories");
          print("  Wallet FK '${first.walletFk}' matches: ${matchingWallet.length} wallets");
        }
        print("=== END JOIN TEST ===");
      }
    } catch (e) {
      print("Debug error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider<FinanceDatabase>.value(
      value: _database,
      child: widget.child,
    );
  }
}