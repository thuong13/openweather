import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final bool isEnabled;
  final Function(bool) onNotificationChanged;

  const NotificationSettingsScreen({
    required this.isEnabled,
    required this.onNotificationChanged,
    Key? key,
  }) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.isEnabled;
    print('NotificationSettingsScreen: Initial isEnabled: $_isEnabled');
  }

  void _toggleNotifications(bool value) async {
    if (value) {
      final hasPermission = await NotificationService.requestPermissions();
      print('NotificationSettingsScreen: Permission granted: $hasPermission');
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật quyền thông báo trong cài đặt thiết bị!'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.fixed,
              action: SnackBarAction(
                label: 'Cài đặt',
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    final bool opened = await openAppSettings();
                    print('NotificationSettingsScreen: openAppSettings result: $opened');
                    if (!opened && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không thể mở cài đặt. Vui lòng vào cài đặt thủ công.'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.fixed,
                        ),
                      );
                    }
                  } catch (e) {
                    print('NotificationSettingsScreen: Error opening app settings: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi mở cài đặt: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.fixed,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isEnabled = value;
      print('NotificationSettingsScreen: Updated isEnabled to $_isEnabled');
    });
    widget.onNotificationChanged(_isEnabled);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _isEnabled);
    print('NotificationSettingsScreen: Saved notificationsEnabled: $_isEnabled to SharedPreferences');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Thông báo đã được bật!' : 'Thông báo đã được tắt!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Trả về true để thông báo rằng cài đặt đã thay đổi
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt thông báo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Bật thông báo chất lượng không khí',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _isEnabled ? 'Thông báo đang được bật' : 'Thông báo đang tắt',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                  value: _isEnabled,
                  onChanged: _toggleNotifications,
                  secondary: Icon(
                    Icons.notifications,
                    size: 24,
                    color: _isEnabled ? Colors.blue : Colors.grey,
                  ),
                  activeColor: Colors.blue,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Lưu ý: Thông báo sẽ được gửi khi AQI đạt mức nguy hiểm (AQI ≥ 2).',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}