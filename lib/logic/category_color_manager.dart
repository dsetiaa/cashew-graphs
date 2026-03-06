import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/presentation/resources/app_colours.dart';

class CategoryColorManager {
  static const _storageKey = 'category_color_overrides';
  static Map<String, Color> _overrides = {};

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      _overrides = map.map(
        (key, value) => MapEntry(key, Color(int.parse(value as String, radix: 16))),
      );
    }
  }

  static Color getColorForCategory(TransactionCategory category) {
    final override = _overrides[category.categoryPk];
    if (override != null) return override;
    if (category.colour != null) {
      return Color(int.parse(category.colour!.substring(4), radix: 16) + 0xFF000000);
    }
    return AppColors.primary;
  }

  static Future<void> setColor(String categoryPk, Color color) async {
    _overrides[categoryPk] = color;
    await _persist();
  }

  static Future<void> resetColor(String categoryPk) async {
    _overrides.remove(categoryPk);
    await _persist();
  }

  static bool hasOverride(String categoryPk) => _overrides.containsKey(categoryPk);

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _overrides.map(
      (key, color) => MapEntry(key, color.toARGB32().toRadixString(16).padLeft(8, '0')),
    );
    await prefs.setString(_storageKey, jsonEncode(map));
  }
}
