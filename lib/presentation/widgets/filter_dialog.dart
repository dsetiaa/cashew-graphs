import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/logic/helpers.dart';
import 'package:cashew_graphs/graphs/line_graphs/line_graph_helpers.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';

class FilterSettings {
  final DateTime startDate;
  final DateTime endDate;
  /// null = all categories selected, empty = none selected, non-empty = specific categories
  final Set<String>? selectedCategoryPks;
  final TimeUnit timeUnit;
  final LineGraphType lineGraphType;
  final bool showSubcategories;
  final bool showTotal;
  final String transactionNameFilter;

  const FilterSettings({
    required this.startDate,
    required this.endDate,
    this.selectedCategoryPks,
    this.timeUnit = TimeUnit.day,
    this.lineGraphType = LineGraphType.perTimeUnit,
    this.showSubcategories = false,
    this.showTotal = false,
    this.transactionNameFilter = '',
  });

  FilterSettings copyWith({
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? Function()? selectedCategoryPks,
    TimeUnit? timeUnit,
    LineGraphType? lineGraphType,
    bool? showSubcategories,
    bool? showTotal,
    String? transactionNameFilter,
  }) {
    return FilterSettings(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedCategoryPks: selectedCategoryPks != null ? selectedCategoryPks() : this.selectedCategoryPks,
      timeUnit: timeUnit ?? this.timeUnit,
      lineGraphType: lineGraphType ?? this.lineGraphType,
      showSubcategories: showSubcategories ?? this.showSubcategories,
      showTotal: showTotal ?? this.showTotal,
      transactionNameFilter: transactionNameFilter ?? this.transactionNameFilter,
    );
  }

  Map<String, dynamic> toJson() => {
    'selectedCategoryPks': selectedCategoryPks?.toList(),
    'timeUnit': timeUnit.name,
    'lineGraphType': lineGraphType.name,
    'showSubcategories': showSubcategories,
    'showTotal': showTotal,
    'transactionNameFilter': transactionNameFilter,
  };

  factory FilterSettings.fromJson(Map<String, dynamic> json, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return FilterSettings(
      startDate: startDate,
      endDate: endDate,
      selectedCategoryPks: json['selectedCategoryPks'] != null
          ? Set<String>.from(json['selectedCategoryPks'] as List)
          : null,
      timeUnit: TimeUnit.values.firstWhere(
        (e) => e.name == json['timeUnit'],
        orElse: () => TimeUnit.day,
      ),
      lineGraphType: LineGraphType.values.firstWhere(
        (e) => e.name == json['lineGraphType'],
        orElse: () => LineGraphType.perTimeUnit,
      ),
      showSubcategories: json['showSubcategories'] as bool? ?? false,
      showTotal: json['showTotal'] as bool? ?? false,
      transactionNameFilter: json['transactionNameFilter'] as String? ?? '',
    );
  }
}

class FilterPreset {
  final String id;
  final String name;
  final FilterSettings settings;

  const FilterPreset({
    required this.id,
    required this.name,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'settings': settings.toJson(),
  };

  factory FilterPreset.fromJson(Map<String, dynamic> json, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return FilterPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      settings: FilterSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }
}

class FilterPresetManager {
  static const _storageKey = 'filter_presets';

  static Future<List<FilterPreset>> getPresets({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => FilterPreset.fromJson(
          json as Map<String, dynamic>,
          startDate: startDate,
          endDate: endDate,
        ))
        .toList();
  }

  static Future<void> savePreset(FilterPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    final List<dynamic> jsonList = jsonString != null ? jsonDecode(jsonString) : [];

    // Check if preset with same name exists and replace it
    final existingIndex = jsonList.indexWhere(
      (json) => (json['name'] as String).toLowerCase() == preset.name.toLowerCase(),
    );

    if (existingIndex >= 0) {
      jsonList[existingIndex] = preset.toJson();
    } else {
      jsonList.add(preset.toJson());
    }

    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<void> deletePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;

    final List<dynamic> jsonList = jsonDecode(jsonString);
    jsonList.removeWhere((json) => json['id'] == id);
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}

class FilterDialog extends StatefulWidget {
  final FilterSettings initialSettings;
  final List<TransactionCategory> categories;

  const FilterDialog({
    required this.initialSettings,
    required this.categories,
    super.key,
  });

