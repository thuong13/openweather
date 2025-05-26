import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    try {
      await _notificationsPlugin.initialize(initializationSettings);
      print('NotificationService: Initialized successfully');

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Cấu hình kênh thông báo với âm thanh mặc định
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'aqi_channel',
            'AQI Notifications',
            description: 'Notifications for AQI updates',
            importance: Importance.max,
            playSound: true, // Bật âm thanh (dùng âm thanh mặc định)
          ),
        );
        print('NotificationService: Notification channel created with default sound');
      }
    } catch (e) {
      print('NotificationService: Error during initialization: $e');
      rethrow;
    }
  }

  static Future<bool> requestPermissions() async {
    final bool? granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    print('NotificationService: Permission granted: $granted');
    return granted ?? false;
  }

  static Future<void> showAqiNotification({
    required int id,
    required int aqi,
    String title = 'Cảnh báo chất lượng không khí',
  }) async {
    print('NotificationService: Attempting to show notification for AQI: $aqi');
    String body;
    switch (aqi) {
      case 5:
        body = 'AQI $aqi: Rất nguy hiểm! Ở trong nhà và sử dụng máy lọc không khí.';
        break;
      case 4:
        body = 'AQI $aqi: Xấu! Hạn chế ra ngoài và đeo khẩu trang.';
        break;
      case 3:
        body = 'AQI $aqi: Kém! Hạn chế hoạt động ngoài trời, đặc biệt với người nhạy cảm.';
        break;
      case 2:
        body = 'AQI $aqi: Trung bình. Cân nhắc đeo khẩu trang nếu bạn nhạy cảm.';
        break;
      default:
        body = 'AQI $aqi: Tốt. Không cần lo lắng.';
    }

    // Cấu hình chi tiết thông báo với âm thanh
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'aqi_channel',
      'AQI Notifications',
      channelDescription: 'Notifications for AQI updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true, // Bật âm thanh (dùng âm thanh mặc định)
      // Tùy chọn: Thêm âm thanh tùy chỉnh (nếu bạn muốn)
      // sound: RawResourceAndroidNotificationSound('notification'), // Thay 'notification' bằng tên tệp âm thanh
    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
      );
      print('NotificationService: Notification sent successfully');
    } catch (e) {
      print('NotificationService: Error sending notification: $e');
      rethrow;
    }
  }
}