import 'package:flutter/services.dart';
import 'dart:convert';

Map<String, dynamic> appStateSettings = {};

Map<String, dynamic> currenciesJSON = {};

loadCurrencyJSON() async {
  currenciesJSON = await json.decode(
      await rootBundle.loadString('assets/static/generated/currencies.json'));
}
