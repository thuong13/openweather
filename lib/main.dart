import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_weather/widgets/home_screen.dart';
import 'package:open_weather/widgets/login.dart';
import 'package:open_weather/widgets/register.dart';
import 'package:open_weather/widgets/settings_screen.dart';
import 'package:provider/provider.dart';
import 'models/theme_language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Ứng dụng Chất lượng Không khí',
            theme: themeProvider.getTheme(),
            initialRoute: '/',
            routes: {
              '/': (context) => HomeScreen(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/settings': (context) => SettingsScreen(), // Thêm route cho SettingsScreen
            },
          );
        },
      ),
    );
  }
}