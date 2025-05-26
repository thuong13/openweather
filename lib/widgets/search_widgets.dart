import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  final Function(String) onSearch;

  const SearchWidget({Key? key, required this.onSearch}) : super(key: key);

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Nhập tên thành phố...',
                border: InputBorder.none,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _controller.clear();
                    setState(() {}); // Cập nhật UI khi xóa dữ liệu
                  },
                )
                    : null,
              ),
              onChanged: (value) => setState(() {}), // Cập nhật để hiển thị nút clear
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onSearch(value.trim());
                  _focusNode.unfocus(); // Ẩn bàn phím sau khi tìm kiếm
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
