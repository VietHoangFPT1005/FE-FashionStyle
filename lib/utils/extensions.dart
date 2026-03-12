import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ===== String Extensions =====
extension StringExt on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
}

// ===== Nullable String =====
extension NullableStringExt on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
}

// ===== Double Extensions =====
extension DoubleExt on double {
  String get toCurrency {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(this)}d';
  }

  String get toCompact {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
    return toStringAsFixed(0);
  }
}

// ===== DateTime Extensions =====
extension DateTimeExt on DateTime {
  String get toFormattedDate => DateFormat('dd/MM/yyyy').format(this);
  String get toFormattedDateTime => DateFormat('HH:mm dd/MM/yyyy').format(this);
  String get toTimeOnly => DateFormat('HH:mm').format(this);
}

// ===== Context Extensions =====
extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<T?> pushNamed<T>(String route, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(route, arguments: arguments);
  }

  Future<T?> pushReplacementNamed<T>(String route, {Object? arguments}) {
    return Navigator.of(this).pushReplacementNamed(route, arguments: arguments);
  }

  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}
