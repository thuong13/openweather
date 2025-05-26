import 'package:flutter/material.dart';
import '../services/api.dart';

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
    return Scaffold(
      extendBodyBehindAppBar: true, // Cho phép nền gradient hiển thị phía sau AppBar
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
        ), // Luôn hiển thị tiêu đề
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
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Minh họa nhỏ phía trên
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    child: Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  // TextField với hiệu ứng bóng
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
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
                          color: Colors.blue.shade300,
                          fontStyle: FontStyle.italic,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.blue.shade700,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Nút "Thêm" với gradient và animation
                  _isLoading
                      ? Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      color: Colors.blue.shade700,
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
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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