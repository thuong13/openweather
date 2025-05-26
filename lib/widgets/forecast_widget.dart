import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/forecast.dart';

class ForecastWidget extends StatefulWidget {
  final List<Forecast> forecasts;

  const ForecastWidget({required this.forecasts, Key? key}) : super(key: key);

  @override
  _ForecastWidgetState createState() => _ForecastWidgetState();
}

class _ForecastWidgetState extends State<ForecastWidget>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  List<String> dayLabels = [];
  List<int> dayIndices = [];
  List<Forecast> filteredForecasts = [];
  bool _isScrollingFromTab = false;

  @override
  void initState() {
    super.initState();
    _filterForecastsForThreeDays();
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

  void _filterForecastsForThreeDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final dayAfterTomorrow = today.add(Duration(days: 2));

    filteredForecasts = widget.forecasts.where((forecast) {
      final forecastDate = DateTime(
        forecast.date.year,
        forecast.date.month,
        forecast.date.day,
      );
      return forecastDate.isAtSameMomentAs(today) ||
          forecastDate.isAtSameMomentAs(tomorrow) ||
          forecastDate.isAtSameMomentAs(dayAfterTomorrow);
    }).toList();
  }

  void _initializeDayLabels() {
    String? previousDayKey;
    for (int i = 0; i < filteredForecasts.length; i++) {
      final dayKey = DateFormat('yyyy-MM-dd').format(filteredForecasts[i].date);
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
      const itemWidth = 96.0;
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
    const itemWidth = 96.0;
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

  @override
  Widget build(BuildContext context) {
    if (filteredForecasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, color: Colors.grey[600], size: 30),
            SizedBox(height: 10),
            Text(
              'Không có dữ liệu dự báo',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    List<Color> dotColors = [];
    for (int i = 0; i < dayLabels.length; i++) {
      dotColors.add(i == 0 ? Colors.orange : Colors.red);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TabBar cố định sát lề trái, nhưng có thể cuộn ngang nếu tràn
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Row(
                  children: dayLabels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final label = entry.value;
                    return GestureDetector(
                      onTap: () {
                        _tabController.animateTo(index);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(right: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: dotColors[index],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _tabController.index == index
                                        ? Colors.black87
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: 3,
                              width: _tabController.index == index ? 40 : 0,
                              color: dotColors[index],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        // Phần dự báo cuộn ngang
        SizedBox(
          height: 180,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Row(
              children: filteredForecasts.asMap().entries.map((entry) {
                final index = entry.key;
                final forecast = entry.value;
                final aqiColor = _getAqiColor(forecast.aqi);
                String aqiRange = '';
                if (forecast.aqi == 1) {
                  aqiRange = '0-50';
                } else if (forecast.aqi == 2) {
                  aqiRange = '51-100';
                } else if (forecast.aqi == 3) {
                  aqiRange = '101-150';
                } else if (forecast.aqi == 4) {
                  aqiRange = '151-200';
                } else {
                  aqiRange = '201+';
                }

                bool isNewDay = dayIndices.contains(index);

                return Row(
                  children: [
                    if (isNewDay && index != 0)
                      Container(
                        width: 1,
                        height: 140,
                        color: Colors.grey[300],
                        margin: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    Container(
                      width: 80,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(forecast.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: aqiColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              aqiRange,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Image.network(
                            'http://openweathermap.org/img/wn/${forecast.weatherIcon}@2x.png',
                            width: 36,
                            height: 36,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.cloud,
                                size: 36,
                                color: Colors.blueGrey,
                              );
                            },
                          ),
                          SizedBox(height: 6),
                          Text(
                            '${forecast.temperature?.toStringAsFixed(0) ?? 'N/A'}°',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.rotate(
                                angle: (forecast.windDirection * 3.14 / 180),
                                child: Icon(
                                  Icons.air,
                                  size: 14,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${forecast.windSpeed.toStringAsFixed(1)} km/h',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
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