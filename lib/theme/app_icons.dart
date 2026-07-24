import 'package:flutter/material.dart';

/// Semua ikon aplikasi didaftarkan di sini supaya konsisten
/// dan gampang diganti sekaligus kalau nanti mau ubah gaya ikon.
class AppIcons {
  AppIcons._();

  // Navigasi utama
  static const IconData home = Icons.home_rounded;
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData profile = Icons.person_rounded;

  // Umum / aksi
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.tune_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData qrScanner = Icons.qr_code_scanner_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
}