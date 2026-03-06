import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/logic/category_color_manager.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<TransactionCategory> _mainCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = Provider.of<FinanceDatabase>(context, listen: false);
    final all = await db.getAllCategories();
    setState(() {
      _mainCategories = all.where((c) => c.mainCategoryPk == null).toList();
      _loading = false;
    });
  }

  Future<void> _showColorPicker(TransactionCategory category) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        currentColor: CategoryColorManager.getColorForCategory(category),
      ),
    );
    if (picked != null) {
      await CategoryColorManager.setColor(category.categoryPk, picked);
      setState(() {});
    }
  }

  Future<void> _resetColor(TransactionCategory category) async {
    await CategoryColorManager.resetColor(category.categoryPk);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.titleMedium),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Category Colors',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.mainTextColor1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...List.generate(_mainCategories.length, (index) {
                  final category = _mainCategories[index];
                  final color = CategoryColorManager.getColorForCategory(category);
                  final hasOverride = CategoryColorManager.hasOverride(category.categoryPk);

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.itemsBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.chartBorder),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () => _showColorPicker(category),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.mainTextColor3,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: AppTypography.bodyLarge,
                      ),
                      trailing: hasOverride
                          ? IconButton(
                              icon: const Icon(Icons.restore, color: AppColors.mainTextColor3),
                              tooltip: 'Reset to default',
                              onPressed: () => _resetColor(category),
                            )
                          : null,
                      onTap: () => _showColorPicker(category),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

const List<Color> _materialPalette = [
  Color(0xFFF44336), // Red
  Color(0xFFE91E63), // Pink
  Color(0xFF9C27B0), // Purple
  Color(0xFF673AB7), // Deep Purple
  Color(0xFF3F51B5), // Indigo
  Color(0xFF2196F3), // Blue
  Color(0xFF03A9F4), // Light Blue
  Color(0xFF00BCD4), // Cyan
  Color(0xFF009688), // Teal
  Color(0xFF4CAF50), // Green
  Color(0xFF8BC34A), // Light Green
  Color(0xFFCDDC39), // Lime
  Color(0xFFFFEB3B), // Yellow
  Color(0xFFFFC107), // Amber
  Color(0xFFFF9800), // Orange
  Color(0xFFFF5722), // Deep Orange
  Color(0xFF795548), // Brown
  Color(0xFF607D8B), // Blue Grey
];

class _ColorPickerDialog extends StatelessWidget {
  final Color currentColor;

  const _ColorPickerDialog({required this.currentColor});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.itemsBackground,
      title: Text('Pick a Color', style: AppTypography.titleMedium),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
          ),
          itemCount: _materialPalette.length,
          itemBuilder: (context, index) {
            final color = _materialPalette[index];
            final isSelected = color.toARGB32() == currentColor.toARGB32();
            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.contentColorWhite, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.mainTextColor3)),
        ),
      ],
    );
  }
}
