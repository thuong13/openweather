import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_history.dart';
import 'history_chart.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await DatabaseHistory.instance.getAllHistory();
    setState(() {
      _history = data;
    });
  }

  Future<void> _clearHistory() async {
    await DatabaseHistory.instance.clearAllHistory();
    setState(() {
      _history = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa toàn bộ lịch sử!')),
    );
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

  String _formatDate(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử AQI'),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
      ),
      body: _history.isEmpty
          ? Center(
        child: Text(
          'Không có dữ liệu lịch sử',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          // Tiêu đề
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Biểu đồ Lịch sử AQI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Biểu đồ
          Container(
            height: 300,
            child: AqiChart(history: _history),
          ),
          // Danh sách lịch sử
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAqiColor(item['aqi']),
                          child: Text(
                            item['aqi'].toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          item['city'] ?? 'Không xác định',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              'Ngày: ${_formatDate(item['timestamp'])}',
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.thermostat, size: 16, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text(
                                  'Nhiệt độ: ${item['temperature']?.toStringAsFixed(0) ?? 'N/A'}°C',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.water_drop, size: 16, color: Colors.blueAccent),
                                SizedBox(width: 4),
                                Text(
                                  'Độ ẩm: ${item['humidity']?.toString() ?? 'N/A'}%',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.air, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Gió: ${item['windSpeed']?.toStringAsFixed(1) ?? 'N/A'} km/h',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          'PM2.5: ${item['pm25'] ?? 'N/A'} µg/m³',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Nút xóa lịch sử
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _clearHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Xóa lịch sử',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}