  static Future<FilterSettings?> show({
    required BuildContext context,
    required FilterSettings initialSettings,
    required List<TransactionCategory> categories,
  }) {
    return showModalBottomSheet<FilterSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterDialog(
        initialSettings: initialSettings,
        categories: categories,
      ),
    );
  }

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  Set<String>? _selectedCategoryPks;
  late TimeUnit _timeUnit;
  late LineGraphType _lineGraphType;
  late bool _showSubcategories;
  late bool _showTotal;
  late TextEditingController _transactionNameController;
  bool _showCategoryError = false;
  List<FilterPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialSettings.startDate;
    _endDate = widget.initialSettings.endDate;
    _selectedCategoryPks = widget.initialSettings.selectedCategoryPks != null
        ? Set.from(widget.initialSettings.selectedCategoryPks!)
        : null;
    _timeUnit = widget.initialSettings.timeUnit;
    _lineGraphType = widget.initialSettings.lineGraphType;
    _showSubcategories = widget.initialSettings.showSubcategories;
    _showTotal = widget.initialSettings.showTotal;
    _transactionNameController = TextEditingController(
      text: widget.initialSettings.transactionNameFilter,
    );
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final presets = await FilterPresetManager.getPresets(
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() {
      _presets = presets;
    });
  }

  void _loadPreset(FilterPreset preset) {
    setState(() {
      // Don't change dates - only load filter options
      _selectedCategoryPks = preset.settings.selectedCategoryPks != null
          ? Set.from(preset.settings.selectedCategoryPks!)
          : null;
      _timeUnit = preset.settings.timeUnit;
      _lineGraphType = preset.settings.lineGraphType;
      _showSubcategories = preset.settings.showSubcategories;
      _showTotal = preset.settings.showTotal;
      _transactionNameController.text = preset.settings.transactionNameFilter;
      _showCategoryError = false;
    });
  }

