import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AqiChart extends StatefulWidget {
  final List<Map<String, dynamic>> history;

  const AqiChart({required this.history, Key? key}) : super(key: key);

  @override
  _AqiChartState createState() => _AqiChartState();
}

class _AqiChartState extends State<AqiChart> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getAqiColor(int aqi) {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getAqiLevel(int aqi) {
    switch (aqi) {
      case 1:
        return "Tốt";
      case 2:
        return "Khá";
      case 3:
        return "Trung bình";
      case 4:
        return "Kém";
      case 5:
        return "Rất kém";
      default:
        return "Không xác định";
    }
  }

  List<BarChartGroupData> _getBarGroups(bool isHourly) {
    return List.generate(widget.history.length, (index) {
      int aqi = widget.history[index]['aqi'] ?? 1;
      Color color = _getAqiColor(aqi);
      return BarChartGroupData(
        x: index,
        barsSpace: 8,
        barRods: [
          BarChartRodData(
            toY: aqi.toDouble(),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.6), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 14,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 5,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, bool isHourly) {
    int index = value.toInt();
    if (index < widget.history.length) {
      final timestamp = widget.history[index]['timestamp'];
      final date = DateTime.parse(timestamp);

      if (isHourly) {
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            DateFormat('HH:mm').format(date),
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${DateFormat.E('vi').format(date)}\n${DateFormat('dd/MM').format(date)}',
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 10,
        children: [
          _buildLegendItem(Colors.green, "Tốt"),
          _buildLegendItem(Colors.amber, "Khá"),
          _buildLegendItem(Colors.orange, "Trung bình"),
          _buildLegendItem(Colors.red, "Kém"),
          _buildLegendItem(Colors.purple, "Rất kém"),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBarChart(bool isHourly) {
    int total = widget.history.length;
    double step = isHourly ? 2 : 1;

    if (total > 15) step = isHourly ? 4 : 3;
    else if (total > 10) step = isHourly ? 3 : 2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: total * 50.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
          child: BarChart(
            BarChartData(
              barGroups: _getBarGroups(isHourly),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              alignment: BarChartAlignment.spaceAround,
              maxY: 6.5, // Giữ maxY để tạo không gian phía trên
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 1 && value.toInt() <= 5) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: 2.0, // Giảm padding bên phải để nhãn sát lề hơn nữa
                            top: value.toInt() == 5 ? 6.0 : 0.0, // Đẩy nhãn "5" xuống thêm
                          ),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 15, // Giảm không gian dự trữ để nhãn sát lề trái nhất có thể
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: step,
                    getTitlesWidget: (value, meta) => _getBottomTitles(value, isHourly),
                    reservedSize: 50,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade900.withOpacity(0.9),
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 10,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = widget.history[group.x];
                    final date = DateTime.parse(data['timestamp']);
                    final dateStr = DateFormat('HH:mm dd/MM/yyyy').format(date);
                    final aqi = rod.toY.toInt();
                    final level = _getAqiLevel(aqi);

                    return BarTooltipItem(
                      '$dateStr\nAQI: $aqi\nMức: $level',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    );
                  },
                ),
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: ' Ngày'),
            Tab(text: ' Giờ'),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegend(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBarChart(false),
              _buildBarChart(true),
            ],
          ),
        ),
      ],
    );
  }
}