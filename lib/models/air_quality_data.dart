import 'dart:convert';

class AirQualityData {
  final String city;
  final int aqi;
  final double pm2_5;
  final double pm10;
  final double co;
  final double so2;
  final double no2; // Thêm NO₂
  final double o3;  // Thêm O₃
  final double temperature; // Nhiệt độ (đơn vị: °C)
  final double humidity; // Độ ẩm (đơn vị: %)
  final double windSpeed; // Tốc độ gió (đơn vị: km/h)
  final double windDirection; // Hướng gió (đơn vị: độ)
  final String? weatherIcon; // Biểu tượng thời tiết (ví dụ: "04d")

  AirQualityData({
    required this.city,
    required this.aqi,
    required this.pm2_5,
    required this.pm10,
    required this.co,
    required this.so2,
    required this.no2,
    required this.o3,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    this.weatherIcon,
  });

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'aqi': aqi,
      'pm2_5': pm2_5,
      'pm10': pm10,
      'co': co,
      'so2': so2,
      'no2': no2,
      'o3': o3,
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'weatherIcon': weatherIcon,
    };
  }

  // Tạo AirQualityData từ JSON
  factory AirQualityData.fromJson(Map<String, dynamic> airJson, Map<String, dynamic> weatherJson, String city) {
    final airData = airJson['list'][0];
    final weatherIcon = weatherJson['weather'] != null && weatherJson['weather'].isNotEmpty
        ? weatherJson['weather'][0]['icon']
        : null;

    return AirQualityData(
      city: city,
      aqi: airData['main']['aqi'] ?? 0,
      pm2_5: (airData['components']['pm2_5'] ?? 0).toDouble(),
      pm10: (airData['components']['pm10'] ?? 0).toDouble(),
      co: (airData['components']['co'] ?? 0).toDouble(),
      so2: (airData['components']['so2'] ?? 0).toDouble(),
      no2: (airData['components']['no2'] ?? 0).toDouble(), // Thêm NO₂ từ JSON
      o3: (airData['components']['o3'] ?? 0).toDouble(),   // Thêm O₃ từ JSON
      temperature: (weatherJson['main']['temp'] ?? 0).toDouble(),
      humidity: (weatherJson['main']['humidity'] ?? 0).toDouble(),
      windSpeed: (weatherJson['wind']['speed'] ?? 0).toDouble(),
      windDirection: (weatherJson['wind']['deg'] ?? 0).toDouble(),
      weatherIcon: weatherIcon,
    );
  }
}