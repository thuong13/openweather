import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.grey[850], // Sáng hơn một chút, dịu mắt
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal[900], // Tông teal đậm
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(color: Colors.grey[800]),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.grey[300]), // Dịu hơn
      ),
      primaryColor: Colors.teal[800], // Xanh lam đậm, dịu mắt
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[800], // Đồng bộ với primaryColor
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.teal[800], // Đồng bộ với primaryColor
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    )
        : ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.grey[50], // Trắng ngà, dịu mắt
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal[50], // Tông teal nhạt
        foregroundColor: Colors.black,
      ),
      cardTheme: CardTheme(color: Colors.white),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.grey[700]), // Dịu hơn
      ),
      primaryColor: Colors.teal[400], // Xanh lam nhẹ, dịu mắt
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[400], // Đồng bộ với primaryColor
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.teal[400], // Đồng bộ với primaryColor
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}