  Future<void> _saveCurrentAsPreset() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.itemsBackground,
        title: Text('Save Preset', style: AppTypography.titleMedium),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.mainTextColor1,
          ),
          decoration: InputDecoration(
            hintText: 'Preset name',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.mainTextColor3,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.chartBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.mainTextColor3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final preset = FilterPreset(
        id: const Uuid().v4(),
        name: name.trim(),
        settings: FilterSettings(
          startDate: _startDate,
          endDate: _endDate,
          selectedCategoryPks: _selectedCategoryPks,
          timeUnit: _timeUnit,
          lineGraphType: _lineGraphType,
          showSubcategories: _showSubcategories,
          showTotal: _showTotal,
          transactionNameFilter: _transactionNameController.text,
        ),
      );
      await FilterPresetManager.savePreset(preset);
      await _loadPresets();
    }
  }

  Future<void> _deletePreset(FilterPreset preset) async {
    await FilterPresetManager.deletePreset(preset.id);
    await _loadPresets();
  }

  @override
  void dispose() {
    _transactionNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate = now;

    // Clamp initialDate to be within valid range
    var initialDate = isStart ? _startDate : _endDate;
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    } else if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.contentColorBlack,
              surface: AppColors.itemsBackground,
              onSurface: AppColors.mainTextColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  void _applyFilters() {
    Navigator.of(context).pop(FilterSettings(
      startDate: _startDate,
      endDate: _endDate,
      selectedCategoryPks: _selectedCategoryPks,
      timeUnit: _timeUnit,
      lineGraphType: _lineGraphType,
      showSubcategories: _showSubcategories,
      showTotal: _showTotal,
      transactionNameFilter: _transactionNameController.text,
    ));
  }

  void _resetFilters() {
    final defaultDateRange = getDefaultDateRange();
    setState(() {
      _startDate = defaultDateRange.start;
      _endDate = defaultDateRange.end;
      _selectedCategoryPks = null; // null = all selected
      _timeUnit = TimeUnit.day;
      _lineGraphType = LineGraphType.perTimeUnit;
      _showSubcategories = false;
      _showTotal = false;
      _transactionNameController.clear();
    });
  }

  bool _hasValidSelection() {
    // null means all selected, which is valid
    if (_selectedCategoryPks == null) return true;
    // non-empty set means some categories selected, which is valid
    return _selectedCategoryPks!.isNotEmpty;
  }

  void _onApplyPressed() {
    if (_hasValidSelection()) {
      _applyFilters();
    } else {
      setState(() {
        _showCategoryError = true;
      });
    }
  }

  Color _getCategoryColor(TransactionCategory category) {
    if (category.colour != null) {
      return Color(int.parse(category.colour!.substring(4), radix: 16) + 0xFF000000);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final mainCategories = widget.categories
        .where((c) => c.mainCategoryPk == null)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.itemsBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mainTextColor3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        'Reset',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.mainTextColor3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('Filters', style: AppTypography.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: _saveCurrentAsPreset,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      color: AppColors.mainTextColor2,
                      tooltip: 'Save as preset',
                      visualDensity: VisualDensity.compact,
                    ),
                    TextButton(
                      onPressed: _onApplyPressed,
                      child: Text(
                        'Apply',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.chartBorder, height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Presets Section
                    if (_presets.isNotEmpty) ...[
                      _buildSectionHeader('Presets'),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _presets.map((preset) {
                          return GestureDetector(
                            onLongPress: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.itemsBackground,
                                  title: Text('Delete Preset', style: AppTypography.titleMedium),
                                  content: Text(
                                    'Delete "${preset.name}"?',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.mainTextColor2,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancel', style: TextStyle(color: AppColors.mainTextColor3)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _deletePreset(preset);
                              }
                            },
                            child: ActionChip(
                              label: Text(preset.name),
                              labelStyle: AppTypography.labelMedium.copyWith(
                                color: AppColors.mainTextColor1,
                              ),
                              avatar: const Icon(
                                Icons.bookmark,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              backgroundColor: AppColors.pageBackground,
                              side: const BorderSide(color: AppColors.chartBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              onPressed: () => _loadPreset(preset),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Long-press to delete',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mainTextColor3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Date Range Section
                    _buildSectionHeader('Date Range'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            label: 'From',
                            date: _startDate,
                            onTap: () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildDateButton(
                            label: 'To',
                            date: _endDate,
                            onTap: () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Time Unit Toggle
                    _buildSectionHeader('Time Unit'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSegmentedControl<TimeUnit>(
                      value: _timeUnit,
                      options: const {
                        TimeUnit.day: 'Daily',
                        TimeUnit.month: 'Monthly',
                      },
                      onChanged: (value) => setState(() => _timeUnit = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Graph Type Toggle
                    _buildSectionHeader('Graph Type'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSegmentedControl<LineGraphType>(
                      value: _lineGraphType,
                      options: const {
                        LineGraphType.perTimeUnit: 'Per Period',
                        LineGraphType.aggregate: 'Cumulative',
                      },
                      onChanged: (value) => setState(() => _lineGraphType = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Options Section
                    _buildSectionHeader('Options'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildToggleRow(
                      label: 'Show Subcategories',
                      value: _showSubcategories,
                      onChanged: (value) => setState(() => _showSubcategories = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildToggleRow(
                      label: 'Show Total',
                      value: _showTotal,
                      onChanged: (value) => setState(() => _showTotal = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Transaction Name Filter
                    _buildSectionHeader('Transaction Name'),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _transactionNameController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mainTextColor1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mainTextColor3,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.mainTextColor3,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.pageBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(
                            color: AppColors.chartBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Categories Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Categories'),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  // Empty set = none selected
                                  _selectedCategoryPks = {};
                                });
                              },
                              child: Text(
                                'Deselect All',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.mainTextColor3,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  // null = all selected
                                  _selectedCategoryPks = null;
                                  _showCategoryError = false;
                                });
                              },
                              child: Text(
                                'Select All',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_showCategoryError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          'Please select at least one category',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      )
                    else if (_selectedCategoryPks == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          'All categories selected',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.mainTextColor3,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: mainCategories.map((category) {
                        final isSelected = _selectedCategoryPks == null ||
                            _selectedCategoryPks!.contains(category.categoryPk);
                        final color = _getCategoryColor(category);

                        return FilterChip(
                          selected: isSelected,
                          label: Text(category.name),
                          labelStyle: AppTypography.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.contentColorBlack
                                : AppColors.mainTextColor2,
                          ),
                          avatar: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          backgroundColor: AppColors.pageBackground,
                          selectedColor: color,
                          checkmarkColor: AppColors.contentColorBlack,
                          side: BorderSide(
                            color: isSelected ? color : AppColors.chartBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _showCategoryError = false;
                              if (_selectedCategoryPks == null) {
                                // Deselecting from "all": add all except this one
                                _selectedCategoryPks = mainCategories
                                    .where((c) => c.categoryPk != category.categoryPk)
                                    .map((c) => c.categoryPk)
                                    .toSet();
                              } else if (selected) {
                                _selectedCategoryPks!.add(category.categoryPk);
                                // If all selected, set to null to represent "all"
                                if (_selectedCategoryPks!.length == mainCategories.length) {
                                  _selectedCategoryPks = null;
                                }
                              } else {
                                _selectedCategoryPks!.remove(category.categoryPk);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.mainTextColor1,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.chartBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mainTextColor1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl<T>({
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.chartBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = value == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.contentColorBlack
                        : AppColors.mainTextColor2,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.chartBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mainTextColor1,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.mainTextColor3,
            inactiveTrackColor: AppColors.chartBorder,
          ),
        ],
      ),
    );
  }
}