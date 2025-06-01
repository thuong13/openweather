import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_weather/widgets/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/theme_language_provider.dart';
import '../widgets/register.dart';
import '../widgets/search_widgets.dart';
import '../models/air_quality_data.dart';
import '../services/api.dart';
import 'login.dart';
import 'detail_screen.dart';
import 'add_city_screen.dart';
import 'location_picker_screen.dart';
import '../database/database_helper.dart';
import '../database/database_history.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _addedCities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  final AirQualityService _airQualityService = AirQualityService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userInfo;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  Timer? _updateTimer;
  DateTime? _lastUpdateTime;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    print('HomeScreen: initState called');
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _checkLoginStatus();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('HomeScreen: AppLifecycleState changed to $state');
    if (state == AppLifecycleState.resumed) {
      _updateCitiesDataIfNeeded();
    }
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      String? email = prefs.getString('userEmail');
      if (email != null) {
        final userInfo = await _dbHelper.getUserInfo(email);
        setState(() {
          _isLoggedIn = isLoggedIn;
          _userInfo = userInfo;
        });
        await _restoreData();
      }
    } else {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _addedCities = [];
        _filteredCities = [];
      });
      await _clearData();
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_isLoggedIn) {
      await _saveData();
      await DatabaseHistory.instance
          .backupDataToSharedPreferences(_userInfo?['email'] ?? '');
      await DatabaseHistory.instance.clearAllLocalData();
      setState(() {
        _addedCities = [];
        _filteredCities = [];
      });
    }

    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userEmail');
    setState(() {
      _isLoggedIn = false;
      _userInfo = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đăng xuất thành công!',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('addedCities');
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('addedCities', jsonEncode(_addedCities));
  }

  Future<void> _updateCitiesData() async {
    if (_addedCities.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> updatedCities = [];
    for (var cityData in _addedCities) {
      try {
        final airQualityData = await _airQualityService.fetchAirQuality(
          cityData['lat'],
          cityData['lon'],
          cityData['city'],
        );
        updatedCities.add({
          'city': cityData['city'],
          'airQualityData': airQualityData,
          'lat': cityData['lat'],
          'lon': cityData['lon'],
        });
      } catch (e) {
        print('Error updating data for ${cityData['city']}: $e');
        updatedCities.add(cityData);
      }
    }

    setState(() {
      _addedCities = updatedCities;
      _filteredCities = List.from(_addedCities);
      _isLoading = false;
      _lastUpdateTime = DateTime.now();
    });
    await _saveData();
  }

  Future<void> _updateCitiesDataIfNeeded() async {
    if (_lastUpdateTime == null ||
        DateTime.now().difference(_lastUpdateTime!).inMinutes >= 1) {
      await _updateCitiesData();
    }
  }

  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateCitiesData();
    });
  }

  Future<void> _restoreData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final citiesJson = prefs.getString('addedCities');
    if (citiesJson != null) {
      final List<dynamic> citiesList = jsonDecode(citiesJson);
      setState(() {
        _addedCities = citiesList.map((city) {
          return {
            'city': city['city'],
            'airQualityData': AirQualityData(
              city: city['airQualityData']['city'],
              aqi: city['airQualityData']['aqi'],
              pm2_5: city['airQualityData']['pm2_5'].toDouble(),
              pm10: city['airQualityData']['pm10'].toDouble(),
              co: city['airQualityData']['co'].toDouble(),
              so2: city['airQualityData']['so2'].toDouble(),
              no2: city['airQualityData']['no2'].toDouble(),
              o3: city['airQualityData']['o3'].toDouble(),
              temperature: city['airQualityData']['temperature'].toDouble(),
              humidity: city['airQualityData']['humidity'].toDouble(),
              windSpeed: city['airQualityData']['windSpeed'].toDouble(),
              windDirection: city['airQualityData']['windDirection'].toDouble(),
              weatherIcon: city['airQualityData']['weatherIcon'],
            ),
            'lat': city['lat'].toDouble(),
            'lon': city['lon'].toDouble(),
          };
        }).toList();
        _filteredCities = List.from(_addedCities);
      });
    }

    await DatabaseHistory.instance
        .restoreDataFromSharedPreferences(_userInfo?['email'] ?? '');
    _updateCitiesData();
  }

  Future<void> _fetchInitialCity() async {
    try {
      final coords = await _airQualityService.getCoordinates('Hà Nội');
      if (coords['lat'] == null || coords['lon'] == null) {
        throw Exception('Tọa độ không hợp lệ cho Hà Nội');
      }
      final airQualityData = await _airQualityService.fetchAirQuality(
        coords['lat']!,
        coords['lon']!,
        'Hà Nội',
      );
      setState(() {
        _addedCities.add({
          'city': 'Hà Nội',
          'airQualityData': airQualityData,
          'lat': coords['lat'],
          'lon': coords['lon'],
        });
        _filteredCities = List.from(_addedCities);
        _listKey.currentState?.insertItem(_addedCities.length - 1);
      });
      await _saveData();
    } catch (e) {
      print('Error fetching initial city: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi tải dữ liệu ban đầu: $e',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 16,
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

  void _onSearch(List<String> queryList) {
    final query = queryList.isNotEmpty ? queryList[0].toLowerCase() : '';
    setState(() {
      _searchMessage = null;
      if (query.isEmpty || _addedCities.isEmpty) {
        _filteredCities = List.from(_addedCities);
      } else {
        _filteredCities = _addedCities
            .where((city) => city['city'].toLowerCase().contains(query))
            .toList();
        if (_filteredCities.isEmpty) {
          _searchMessage = 'Không có thành phố này trong danh sách';
        }
      }
    });
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
        return Colors.purple.withOpacity(0.15);
      case 4:
        return Colors.red.withOpacity(0.15);
      case 3:
        return Colors.orange.withOpacity(0.15);
      case 2:
        return Colors.amber.withOpacity(0.15);
      case 1:
      default:
        return Colors.green.withOpacity(0.15);
    }
  }

  IconData _getAqiIcon(int aqi) {
    switch (aqi) {
      case 5:
        return Icons.warning_amber;
      case 4:
        return Icons.cloud_circle;
      case 3:
        return Icons.cloud;
      case 2:
        return Icons.wb_cloudy;
      case 1:
      default:
        return Icons.wb_sunny;
    }
  }

  void _showUserInfoMenu(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Theme.of(context).cardColor,
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 36,
                    color: themeProvider.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thông tin tài khoản',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: Icon(
                  Icons.person,
                  color: themeProvider.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  size: 24,
                ),
                title: Text(
                  'Họ tên',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  _userInfo?['name'] ?? 'Chưa cập nhật',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: Icon(
                  Icons.email,
                  color: themeProvider.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  size: 24,
                ),
                title: Text(
                  'Email',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  _userInfo?['email'] ?? 'Chưa cập nhật',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  void _removeCity(int index) {
    if (index < 0 || index >= _addedCities.length) return;

    final removedCity = _addedCities[index];
    String cityName = removedCity['city'];

    _listKey.currentState?.removeItem(
      index,
          (context, animation) => _buildCityCard(removedCity, animation, index),
      duration: const Duration(milliseconds: 300),
    );

    setState(() {
      _addedCities.removeAt(index);
      _filteredCities = List.from(_addedCities);
      _searchMessage = null; // Đặt lại thông báo tìm kiếm sau khi xóa
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã xóa $cityName khỏi danh sách!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _saveData();
  }

  Widget _buildCityCard(Map<String, dynamic> cityData, Animation<double> animation, int index) {
    final airQualityData = cityData['airQualityData'] as AirQualityData;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: 0.0,
        child: Slidable(
          key: Key(cityData['city']),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.25,
            dismissible: DismissiblePane(
              onDismissed: () {
                _removeCity(index);
              },
              dismissThreshold: 0.9,
            ),
            children: [
              SlidableAction(
                onPressed: (context) {
                  _removeCity(index);
                },
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ],
          ),
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: themeProvider.isDarkMode ? Colors.grey[800] : Theme.of(context).cardColor,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeProvider.isDarkMode
                        ? Colors.grey[800]!
                        : Theme.of(context).cardColor,
                    _getAqiBackgroundColor(airQualityData.aqi),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getAqiColor(airQualityData.aqi).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                leading: Icon(
                  _getAqiIcon(airQualityData.aqi),
                  color: _getAqiColor(airQualityData.aqi),
                  size: 48,
                ),
                title: Text(
                  cityData['city'],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  'AQI: ${airQualityData.aqi}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _getAqiColor(airQualityData.aqi),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
                  size: 20,
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        airQualityData: airQualityData,
                        lat: cityData['lat'],
                        lon: cityData['lon'],
                      ),
                    ),
                  );
                  if (result == true) {
                    _updateCitiesData();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen: build called');
    final themeProvider = Provider.of<ThemeProvider>(context);

    List<String> cityNames = _addedCities.map((city) => city['city'] as String).toList();

    final bodyGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.blueGrey[900]!, Colors.blueGrey[700]!, Theme.of(context).scaffoldBackgroundColor]
          : [Colors.blue.shade300, Colors.blue.shade100, Theme.of(context).scaffoldBackgroundColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.5, 1.0],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode
            ? Colors.black.withOpacity(0.05)
            : Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.05) ?? Colors.white.withOpacity(0.05),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider.isDarkMode
                    ? Colors.grey[800]!.withOpacity(0.2)
                    : Theme.of(context).cardColor.withOpacity(0.2),
                border: Border.all(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Theme.of(context).cardColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Image.asset('images/logo.png', height: 36, width: 36),
            ),
            const SizedBox(width: 8),
            Text(
              'Air Quality',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => _showUserInfoMenu(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[800]!.withOpacity(0.2)
                        : Theme.of(context).cardColor.withOpacity(0.2),
                    border: Border.all(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[800]!.withOpacity(0.5)
                          : Theme.of(context).cardColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.account_circle,
                    size: 36,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: Icon(
                Icons.login,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.person_add,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: bodyGradient,
            ),
            child: Column(
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SearchWidget(
                    onSearch: _onSearch,
                    cities: cityNames,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _addedCities.isEmpty
                      ? Center(
                    child: Text(
                      'Chưa có thành phố nào được thêm.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : _searchMessage != null
                      ? Center(
                    child: Text(
                      _searchMessage!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: _filteredCities.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      itemBuilder: (context, index, animation) {
                        if (index >= _filteredCities.length) {
                          return const SizedBox.shrink();
                        }
                        return _buildCityCard(_filteredCities[index], animation, index);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              print('HomeScreen: Opening LocationPickerScreen');
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationPickerScreen()),
              );
              print('HomeScreen: Received result from LocationPickerScreen: $result');
              if (result != null) {
                if (result is Map<String, dynamic> &&
                    result.containsKey('city') &&
                    result.containsKey('airQualityData') &&
                    result.containsKey('lat') &&
                    result.containsKey('lon')) {
                  if (_addedCities.any((city) => city['city'].toLowerCase() == result['city'].toLowerCase())) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${result['city']} đã có trong danh sách!',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          backgroundColor: Colors.orangeAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                    return;
                  }
                  setState(() {
                    _addedCities.add(result);
                    _filteredCities = List.from(_addedCities);
                    _listKey.currentState?.insertItem(_addedCities.length - 1);
                  });
                  await _saveData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã thêm ${result['city']} vào danh sách! AQI: ${result['airQualityData'].aqi}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        backgroundColor: _getAqiColor(result['airQualityData'].aqi),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dữ liệu trả về không đúng định dạng!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 16,
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
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeProvider.isDarkMode
                      ? [Colors.green.shade800, Colors.green.shade600]
                      : [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.my_location,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                size: 28,
              ),
            ),
            heroTag: 'locationButton',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              print('HomeScreen: Opening AddCityScreen');
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCityScreen()),
              );
              print('HomeScreen: Received result from AddCityScreen: $result');
              if (result != null) {
                if (result is Map<String, dynamic> &&
                    result.containsKey('city') &&
                    result.containsKey('airQualityData') &&
                    result.containsKey('lat') &&
                    result.containsKey('lon')) {
                  if (_addedCities.any((city) => city['city'].toLowerCase() == result['city'].toLowerCase())) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${result['city']} đã có trong danh sách!',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          backgroundColor: Colors.orangeAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                    return;
                  }
                  setState(() {
                    _addedCities.add(result);
                    _filteredCities = List.from(_addedCities);
                    _listKey.currentState?.insertItem(_addedCities.length - 1);
                  });
                  await _saveData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã thêm ${result['city']} vào danh sách! AQI: ${result['airQualityData'].aqi}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        backgroundColor: _getAqiColor(result['airQualityData'].aqi),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dữ liệu trả về không đúng định dạng!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 16,
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
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeProvider.isDarkMode
                      ? [Colors.blue.shade800, Colors.blue.shade600]
                      : [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.add,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                size: 28,
              ),
            ),
            heroTag: 'addButton',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}