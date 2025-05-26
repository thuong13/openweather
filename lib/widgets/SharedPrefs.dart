import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPrefs? _instance;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  static Future<SharedPrefs> getInstance() async {
    if (_instance == null) {
      _instance = SharedPrefs._();
      await _instance!._init();
    }
    return _instance!;
  }

  SharedPrefs._();

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('Lỗi khi khởi tạo SharedPreferences: $e');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> setNotificationsEnabled(bool value) async {
    if (!_isInitialized) {
      throw Exception('SharedPrefs chưa được khởi tạo');
    }
    try {
      await _prefs.setBool('notificationsEnabled', value);
    } catch (e) {
      debugPrint('Lỗi khi lưu notificationsEnabled: $e');
      rethrow;
    }
  }

  Future<bool> getNotificationsEnabled() async {
    if (!_isInitialized) {
      throw Exception('SharedPrefs chưa được khởi tạo');
    }
    try {
      return _prefs.getBool('notificationsEnabled') ?? false;
    } catch (e) {
      debugPrint('Lỗi khi đọc notificationsEnabled: $e');
      return false;
    }
  }

  Future<void> setNotificationHour(int hour) async {
    if (!_isInitialized) {
      throw Exception('SharedPrefs chưa được khởi tạo');
    }
    try {
      await _prefs.setInt('notificationHour', hour);
    } catch (e) {
      debugPrint('Lỗi khi lưu notificationHour: $e');
      rethrow;
    }
  }

  Future<int> getNotificationHour() async {
    if (!_isInitialized) {
      throw Exception('SharedPrefs chưa được khởi tạo');
    }
    try {
      return _prefs.getInt('notificationHour') ?? 8;
    } catch (e) {
      debugPrint('Lỗi khi đọc notificationHour: $e');
      return 8;
    }
  }

  Future<void> setNotificationMinute(int minute) async {
    if (!_isInitialized) {
      throw Exception('SharedPrefs chưa được khởi tạo');
    }
    try {
      await _prefs.setInt('notificationMinute', minute);
    } catch (e) {
      debugPrint('Lỗi khi lưu notificationMinute: $e');
      rethrow;
    }
  }

  Future<int> getNotificationMinute() async {
    if (!_isInitialized) {
      throw Exception('SharedPrefs chưa được khởi tạo');
    }
    try {
      return _prefs.getInt('notificationMinute') ?? 0;
    } catch (e) {
      debugPrint('Lỗi khi đọc notificationMinute: $e');
      return 0;
    }
  }
}