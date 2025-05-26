class Forecast {
  final DateTime date;
  final int aqi;
  final String description;
  final double temperature; // Nhiệt độ
  final double windSpeed;   // Tốc độ gió
  final int windDirection;  // Hướng gió (độ)
  final String weatherIcon; // Biểu tượng thời tiết

  Forecast({
    required this.date,
    required this.aqi,
    required this.description,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherIcon, required String weather,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    int aqi = (json['main']['aqi'] as num).toInt();
    String description = _getAqiDescription(aqi);

    return Forecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      aqi: aqi,
      description: description,
      temperature: (json['main']['temp'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      windDirection: (json['wind']['deg'] as num).toInt(),
      weatherIcon: json['weather'] != null && json['weather'].isNotEmpty
          ? json['weather'][0]['icon'] ?? '01d'
          : '01d', weather: '',
    );
  }

  static String _getAqiDescription(int aqi) {
    switch (aqi) {
      case 5:
        return 'Rất xấu';
      case 4:
        return 'Xấu';
      case 3:
        return 'Trung bình';
      case 2:
        return 'Khá';
      case 1:
      default:
        return 'Tốt';
    }
  }
}