import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../models/theme_language_provider.dart'; // Đảm bảo import ThemeProvider

class AddCityScreen extends StatefulWidget {
  @override
  _AddCityScreenState createState() => _AddCityScreenState();
}

class _AddCityScreenState extends State<AddCityScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController();
  final AirQualityService _airQualityService = AirQualityService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Khởi tạo animation cho hiệu ứng fade-in
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _addCity() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập tên thành phố!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final coords = await _airQualityService.getCoordinates(city);
      if (coords['lat'] == null || coords['lon'] == null) {
        throw Exception('Tọa độ không hợp lệ cho $city');
      }
      final airQualityData = await _airQualityService.fetchAirQuality(
        coords['lat']!,
        coords['lon']!,
        city,
      );

      final result = {
        'city': city,
        'airQualityData': airQualityData,
        'lat': coords['lat'],
        'lon': coords['lon'],
      };
      print('AddCityScreen: Add button pressed, returning result: $result');
      Navigator.pop(context, result);
    } catch (e) {
      print('AddCityScreen: Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tìm thấy thành phố: $city'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AddCityScreen: build called');
    // Lấy ThemeProvider để xác định chế độ sáng/tối
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Gradient tùy chỉnh theo theme
    final bodyGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!] // Dark Mode
          : [Colors.blue.shade200, Colors.blue.shade100], // Light Mode
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final buttonGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.blue.shade800, Colors.blue.shade700] // Dark Mode
          : [Colors.blue.shade600, Colors.blue.shade400], // Light Mode
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Thêm Thành Phố',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print('AddCityScreen: Back button pressed');
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: bodyGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    child: Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[800] // Dark Mode
                          : Colors.white, // Light Mode
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'Tên thành phố',
                        hintStyle: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade300,
                          fontStyle: FontStyle.italic,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : Colors.white,
                        prefixIcon: Icon(
                          Icons.search,
                          color: themeProvider.isDarkMode
                              ? Colors.blue.shade400
                              : Colors.blue.shade700,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  _isLoading
                      ? Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[800]
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      color: themeProvider.isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
                      strokeWidth: 3,
                    ),
                  )
                      : AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    child: ElevatedButton(
                      onPressed: _addCity,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: buttonGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          constraints: BoxConstraints(minHeight: 50, minWidth: double.infinity),
                          alignment: Alignment.center,
                          child: Text(
                            'Thêm',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}