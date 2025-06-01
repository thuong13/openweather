import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/theme_language_provider.dart'; // Đảm bảo import ThemeProvider
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _obscurePassword = true;

  Future<void> _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String address = _addressController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin bắt buộc!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool success = await _dbHelper.registerUser(email, password, name, phone, address);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thành công!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email đã tồn tại! Vui lòng sử dụng email khác.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy ThemeProvider để xác định chế độ sáng/tối
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Gradient tùy chỉnh theo theme
    final appBarGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!] // Dark Mode
          : [Colors.lightBlue.shade200, Colors.lightBlue.shade100], // Light Mode
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final bodyGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.blueGrey[900]!, Colors.grey[850]!] // Dark Mode
          : [Colors.lightBlue.shade100, Colors.white], // Light Mode
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final cardGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.grey[800]!, Colors.blueGrey[800]!.withOpacity(0.2)] // Dark Mode
          : [Colors.white, Colors.lightBlue.shade50], // Light Mode
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final buttonGradient = LinearGradient(
      colors: themeProvider.isDarkMode
          ? [Colors.lightBlue.shade800, Colors.lightBlue.shade700] // Dark Mode
          : [Colors.lightBlue.shade600, Colors.lightBlue.shade400], // Light Mode
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Colors.transparent, // Để gradient hiển thị đúng
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 40,
        title: Row(
          children: [
            SizedBox(width: 4),
            Text(
              'Đăng ký',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.white, // Giữ màu trắng cho AppBar
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: appBarGradient,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: themeProvider.isDarkMode ? Colors.white : Colors.white), // Giữ màu trắng
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: bodyGradient,
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.blueGrey.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: themeProvider.isDarkMode
                      ? Colors.blueGrey[800] // Dark Mode
                      : Colors.lightBlue.shade300, // Light Mode
                  child: Icon(Icons.person_add, size: 55, color: Colors.white),
                ),
                const SizedBox(height: 25),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: themeProvider.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.blueGrey.withOpacity(0.1),
                  color: Colors.transparent, // Để gradient hiển thị
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: cardGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đăng ký tài khoản',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.isDarkMode
                                ? Colors.lightBlue.shade100 // Light blue nhạt cho Dark Mode
                                : Colors.blue.shade700, // Blue đậm cho Light Mode
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 25),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade200
                                  : Colors.lightBlue.shade600,
                            ),
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade100
                                  : Colors.blue.shade700,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: themeProvider.isDarkMode
                                ? Colors.grey[800]!.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.lightBlue.shade200
                                    : Colors.lightBlue.shade600,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade200
                                  : Colors.lightBlue.shade600,
                            ),
                            labelText: 'Mật khẩu',
                            labelStyle: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade100
                                  : Colors.blue.shade700,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: themeProvider.isDarkMode
                                ? Colors.grey[800]!.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.lightBlue.shade200
                                    : Colors.lightBlue.shade600,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: themeProvider.isDarkMode
                                    ? Colors.lightBlue.shade200
                                    : Colors.lightBlue.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person,
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade200
                                  : Colors.lightBlue.shade600,
                            ),
                            labelText: 'Họ tên',
                            labelStyle: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade100
                                  : Colors.blue.shade700,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: themeProvider.isDarkMode
                                ? Colors.grey[800]!.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.lightBlue.shade200
                                    : Colors.lightBlue.shade600,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.phone,
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade200
                                  : Colors.lightBlue.shade600,
                            ),
                            labelText: 'Số điện thoại (không bắt buộc)',
                            labelStyle: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade100
                                  : Colors.blue.shade700,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: themeProvider.isDarkMode
                                ? Colors.grey[800]!.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.lightBlue.shade200
                                    : Colors.lightBlue.shade600,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade200
                                  : Colors.lightBlue.shade600,
                            ),
                            labelText: 'Địa chỉ (không bắt buộc)',
                            labelStyle: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade100
                                  : Colors.blue.shade700,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: themeProvider.isDarkMode
                                ? Colors.grey[800]!.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.lightBlue.shade200
                                    : Colors.lightBlue.shade600,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.blueGrey[800]!
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: themeProvider.isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.blueGrey.withOpacity(0.3),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: buttonGradient,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              constraints: BoxConstraints(minWidth: 200, minHeight: 60),
                              alignment: Alignment.center,
                              child: Text(
                                'Đăng ký',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text(
                            'Đã có tài khoản? Đăng nhập ngay',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.lightBlue.shade200
                                  : Colors.lightBlue.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}