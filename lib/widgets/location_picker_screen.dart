import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/air_quality_data.dart';
import '../models/theme_language_provider.dart'; // Đảm bảo tên file đúng

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  bool _isLoading = false;
  String _cityName = 'Đang lấy vị trí...';
  AirQualityData? _airQualityData;
  double? _lat;
  double? _lon;

  final String openWeatherApiKey = 'fc93447736eaa6a442ecabd8102cd2c6'; // Thay bằng API key hợp lệ

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndAirQuality();
  }

  Future<void> _getCurrentLocationAndAirQuality() async {
    setState(() {
      _isLoading = true;
      _cityName = 'Đang lấy vị trí...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _cityName = 'GPS bị tắt');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng bật GPS để lấy vị trí thực tế!'),
            action: SnackBarAction(
              label: 'Mở cài đặt',
              onPressed: () async {
                await Geolocator.openLocationSettings();
                _getCurrentLocationAndAirQuality();
              },
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối!');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền vị trí bị chặn vĩnh viễn!');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final geoUrl =
          'http://api.openweathermap.org/geo/1.0/reverse?lat=${position.latitude}&lon=${position.longitude}&limit=1&appid=$openWeatherApiKey';
      final geoResponse = await http.get(Uri.parse(geoUrl));
      final geoData = jsonDecode(geoResponse.body);
      String cityName = geoData[0]['name'] ?? 'Không xác định';

      final aqiUrl =
          'http://api.openweathermap.org/data/2.5/air_pollution?lat=${position.latitude}&lon=${position.longitude}&appid=$openWeatherApiKey';
      final aqiResponse = await http.get(Uri.parse(aqiUrl));
      final aqiData = jsonDecode(aqiResponse.body);

      final weatherUrl =
          'http://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$openWeatherApiKey&units=metric';
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final weatherData = jsonDecode(weatherResponse.body);

      final airQualityData = AirQualityData.fromJson(aqiData, weatherData, cityName);

      setState(() {
        _cityName = cityName;
        _airQualityData = airQualityData;
        _lat = position.latitude;
        _lon = position.longitude;
      });
    } catch (e) {
      print('Lỗi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy vị trí hoặc AQI: $e'), backgroundColor: Colors.red),
      );
      setState(() => _cityName = 'Lỗi lấy vị trí');
    } finally {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // Gradient tùy chỉnh theo theme
    final appBarGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.lightBlueAccent[700]!, Colors.blue[600]!] // Xanh đậm cho Dark Mode
          : [Colors.lightBlueAccent[700]!, Colors.blue[600]!], // Xanh dương nhạt đến đậm cho Light Mode
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chọn Vị Trí Hiện Tại',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: appBarGradient,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vị trí hiện tại của bạn:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).appBarTheme.foregroundColor))
                  : Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _cityName,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_airQualityData != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'Chỉ số AQI: ${_airQualityData!.aqi}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getAqiColor(_airQualityData!.aqi),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getHealthWarning(_airQualityData!.aqi),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _getAqiColor(_airQualityData!.aqi),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.thermostat, color: Colors.blueGrey),
                            SizedBox(width: 4),
                            Text(
                              '${_airQualityData!.temperature.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(width: 20),
                            Icon(Icons.water_drop, color: Colors.lightBlue),
                            SizedBox(width: 4),
                            Text(
                              '${_airQualityData!.humidity.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check),
                      onPressed: _isLoading || _airQualityData == null
                          ? null
                          : () {
                        Navigator.pop(context, {
                          'city': _cityName,
                          'airQualityData': _airQualityData,
                          'lat': _lat,
                          'lon': _lon,
                        });
                      },
                      label: Text('Thêm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: themeProvider.isDarkMode
                            ? Colors.lightBlueAccent[700] // Xanh đậm cho Dark Mode
                            : Colors.lightBlueAccent[700], // Xanh dương đậm cho Light Mode
                        foregroundColor: Colors.white, // Chữ/icon trắng cho cả hai chế độ
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.white, // Viền trắng đồng bộ
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      label: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, // Chữ/icon trắng
                        backgroundColor: themeProvider.isDarkMode
                            ? Colors.lightBlueAccent[700] // Đồng bộ màu nền với nút "Thêm" trong Dark Mode
                            : Colors.lightBlueAccent[700], // Đồng bộ màu nền với nút "Thêm" trong Light Mode
                        side: const BorderSide(
                          color: Colors.white, // Viền trắng đồng bộ
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}