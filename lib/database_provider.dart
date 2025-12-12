import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<void> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // --- VALIDATION START ---
        // Get extension (e.g., ".db") and convert to lowercase
        final extension = p.extension(file.path).toLowerCase();
        const allowedExtensions = ['.db', '.sqlite', '.sqlite3', '.sql'];

        if (!allowedExtensions.contains(extension)) {
          // Validation Failed: Show error and exit
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid file type ($extension). Please select a .db, .sqlite, .sqlite3, or .sql file.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        // --- VALIDATION END ---

        final dbFolder = await getApplicationDocumentsDirectory();

        // Ensure this filename matches what you set in your FinanceDatabase class
        final targetPath = p.join(dbFolder.path, 'finance_app.db');

        // 1. Close old
        await _database.close();

        // 2. Overwrite file
        await file.copy(targetPath);

        // 3. Create new instance & Rebuild
        setState(() {
          _database = FinanceDatabase();
        });

        print("Database Reloaded");
      }
    } catch (e) {
      print("Error importing: $e");
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