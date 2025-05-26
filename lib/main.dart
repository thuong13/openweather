import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Thêm import này
import 'package:open_weather/widgets/home_screen.dart';
import 'package:open_weather/widgets/login.dart';
import 'package:open_weather/widgets/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo dữ liệu locale cho tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Ẩn nhãn debug
      title: 'Ứng dụng Chất lượng Không khí',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Màu chủ đạo
      ),
      initialRoute: '/', // Màn hình khởi động là HomeScreen
      routes: {
        '/': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) =>  RegisterScreen(),
      },
    );
  }
}