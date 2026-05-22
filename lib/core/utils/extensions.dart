import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../theme/app_colors.dart';

extension DateTimeExtensions on DateTime {
  String toTimeAgo() {
    timeago.setLocaleMessages('es', timeago.EsMessages());
    return timeago.format(this, locale: 'es', allowFromNow: false);
  }

  String toFormattedTime() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String toFormattedDate() {
    return '$day/$month/$year';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

extension StringExtensions on String {
  String get initials {
    final parts = trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidUsername {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(this);
  }
}

extension ListExtensions<T> on List<T> {
  List<T> takeOrAll(int count) {
    if (length <= count) return this;
    return take(count).toList();
  }
}

extension BuildContextExtensions on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get surface2Color => isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
  Color get surface3Color => isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
  Color get textColor => isDark ? AppColors.darkText : AppColors.lightText;
  Color get textDimColor => isDark ? AppColors.darkTextDim : AppColors.lightTextDim;
  Color get textFaintColor => isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get borderStrongColor => isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  void showSuccessSnack(String message) => showSnackBar(message);
  void showErrorSnack(String message) => showSnackBar(message, isError: true);
}
