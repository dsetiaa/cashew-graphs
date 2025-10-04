// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:universal_io/io.dart';
//
// // import 'globals_i_think.dart';
//
// extension DateUtils on DateTime {
//   DateTime copyWith({
//     int? year,
//     int? month,
//     int? day,
//     int? hour,
//     int? minute,
//     int? second,
//     int? millisecond,
//     int? microsecond,
//   }) {
//     return DateTime(
//       year ?? this.year,
//       month ?? this.month,
//       day ?? this.day,
//       hour ?? this.hour,
//       minute ?? this.minute,
//       second ?? this.second,
//       millisecond ?? this.millisecond,
//       microsecond ?? this.microsecond,
//     );
//   }
//
//   DateTime justDay(
//       {int yearOffset = 0, int monthOffset = 0, int dayOffset = 0}) {
//     return DateTime(
//         this.year + yearOffset, this.month + monthOffset, this.day + dayOffset);
//   }
//
//   DateTime firstDayOfMonth() {
//     return DateTime(this.year, this.month, 1);
//   }
// }
//
// checkYesterdayTodayTomorrow(DateTime date) {
//   DateTime now = DateTime.now();
//   if (date.justDay() == now.justDay()) {
//     return "today".tr();
//   } else if (date.justDay() == now.justDay(dayOffset: 1)) {
//     return "tomorrow".tr();
//   } else if (date.justDay() == now.justDay(dayOffset: -1)) {
//     return "yesterday".tr();
//   }
//
//   return false;
// }
//
//
// String getWordedDateShort(
//     DateTime date, {
//       includeYear = false,
//       showTodayTomorrow = true,
//       lowerCaseTodayTomorrow = false,
//     }) {
//   if (showTodayTomorrow && checkYesterdayTodayTomorrow(date) != false) {
//     String todayTomorrowOut = checkYesterdayTodayTomorrow(date);
//     return lowerCaseTodayTomorrow
//         ? todayTomorrowOut.toLowerCase()
//         : todayTomorrowOut;
//   }
//
//   // final String? locale = navigatorKey.currentContext?.locale.toString();
//
//   if (includeYear) {
//     return DateFormat.yMMMd(locale).format(date);
//   } else {
//     return DateFormat.MMMd(locale).format(date);
//   }
// }
//
//
// bool getIsFullScreen(context) {
//   return getWidthNavigationSidebar(context) > 0;
//   double maxWidth = 700;
//   return MediaQuery.sizeOf(context).width > maxWidth;
// }
//
// // returns 0 if no navigation sidebar should be shown
// double getWidthNavigationSidebar(BuildContext context) {
//   double screenPercent = 0.3;
//   double maxWidthNavigation = 270;
//   double minScreenWidth = 700;
//
//   if (MediaQuery.sizeOf(context).width < minScreenWidth) return 0;
//   if (appStateSettings["expandedNavigationSidebar"] == false) {
//     return 70 + MediaQuery.viewPaddingOf(context).left;
//   }
//   return (MediaQuery.sizeOf(context).width * screenPercent > maxWidthNavigation
//       ? maxWidthNavigation
//       : MediaQuery.sizeOf(context).width * screenPercent) +
//       MediaQuery.viewPaddingOf(context).left;
// }
//
//
// String convertToMoney(AllWallets allWallets, double amount,
//     {String? currencyKey,
//       double? finalNumber,
//       int? decimals,
//       bool? allDecimals,
//       bool? addCurrencyName,
//       bool forceHideCurrencyName = false,
//       bool forceAllDecimals = false,
//       bool forceNonCustomNumberFormat = false,
//       bool forceCustomNumberFormat = false,
//       String? customSymbol,
//       String Function(String)? editFormattedOutput,
//       bool forceCompactNumberFormatter = false,
//       bool forceDefaultNumberFormatter = false,
//       bool forceAbsoluteZero = true,
//       NumberFormat Function(int? decimalDigits, String? locale, String? symbol)?
//       getCustomNumberFormat})
// {
//   int numberDecimals = decimals ??
//       allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]?.decimals ??
//       2;
//   numberDecimals = numberDecimals > 2 &&
//       (finalNumber ?? amount).toString().split('.').length > 1
//       ? (finalNumber ?? amount).toString().split('.')[1].length < numberDecimals
//       ? (finalNumber ?? amount).toString().split('.')[1].length
//       : numberDecimals
//       : numberDecimals;
//
//   if (amount == double.infinity || amount == double.negativeInfinity) {
//     return "Infinity";
//   }
//   amount = double.parse(amount.toStringAsFixed(numberDecimals));
//   if (forceAbsoluteZero) amount = absoluteZero(amount);
//   if (finalNumber != null) {
//     finalNumber = double.parse(finalNumber.toStringAsFixed(numberDecimals));
//     if (forceAbsoluteZero) finalNumber = absoluteZero(finalNumber);
//   }
//
//   int? decimalDigits = forceAllDecimals
//       ? decimals
//       : allDecimals == true ||
//       hasDecimalPoints(finalNumber) ||
//       hasDecimalPoints(amount)
//       ? numberDecimals
//       : 0;
//   String? locale = appStateSettings["customNumberFormat"] == true
//       ? "en-US"
//       : Platform.localeName;
//   String? symbol =
//       customSymbol ?? getCurrencyString(allWallets, currencyKey: currencyKey);
//
//   bool useCustomNumberFormat = forceCustomNumberFormat ||
//       (forceNonCustomNumberFormat == false &&
//           appStateSettings["customNumberFormat"] == true);
//
//   final NumberFormat formatter;
//   if (getCustomNumberFormat != null) {
//     formatter = getCustomNumberFormat(
//         decimalDigits, locale, useCustomNumberFormat ? "" : symbol);
//   } else if (forceDefaultNumberFormatter == false &&
//       (forceCompactNumberFormatter ||
//           appStateSettings["shortNumberFormat"] == "compact")) {
//     formatter = NumberFormat.compactCurrency(
//       locale: locale,
//       decimalDigits: decimalDigits,
//       symbol: useCustomNumberFormat ? "" : symbol,
//     );
//     formatter.significantDigitsInUse = false;
//   } else {
//     formatter = NumberFormat.currency(
//       decimalDigits: decimalDigits,
//       locale: locale,
//       symbol: useCustomNumberFormat ? "" : symbol,
//     );
//   }
//
//   // View the entire dictionary of locale formats, through NumberFormat.currency definition
//   // numberFormatSymbols[locale] as NumberSymbols
//
//   // If there is no currency symbol, use the currency code
//   if (forceHideCurrencyName == false &&
//       getCurrencyString(allWallets, currencyKey: currencyKey) == "") {
//     addCurrencyName = true;
//   }
//   String formatOutput = formatter.format(amount).trim();
//   String? currencyName;
//   if (addCurrencyName == true && currencyKey != null) {
//     currencyName = " " + currencyKey.toUpperCase();
//   } else if (addCurrencyName == true) {
//     currencyName = " " +
//         (allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]
//             ?.currency ??
//             "")
//             .toUpperCase();
//   }
//
//   if (useCustomNumberFormat) {
//     formatOutput = formatOutputWithNewDelimiterAndDecimal(
//       amount: finalNumber ?? amount,
//       currencyName: currencyName,
//       input: formatOutput,
//       delimiter: appStateSettings["numberFormatDelimiter"],
//       decimal: appStateSettings["numberFormatDecimal"],
//       symbol: symbol,
//     );
//   } else if (useCustomNumberFormat == false && currencyName != null) {
//     formatOutput = formatOutput + currencyName;
//   }
//
//   if (editFormattedOutput != null) {
//     return editFormattedOutput(formatOutput);
//   }
//
//   return formatOutput;
// }
//
// double absoluteZero(double number) {
//   if (number == -0) return number.abs();
//   return number;
// }
//
// bool hasDecimalPoints(double? value) {
//   if (value == null) return false;
//   String stringValue = value.toString();
//   int dotIndex = stringValue.indexOf('.');
//
//   if (dotIndex != -1) {
//     for (int i = dotIndex + 1; i < stringValue.length; i++) {
//       if (stringValue[i] != '0') {
//         return true;
//       }
//     }
//   }
//
//   return false;
// }
//
// String getCurrencyString(AllWallets allWallets, {String? currencyKey}) {
//   String? selectedWalletCurrency =
//       allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]?.currency;
//   return currencyKey != null
//       ? (currenciesJSON[currencyKey]?["Symbol"] ?? "")
//       : selectedWalletCurrency == null
//       ? ""
//       : (currenciesJSON[selectedWalletCurrency]?["Symbol"] ?? "");
// }
//
// String formatOutputWithNewDelimiterAndDecimal({
//   required double amount,
//   required String input,
//   required String delimiter,
//   required String decimal,
//   required String symbol,
//   required String? currencyName,
// }) {
//   // Use a placeholder
//   input = input.replaceAll(".", "\uFFFD");
//   input = input.replaceAll(",", delimiter);
//   input = input.replaceAll("\uFFFD", decimal);
//   String negativeSign = "";
//   if (amount < 0) {
//     input = input.replaceRange(0, 1, "");
//     negativeSign = "-";
//   }
//   if (appStateSettings["numberFormatCurrencyFirst"] == false) {
//     return negativeSign +
//         input +
//         (symbol.length > 0 ? "  " : "") +
//         symbol +
//         (currencyName ?? "");
//   } else {
//     return negativeSign + symbol + input + (currencyName ?? "");
//   }
// }
