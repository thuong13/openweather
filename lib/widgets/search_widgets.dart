import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme_language_provider.dart';

class SearchWidget extends StatefulWidget {
  final Function(List<String>) onSearch; // Callback để trả về truy vấn tìm kiếm
  final List<String> cities; // Danh sách thành phố được truyền từ HomeScreen

  const SearchWidget({
    Key? key,
    required this.onSearch,
    required this.cities,
  }) : super(key: key);

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Xử lý tìm kiếm
  void _searchCities(String query) {
    // Gọi callback để truyền truy vấn tìm kiếm về HomeScreen
    widget.onSearch([query.trim()]); // Truyền truy vấn dưới dạng danh sách 1 phần tử
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black26 : Colors.black12,
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập tên thành phố...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
                border: InputBorder.none,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  onPressed: () {
                    _controller.clear();
                    _searchCities(''); // Truyền truy vấn rỗng để hiển thị toàn bộ danh sách
                    setState(() {}); // Cập nhật UI để ẩn nút clear
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                _searchCities(value); // Tìm kiếm theo thời gian thực
                setState(() {}); // Cập nhật UI để hiển thị/hide nút clear
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                _searchCities(value); // Gửi truy vấn khi nhấn Enter
                _focusNode.unfocus(); // Ẩn bàn phím sau khi tìm kiếm
              },
            ),
          ),
        ],
      ),
    );
  }
}