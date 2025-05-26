class ForecastDaily {
  final DateTime date;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String weatherMain;
  final double windSpeed;
  final int? aqi;
  final double humidity; // Thêm trường độ ẩm

  ForecastDaily({
    required this.date,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.weatherMain,
    required this.windSpeed,
    this.aqi,
    required this.humidity, // Đánh dấu required vì độ ẩm là thông tin quan trọng
  });

  factory ForecastDaily.fromJson(Map<String, dynamic> json) {
    // Hàm xử lý an toàn chuyển đổi sang double
    double safeToDouble(dynamic value) => value == null ? 0.0 : (value is int ? value.toDouble() : (value as num).toDouble());

    final main = json['main'] ?? {};
    final weather = json['weather'] != null && json['weather'].isNotEmpty ? json['weather'][0] : {'main': 'Unknown'};
    final wind = json['wind'] ?? {};

    return ForecastDaily(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000).toLocal(),
      temp: safeToDouble(main['temp']),
      tempMin: safeToDouble(main['temp_min']),
      tempMax: safeToDouble(main['temp_max']),
      weatherMain: weather['main'] ?? 'Unknown',
      windSpeed: safeToDouble(wind['speed']) * 3.6, // Chuyển m/s sang km/h
      aqi: json['main']['aqi'] as int?, // Lấy AQI, có thể null
      humidity: safeToDouble(main['humidity']), // Lấy độ ẩm từ JSON
    );
  }
}