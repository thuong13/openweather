import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../services/daily.dart';
import '../services/forecast.dart';

class ForecastService {
  static const String apiKey = 'fc93447736eaa6a442ecabd8102cd2c6';
  static const String weatherUrl = 'https://api.openweathermap.org/data/2.5/forecast';
  static const String airPollutionUrl = 'http://api.openweathermap.org/data/2.5/air_pollution/forecast';

  static Future<List<Forecast>> get48HourForecast(double lat, double lon) async {
    try {
      final weatherUri = '$weatherUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final weatherResponse = await http.get(Uri.parse(weatherUri));

      if (weatherResponse.statusCode != 200) {
        throw Exception('Không thể lấy dữ liệu dự báo thời tiết. Mã lỗi: ${weatherResponse.statusCode}');
      }

      final weatherJsonData = jsonDecode(weatherResponse.body);
      if (weatherJsonData == null || weatherJsonData['list'] == null) {
        throw Exception('Dữ liệu dự báo thời tiết không hợp lệ.');
      }

      final airPollutionUri = '$airPollutionUrl?lat=$lat&lon=$lon&appid=$apiKey';
      final airPollutionResponse = await http.get(Uri.parse(airPollutionUri));

      if (airPollutionResponse.statusCode != 200) {
        throw Exception('Không thể lấy dữ liệu dự báo AQI. Mã lỗi: ${airPollutionResponse.statusCode}');
      }

      final airPollutionJsonData = jsonDecode(airPollutionResponse.body);
      if (airPollutionJsonData == null || airPollutionJsonData['list'] == null) {
        throw Exception('Dữ liệu dự báo AQI không hợp lệ.');
      }

      List<Forecast> forecasts = [];
      List weatherList = weatherJsonData['list'];
      List airPollutionList = airPollutionJsonData['list'];

      for (int i = 0; i < weatherList.length && i < airPollutionList.length && i < 16; i++) {
        final weatherData = weatherList[i];
        final airData = airPollutionList[i];

        final combinedData = {
          'dt': weatherData['dt'],
          'main': {
            'temp': weatherData['main']['temp'] ?? 0.0,
            'aqi': airData['main']['aqi'],
          },
          'weather': weatherData['weather'],
          'wind': weatherData['wind'],
        };

        forecasts.add(Forecast.fromJson(combinedData));
      }

      return forecasts;
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu dự báo: $e');
    }
  }

  static Future<List<ForecastDaily>> get5DayForecast(double lat, double lon) async {
    try {
      final weatherUri = '$weatherUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&cnt=40';
      final weatherResponse = await http.get(Uri.parse(weatherUri));

      if (weatherResponse.statusCode != 200) {
        throw Exception('Không thể lấy dữ liệu dự báo 5 ngày. Mã lỗi: ${weatherResponse.statusCode}');
      }

      final weatherJsonData = jsonDecode(weatherResponse.body);
      if (weatherJsonData == null || weatherJsonData['list'] == null) {
        throw Exception('Dữ liệu dự báo 5 ngày không hợp lệ.');
      }

      final airPollutionUri = '$airPollutionUrl?lat=$lat&lon=$lon&appid=$apiKey';
      final airPollutionResponse = await http.get(Uri.parse(airPollutionUri));

      if (airPollutionResponse.statusCode != 200) {
        throw Exception('Không thể lấy dữ liệu dự báo AQI. Mã lỗi: ${airPollutionResponse.statusCode}');
      }

      final airPollutionJsonData = jsonDecode(airPollutionResponse.body);
      if (airPollutionJsonData == null || airPollutionJsonData['list'] == null) {
        throw Exception('Dữ liệu dự báo AQI không hợp lệ.');
      }

      List<ForecastDaily> dailyForecasts = [];
      List weatherList = weatherJsonData['list'];
      List airPollutionList = airPollutionJsonData['list'];
      Map<DateTime, List<Map<String, dynamic>>> dailyData = {};
      Map<DateTime, List<Map<String, dynamic>>> dailyAqiData = {};

      // Nhóm dữ liệu thời tiết theo ngày
      for (var weatherData in weatherList) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(weatherData['dt'] * 1000).toLocal();
        DateTime day = DateTime(date.year, date.month, date.day);

        if (!dailyData.containsKey(day)) {
          dailyData[day] = [];
        }
        dailyData[day]!.add(weatherData);
      }

      // Nhóm dữ liệu AQI theo ngày
      for (var airData in airPollutionList) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(airData['dt'] * 1000).toLocal();
        DateTime day = DateTime(date.year, date.month, date.day);

        if (!dailyAqiData.containsKey(day)) {
          dailyAqiData[day] = [];
        }
        dailyAqiData[day]!.add(airData);
      }

      // Tính toán dữ liệu dự báo hàng ngày
      dailyData.forEach((date, weatherDataList) {
        // Hàm xử lý an toàn
        double safeToDouble(dynamic value) => value == null ? 0.0 : (value is int ? value.toDouble() : (value as num).toDouble());

        double avgTemp = weatherDataList
            .map((d) => safeToDouble(d['main']?['temp']))
            .reduce((a, b) => a + b) /
            (weatherDataList.length > 0 ? weatherDataList.length : 1);

        double minTemp = weatherDataList
            .map((d) => safeToDouble(d['main']?['temp_min']))
            .reduce((a, b) => math.min(a, b));

        double maxTemp = weatherDataList
            .map((d) => safeToDouble(d['main']?['temp_max']))
            .reduce((a, b) => math.max(a, b));

        String mainWeather = weatherDataList.isNotEmpty && weatherDataList[0]['weather'] != null && weatherDataList[0]['weather'].isNotEmpty
            ? weatherDataList[0]['weather'][0]['main'] ?? 'Unknown'
            : 'Unknown';

        double avgWindSpeed = weatherDataList
            .map((d) => safeToDouble(d['wind']?['speed']))
            .reduce((a, b) => a + b) /
            (weatherDataList.length > 0 ? weatherDataList.length : 1) *
            3.6;

        // Tính độ ẩm trung bình
        double avgHumidity = weatherDataList
            .map((d) => safeToDouble(d['main']?['humidity']))
            .reduce((a, b) => a + b) /
            (weatherDataList.length > 0 ? weatherDataList.length : 1);

        // Tính AQI trung bình cho ngày (nếu có dữ liệu AQI)
        int? avgAqi;
        if (dailyAqiData.containsKey(date) && dailyAqiData[date]!.isNotEmpty) {
          var aqiList = dailyAqiData[date]!
              .map((d) => d['main']?['aqi'] as int?)
              .where((aqi) => aqi != null)
              .map((aqi) => aqi!)
              .toList();
          avgAqi = aqiList.isNotEmpty ? (aqiList.reduce((a, b) => a + b) ~/ aqiList.length) : null;
        }

        dailyForecasts.add(ForecastDaily(
          date: date,
          temp: avgTemp,
          tempMin: minTemp,
          tempMax: maxTemp,
          weatherMain: mainWeather,
          windSpeed: avgWindSpeed,
          aqi: avgAqi,
          humidity: avgHumidity, // Thêm độ ẩm
        ));
      });

      return dailyForecasts.take(5).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu dự báo 5 ngày: $e');
    }
  }
}