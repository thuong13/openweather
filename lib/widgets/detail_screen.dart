import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/air_quality_data.dart';
import '../database/database_history.dart';
import '../models/forecast_service.dart';
import '../models/notification_service.dart';
import '../services/daily.dart';
import '../services/forecast.dart';
import 'DailyForecastWidget.dart';
import 'history_chart.dart';
import 'notification_settings_screen.dart';
import 'forecast_widget.dart';
import 'pollutant_detail_screen.dart';
import 'dart:math' as math;
import '../services/api.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class DetailScreen extends StatefulWidget {
  final AirQualityData airQualityData;
  final double lat;
  final double lon;

  const DetailScreen({
    required this.airQualityData,
    required this.lat,
    required this.lon,
    Key? key,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _history = [];
  late Future<List<Forecast>> _forecastFuture;
  late Future<List<ForecastDaily>> _dailyForecastFuture;
  bool _notificationsEnabled = false;
  late AirQualityData _currentAirQualityData;
  final AirQualityService _airQualityService = AirQualityService();
  Timer? _updateTimer;
  DateTime? _lastUpdateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentAirQualityData = widget.airQualityData;
    _loadHistory();
    _forecastFuture = ForecastService.get48HourForecast(widget.lat, widget.lon);
    _dailyForecastFuture = ForecastService.get5DayForecast(widget.lat, widget.lon);
    _startAutoUpdate();
    _loadNotificationSettings().then((_) {
      print('DetailScreen: After loading settings, notificationsEnabled: $_notificationsEnabled');
      NotificationService.initialize().then((_) {
        _checkAndShowNotification(_currentAirQualityData.aqi);
      }).catchError((e) {
        print('DetailScreen: Error initializing NotificationService: $e');
      });
    });
  }

  Future<void> _loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      print('DetailScreen: Loaded notificationsEnabled: $_notificationsEnabled');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('DetailScreen: AppLifecycleState changed to $state');
    if (state == AppLifecycleState.resumed) {
      _updateDataIfNeeded();
    }
  }

  Future<void> _updateData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final airQualityData = await _airQualityService.fetchAirQuality(
        widget.lat,
        widget.lon,
        widget.airQualityData.city,
      );
      final forecastFuture = ForecastService.get48HourForecast(widget.lat, widget.lon);

      setState(() {
        _currentAirQualityData = airQualityData;
        _forecastFuture = forecastFuture;
        _lastUpdateTime = DateTime.now();
        _isLoading = false;
      });

      _checkAndShowNotification(_currentAirQualityData.aqi);
    } catch (e) {
      print('DetailScreen: Error updating data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi cập nhật dữ liệu: $e',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _updateDataIfNeeded() async {
    if (_lastUpdateTime == null || DateTime.now().difference(_lastUpdateTime!).inMinutes >= 1) {
      await _updateData();
    }
  }

  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateData();
    });
  }

  Future<void> _loadHistory() async {
    try {
      final data = await DatabaseHistory.instance.getHistory(widget.airQualityData.city);
      if (mounted) {
        setState(() {
          _history = data;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải lịch sử: $e');
    }
  }

  void _checkAndShowNotification(int aqi) async {
    print('DetailScreen: Checking notification for AQI: $aqi, notificationsEnabled: $_notificationsEnabled');
    if (!_notificationsEnabled) {
      print('DetailScreen: Notifications are disabled, skipping');
      return;
    }

    final hasPermission = await NotificationService.requestPermissions();
    print('DetailScreen: Has permission: $hasPermission');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vui lòng bật quyền thông báo trong cài đặt thiết bị để nhận cảnh báo AQI!',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.orangeAccent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Cài đặt',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  final bool opened = await openAppSettings();
                  print('DetailScreen: openAppSettings result: $opened');
                  if (!opened && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Không thể mở cài đặt. Vui lòng vào cài đặt thủ công.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  print('DetailScreen: Error opening app settings: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Lỗi khi mở cài đặt: $e',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    print('DetailScreen: Sending notification for AQI: $aqi');
    try {
      await NotificationService.showAqiNotification(id: 0, aqi: aqi);
    } catch (e) {
      print('DetailScreen: Error showing notification: $e');
    }
  }

  void _navigateToNotificationSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(
          isEnabled: _notificationsEnabled,
          onNotificationChanged: (bool enabled) async {
            setState(() {
              print('DetailScreen: Updating notificationsEnabled to $enabled');
              _notificationsEnabled = enabled;
            });
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('notificationsEnabled', enabled);
            print('DetailScreen: Saved notificationsEnabled: $enabled to SharedPreferences');
            if (enabled) {
              _checkAndShowNotification(_currentAirQualityData.aqi);
            }
          },
        ),
      ),
    );
    if (result == true) {
      await _loadNotificationSettings();
      print('DetailScreen: Reloaded notificationsEnabled: $_notificationsEnabled');
      if (_notificationsEnabled) {
        _checkAndShowNotification(_currentAirQualityData.aqi);
      }
    }
  }

  String _getHealthWarning(int aqi) {
    switch (aqi) {
      case 5:
        return 'Rất kém, ảnh hưởng nghiêm trọng!';
      case 4:
        return 'Xấu, cần hạn chế ra ngoài!';
      case 3:
        return 'Kém, có thể ảnh hưởng đến sức khỏe!';
      case 2:
        return 'Trung bình, có thể gây kích ứng nhẹ!';
      case 1:
      default:
        return 'Tốt, không có ảnh hưởng đáng kể!';
    }
  }

  Color _getAqiColor(int aqi) {
    switch (aqi) {
      case 5:
        return Colors.purple;
      case 4:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.amber;
      case 1:
      default:
        return Colors.green;
    }
  }

  Color _getAqiBackgroundColor(int aqi) {
    switch (aqi) {
      case 5:
        return Colors.purple.withOpacity(0.1);
      case 4:
        return Colors.red.withOpacity(0.1);
      case 3:
        return Colors.orange.withOpacity(0.1);
      case 2:
        return Colors.amber.withOpacity(0.1);
      case 1:
      default:
        return Colors.green.withOpacity(0.1);
    }
  }

  List<Map<String, dynamic>> _getHealthRecommendations(int aqi) {
    switch (aqi) {
      case 5:
        return [
          {'icon': Icons.warning, 'text': 'Cảnh báo: Chất lượng không khí rất nguy hiểm! Ở trong nhà liên tục.'},
          {'icon': Icons.directions_run, 'text': 'Tuyệt đối không tập thể dục ngoài trời.'},
          {'icon': Icons.window, 'text': 'Đóng kín cửa sổ và cửa ra vào.'},
          {'icon': Icons.masks, 'text': 'Bắt buộc đeo khẩu trang N95 nếu phải ra ngoài.'},
          {'icon': Icons.air, 'text': 'Sử dụng máy lọc không khí liên tục.'},
          {'icon': Icons.child_care, 'text': 'Đặc biệt: Trẻ em, người già, người có bệnh hô hấp nên tránh mọi hoạt động ngoài trời.'},
        ];
      case 4:
        return [
          {'icon': Icons.directions_run, 'text': 'Tránh tập thể dục ngoài trời.'},
          {'icon': Icons.window, 'text': 'Đóng cửa sổ để tránh không khí bẩn bên ngoài.'},
          {'icon': Icons.masks, 'text': 'Đeo khẩu trang khi ra ngoài.'},
          {'icon': Icons.air, 'text': 'Chạy máy lọc không khí.'},
          {'icon': Icons.child_care, 'text': 'Đặc biệt: Trẻ em, người già, người có bệnh hô hấp nên ở trong nhà.'},
        ];
      case 3:
        return [
          {'icon': Icons.directions_run, 'text': 'Hạn chế tập thể dục ngoài trời.'},
          {'icon': Icons.window, 'text': 'Đóng cửa sổ nếu không khí bên ngoài tệ.'},
          {'icon': Icons.masks, 'text': 'Nên đeo khẩu trang khi ra ngoài.'},
          {'icon': Icons.air, 'text': 'Sử dụng máy lọc không khí để cải thiện không khí trong nhà.'},
          {'icon': Icons.child_care, 'text': 'Đặc biệt: Trẻ em, người già, người có bệnh hô hấp nên hạn chế ra ngoài.'},
        ];
      case 2:
        return [
          {'icon': Icons.directions_run, 'text': 'Tập thể dục ngoài trời vẫn an toàn, nhưng hạn chế nếu bạn nhạy cảm.'},
          {'icon': Icons.window, 'text': 'Mở cửa sổ, nhưng chú ý nếu không khí trở nên tệ hơn.'},
          {'icon': Icons.masks, 'text': 'Cân nhắc đeo khẩu trang nếu bạn nhạy cảm với không khí.'},
          {'icon': Icons.air, 'text': 'Sử dụng máy lọc không khí nếu cần.'},
          {'icon': Icons.child_care, 'text': 'Đặc biệt: Người nhạy cảm nên theo dõi triệu chứng khi ra ngoài.'},
        ];
      case 1:
      default:
        return [
          {'icon': Icons.directions_run, 'text': 'Tập thể dục ngoài trời thoải mái.'},
          {'icon': Icons.window, 'text': 'Mở cửa sổ để thông thoáng không khí.'},
          {'icon': Icons.masks, 'text': 'Không cần đeo khẩu trang khi ra ngoài.'},
          {'icon': Icons.air, 'text': 'Không cần sử dụng máy lọc không khí.'},
          {'icon': Icons.child_care, 'text': 'Đặc biệt: Tất cả mọi người đều có thể hoạt động bình thường.'},
        ];
    }
  }

  int _calculatePollutantAqi(String title, double value) {
    switch (title) {
      case 'PM2.5':
        if (value <= 12) return 1;
        if (value <= 35) return 2;
        if (value <= 55) return 3;
        if (value <= 150) return 4;
        return 5;
      case 'PM10':
        if (value <= 54) return 1;
        if (value <= 154) return 2;
        if (value <= 254) return 3;
        if (value <= 354) return 4;
        return 5;
      case 'CO':
        if (value <= 4400) return 1;
        if (value <= 9400) return 2;
        if (value <= 12400) return 3;
        if (value <= 15400) return 4;
        return 5;
      case 'SO₂':
        if (value <= 40) return 1;
        if (value <= 100) return 2;
        if (value <= 200) return 3;
        if (value <= 500) return 4;
        return 5;
      default:
        return 0;
    }
  }

  Color _getPollutantColor(String title, double value) {
    final pollutantAqi = _calculatePollutantAqi(title, value);
    switch (pollutantAqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getPollutionLevel(String title, double value) {
    final pollutantAqi = _calculatePollutantAqi(title, value);
    switch (pollutantAqi) {
      case 1:
        return 'Tốt';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Kém';
      case 4:
        return 'Xấu';
      case 5:
        return 'Rất xấu';
      default:
        return 'Không xác định';
    }
  }

  void _saveToHistory(BuildContext context) async {
    final data = {
      'city': widget.airQualityData.city,
      'aqi': _currentAirQualityData.aqi,
      'pm25': _currentAirQualityData.pm2_5,
      'pm10': _currentAirQualityData.pm10,
      'co': _currentAirQualityData.co,
      'so2': _currentAirQualityData.so2,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await DatabaseHistory.instance.insertAirQuality(data);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu lịch sử thành công!',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi lưu lịch sử: $e',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _clearHistory(BuildContext context) async {
    try {
      await DatabaseHistory.instance.clearHistory(widget.airQualityData.city);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xóa tất cả lịch sử!',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi xóa lịch sử: $e',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.airQualityData.city,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getAqiColor(_currentAirQualityData.aqi),
                  _getAqiColor(_currentAirQualityData.aqi).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _notificationsEnabled ? Icons.notifications_active : Icons.notifications,
                    key: ValueKey<bool>(_notificationsEnabled),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                tooltip: 'Cài đặt thông báo',
                onPressed: _navigateToNotificationSettings,
              ),
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getAqiColor(_currentAirQualityData.aqi).withOpacity(0.05),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'aqi_card_${widget.airQualityData.city}',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                _getAqiBackgroundColor(_currentAirQualityData.aqi),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _getAqiColor(_currentAirQualityData.aqi).withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                widget.airQualityData.city,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  'Chỉ số AQI: ${_currentAirQualityData.aqi}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    shadows: [
                                      Shadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 4),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  _getHealthWarning(_currentAirQualityData.aqi),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildWeatherInfo(
                                    Icons.thermostat,
                                    '${_currentAirQualityData.temperature.toStringAsFixed(1)} °C',
                                    Colors.black87,
                                  ),
                                  _buildWeatherInfo(
                                    Icons.water_drop,
                                    '${_currentAirQualityData.humidity.toStringAsFixed(0)} %',
                                    Colors.lightBlueAccent,
                                  ),
                                  _buildWeatherInfo(
                                    Icons.air,
                                    '${_currentAirQualityData.windSpeed.toStringAsFixed(1)} km/h',
                                    Colors.black87,
                                    windDirection: _currentAirQualityData.windDirection,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                child: Icon(
                                  Icons.cloud,
                                  size: 90,
                                  color: _getAqiColor(_currentAirQualityData.aqi).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông tin chi tiết về chất lượng không khí',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildPollutantCard(
                                icon: Icons.opacity,
                                title: 'PM2.5',
                                value: _currentAirQualityData.pm2_5,
                                unit: 'µg/m³',
                              ),
                              const SizedBox(height: 12),
                              _buildPollutantCard(
                                icon: Icons.opacity_outlined,
                                title: 'PM10',
                                value: _currentAirQualityData.pm10,
                                unit: 'µg/m³',
                              ),
                              const SizedBox(height: 12),
                              _buildPollutantCard(
                                icon: Icons.local_fire_department,
                                title: 'CO',
                                value: _currentAirQualityData.co,
                                unit: 'µg/m³',
                              ),
                              const SizedBox(height: 12),
                              _buildPollutantCard(
                                icon: Icons.cloud,
                                title: 'SO₂',
                                value: _currentAirQualityData.so2,
                                unit: 'µg/m³',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Khuyến nghị về sức khỏe',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_currentAirQualityData.aqi == 5) ...[
                                const SizedBox(height: 16),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning, color: Colors.red, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Cảnh báo khẩn cấp: Chất lượng không khí rất nguy hiểm!',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              ..._getHealthRecommendations(_currentAirQualityData.aqi).map((recommendation) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getAqiColor(_currentAirQualityData.aqi).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          recommendation['icon'],
                                          color: _getAqiColor(_currentAirQualityData.aqi),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          recommendation['text'],
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biểu đồ lịch sử AQI',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 300,
                                child: _history.isEmpty
                                    ? Center(
                                  child: Text(
                                    'Không có dữ liệu lịch sử',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                    : AqiChart(history: _history),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _saveToHistory(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        'Lưu vào lịch sử',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _clearHistory(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        'Xóa lịch sử',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dự báo 5 ngày',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<List<ForecastDaily>>(
                                future: _dailyForecastFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: _getAqiColor(_currentAirQualityData.aqi),
                                        strokeWidth: 3,
                                      ),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Lỗi tải dữ liệu 5 ngày: ${snapshot.error}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.redAccent,
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.warning_amber,
                                            color: Colors.grey[600],
                                            size: 30,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Không có dữ liệu dự báo 5 ngày.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final dailyForecasts = snapshot.data!;
                                  return DailyForecastWidget(forecasts: dailyForecasts);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dự báo theo giờ',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<List<Forecast>>(
                                future: _forecastFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: _getAqiColor(_currentAirQualityData.aqi),
                                        strokeWidth: 3,
                                      ),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Lỗi tải dữ liệu: ${snapshot.error}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.redAccent,
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.warning_amber,
                                            color: Colors.grey[600],
                                            size: 30,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Không có dữ liệu dự báo (Kiểm tra API Key hoặc giới hạn gói miễn phí)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ForecastWidget(forecasts: snapshot.data!);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _getAqiColor(_currentAirQualityData.aqi),
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value, Color iconColor, {double? windDirection}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        if (windDirection != null) ...[
          const SizedBox(width: 4),
          Transform.rotate(
            angle: (windDirection * math.pi / 180),
            child: const Icon(
              Icons.arrow_forward,
              size: 14,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPollutantCard({
    required IconData icon,
    required String title,
    required double value,
    required String unit,
  }) {
    final color = _getPollutantColor(title, value);
    final level = _getPollutionLevel(title, value);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PollutantDetailScreen(
              title: title,
              value: value,
              unit: unit,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}