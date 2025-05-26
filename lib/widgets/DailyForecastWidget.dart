import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/daily.dart';

class DailyForecastWidget extends StatefulWidget {
  final List<ForecastDaily> forecasts;

  const DailyForecastWidget({required this.forecasts, Key? key}) : super(key: key);

  @override
  _DailyForecastWidgetState createState() => _DailyForecastWidgetState();
}

class _DailyForecastWidgetState extends State<DailyForecastWidget>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  List<String> dayLabels = [];
  List<int> dayIndices = [];
  bool _isScrollingFromTab = false;

  @override
  void initState() {
    super.initState();
    _initializeDayLabels();
    _tabController = TabController(length: dayLabels.length, vsync: this);
    _scrollController.addListener(_updateCurrentDay);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDayLabels() {
    String? previousDayKey;
    for (int i = 0; i < widget.forecasts.length; i++) {
      final dayKey = DateFormat('yyyy-MM-dd').format(widget.forecasts[i].date);
      if (dayKey != previousDayKey) {
        final day = DateTime.parse(dayKey);
        final dayLabel = DateFormat('EEEE', 'vi_VN').format(day);
        dayLabels.add(dayLabel);
        dayIndices.add(i);
        previousDayKey = dayKey;
      }
    }
  }

  void _updateCurrentDay() {
    if (_scrollController.hasClients && !_isScrollingFromTab) {
      final scrollOffset = _scrollController.offset;
      const itemWidth = 120.0; // Tăng width để dễ nhìn hơn
      final firstVisibleIndex = (scrollOffset / itemWidth).floor();

      for (int i = 0; i < dayIndices.length; i++) {
        if (firstVisibleIndex >= dayIndices[i] &&
            (i == dayIndices.length - 1 || firstVisibleIndex < dayIndices[i + 1])) {
          if (_tabController.index != i) {
            _tabController.animateTo(i);
          }
          break;
        }
      }
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      _isScrollingFromTab = true;
    });

    final targetIndex = dayIndices[_tabController.index];
    const itemWidth = 120.0;
    final targetOffset = targetIndex * itemWidth;

    _scrollController
        .animateTo(
      targetOffset,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      setState(() {
        _isScrollingFromTab = false;
      });
    });
  }

  Color _getAqiColor(int? aqi) {
    if (aqi == null) return Colors.grey;
    switch (aqi) {
      case 5:
        return Colors.purple;
      case 4:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.yellow;
      case 1:
      default:
        return Colors.green;
    }
  }

  IconData _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'rain':
        return Icons.umbrella;
      case 'clouds':
        return Icons.cloud;
      case 'clear':
        return Icons.wb_sunny;
      case 'partly cloudy':
      case 'overcast':
        return Icons.cloud_queue;
      default:
        return Icons.cloud;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forecasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, color: Colors.grey[600], size: 30),
            SizedBox(height: 10),
            Text(
              'Không có dữ liệu dự báo 5 ngày',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    // Tính ngày hiện tại (10:31 PM +07, Wednesday, May 14, 2025)
    final today = DateTime.now();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab điều hướng
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dayLabels.asMap().entries.map((entry) {
                final index = entry.key;
                final label = entry.value;
                return GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 24, bottom: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _tabController.index == index
                                ? Colors.blue[800]
                                : Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (_tabController.index == index)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            height: 2,
                            width: 20,
                            color: Colors.blue[800],
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 12),
        // Nội dung dự báo
        SizedBox(
          height: 190, // Tăng chiều cao để dễ nhìn hơn
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Row(
              children: widget.forecasts.asMap().entries.map((entry) {
                final index = entry.key;
                final forecast = entry.value;
                final isNewDay = dayIndices.contains(index);
                final forecastDayFormatted = DateFormat('yyyy-MM-dd').format(forecast.date);
                final isToday = forecastDayFormatted == todayFormatted;

                return Row(
                  children: [
                    if (isNewDay && index != 0)
                      Container(
                        width: 1,
                        height: 170,
                        color: Colors.grey[300],
                        margin: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    Container(
                      width: 120, // Tăng width để dễ nhìn hơn
                      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.blue[50] : Colors.white,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE', 'vi_VN').format(forecast.date),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.blue[800] : Colors.black87,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getAqiColor(forecast.aqi),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${forecast.aqi ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                _getWeatherIcon(forecast.weatherMain),
                                size: 26,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            '${forecast.tempMax.toStringAsFixed(0)}° / ${forecast.tempMin.toStringAsFixed(0)}°',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.air,
                                size: 16,
                                color: Colors.blueGrey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${forecast.windSpeed.toStringAsFixed(1)} km/h',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${forecast.humidity.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}