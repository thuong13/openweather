import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_data.dart';

class AirQualityService {
  final String apiKey = 'fc93447736eaa6a442ecabd8102cd2c6'; // Consider securing this key in production
  final String _baseUrl = 'api.openweathermap.org';

  // Fetch air quality data from coordinates
  Future<AirQualityData> fetchAirQuality(double lat, double lon, String city) async {
    try {
      // Gọi API chất lượng không khí
      final airPollutionUri = Uri.https(
        _baseUrl,
        '/data/2.5/air_pollution',
        {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'appid': apiKey,
        },
      );
      print('Air Quality URI: $airPollutionUri');
      final airResponse = await http.get(airPollutionUri);
      print('Air Quality API response: ${airResponse.statusCode} - ${airResponse.body}');

      if (airResponse.statusCode != 200) {
        throw Exception('Failed to load air quality data: ${airResponse.statusCode} - ${airResponse.body}');
      }

      final airJsonData = jsonDecode(airResponse.body);
      if (airJsonData['list'] == null || airJsonData['list'].isEmpty) {
        throw Exception('Air quality data is empty for $city');
      }

      final airData = airJsonData['list'][0];
      final components = airData['components'];

      // Gọi API thời tiết
      final weatherUri = Uri.https(
        _baseUrl,
        '/data/2.5/weather',
        {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'appid': apiKey,
          'units': 'metric',
        },
      );
      print('Weather URI: $weatherUri');
      final weatherResponse = await http.get(weatherUri);
      print('Weather API response: ${weatherResponse.statusCode} - ${weatherResponse.body}');

      if (weatherResponse.statusCode != 200) {
        throw Exception('Failed to load weather data: ${weatherResponse.statusCode} - ${weatherResponse.body}');
      }

      final weatherJsonData = jsonDecode(weatherResponse.body);

      // Lấy weatherIcon từ dữ liệu thời tiết
      final weatherIcon = weatherJsonData['weather'] != null && weatherJsonData['weather'].isNotEmpty
          ? weatherJsonData['weather'][0]['icon']
          : null;

      // Tạo đối tượng AirQualityData từ dữ liệu
      return AirQualityData(
        city: city,
        aqi: airData['main']['aqi'].toInt(),
        pm2_5: components['pm2_5']?.toDouble() ?? 0.0,
        pm10: components['pm10']?.toDouble() ?? 0.0,
        co: components['co']?.toDouble() ?? 0.0,
        so2: components['so2']?.toDouble() ?? 0.0,
        no2: components['no2']?.toDouble() ?? 0.0, // Thêm NO₂
        o3: components['o3']?.toDouble() ?? 0.0,   // Thêm O₃
        temperature: weatherJsonData['main']['temp']?.toDouble() ?? 0.0,
        humidity: weatherJsonData['main']['humidity']?.toDouble() ?? 0.0,
        windSpeed: weatherJsonData['wind']['speed']?.toDouble() ?? 0.0,
        windDirection: weatherJsonData['wind']['deg']?.toDouble() ?? 0.0,
        weatherIcon: weatherIcon,
      );
    } catch (e) {
      throw Exception('Failed to fetch air quality or weather data: $e');
    }
  }

  // Get coordinates from city name
  Future<Map<String, double>> getCoordinates(String city) async {
    final uri = Uri.https(
      _baseUrl,
      '/geo/1.0/direct',
      {
        'q': city,
        'limit': '1',
        'appid': apiKey,
      },
    );
    print('Geocoding URI: $uri');
    try {
      final response = await http.get(uri);
      print('Geocoding API response for $city: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': data[0]['lat']?.toDouble() ?? 0.0,
            'lon': data[0]['lon']?.toDouble() ?? 0.0,
          };
        } else {
          throw Exception('City not found: $city');
        }
      } else {
        throw Exception('Failed to get coordinates: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch coordinates: $e');
    }
  }

  // Convenience method to get air quality data by city name
  Future<AirQualityData> fetchAirQualityByCity(String city) async {
    try {
      final coords = await getCoordinates(city);
      return fetchAirQuality(coords['lat']!, coords['lon']!, city);
    } catch (e) {
      throw Exception('Error fetching air quality for city $city: $e');
    }
  }
}