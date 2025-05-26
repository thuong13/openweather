import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'home_screen.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _obscurePassword = true;
  List<Map<String, dynamic>> _accountSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadAccountSuggestions();
  }

  Future<void> _loadAccountSuggestions() async {
    final suggestions = await _dbHelper.getAccountSuggestions();
    setState(() {
      _accountSuggestions = suggestions;
    });
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin!', true);
      return;
    }

    bool success = await _dbHelper.loginUser(email, password);
    if (success) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);

      _showMessage('Đăng nhập thành công!', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      _showMessage('Sai email hoặc mật khẩu!', true);
    }
  }

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeSuggestion(String email) async {
    await _dbHelper.removeAccountSuggestion(email);
    await _loadAccountSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0, // Loại bỏ khoảng cách mặc định giữa leading và title
        leadingWidth: 40, // Giảm chiều rộng của leading để sát hơn
        title: Row(
          children: [
            SizedBox(width: 4), // Điều chỉnh khoảng cách nhỏ giữa icon và chữ
            Text(
              'Đăng nhập',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.lightBlue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.lightBlue.shade300,
                      child: Icon(Icons.lock, size: 55, color: Colors.white),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 35),
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text == '') return _accountSuggestions;
                        return _accountSuggestions.where((account) =>
                            account['email'].toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      displayStringForOption: (option) => option['email'],
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        _emailController.text = controller.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 16),
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.lightBlue.shade600),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.lightBlue.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.lightBlue.shade600, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.lightBlue.shade200),
                            ),
                          ),
                          onChanged: (value) {
                            _emailController.text = value;
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 10.0,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.lightBlue.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              constraints: BoxConstraints(maxHeight: 240),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.lightBlue.shade100),
                                itemBuilder: (context, index) {
                                  final account = options.elementAt(index);
                                  return ListTile(
                                    leading: Icon(Icons.person, color: Colors.lightBlue.shade600),
                                    title: Text(
                                      account['email'],
                                      style: TextStyle(color: Colors.blue.shade700, fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      account['name'] ?? 'Chưa có tên',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.close, color: Colors.red.shade300),
                                      onPressed: () => _removeSuggestion(account['email']),
                                    ),
                                    onTap: () => onSelected(account),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (selection) {
                        _emailController.text = selection['email'];
                      },
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 16),
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.lightBlue.shade600),
                        suffixIcon: IconButton(
                          icon: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              key: ValueKey(_obscurePassword),
                              color: Colors.lightBlue.shade600,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.lightBlue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.lightBlue.shade600, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.lightBlue.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    ElevatedButton.icon(
                      onPressed: _login,
                      icon: Icon(Icons.login, color: Colors.white, size: 24),
                      label: Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.blueGrey.withOpacity(0.3),
                        backgroundColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.lightBlue.shade700;
                            } else if (states.contains(MaterialState.hovered)) {
                              return Colors.lightBlue.shade500;
                            }
                            return Colors.lightBlue.shade600;
                          },
                        ),
                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                      ).copyWith(
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        );
                      },
                      icon: Icon(Icons.person_add_alt, color: Colors.lightBlue.shade600, size: 20),
                      label: Text(
                        'Chưa có tài khoản? Đăng ký ngay',
                        style: TextStyle(
                          color: Colors.lightBlue.shade600,
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
          ),
        ),
      ),
    );
  }
}