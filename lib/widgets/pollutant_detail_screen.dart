import 'package:flutter/material.dart';

class PollutantDetailScreen extends StatelessWidget {
  final String title;
  final double value;
  final String unit;

  const PollutantDetailScreen({
    required this.title,
    required this.value,
    required this.unit,
    Key? key,
  }) : super(key: key);

  String _getPollutantLevel() {
    switch (title) {
      case 'PM2.5':
        if (value <= 12) return 'Tốt';
        if (value <= 35.4) return 'Trung bình';
        if (value <= 55.4) return 'Không lành mạnh cho nhóm nhạy cảm';
        if (value <= 150.4) return 'Không lành mạnh';
        if (value <= 250.4) return 'Rất không lành mạnh';
        return 'Nguy hiểm';
      case 'PM10':
        if (value <= 54) return 'Tốt';
        if (value <= 154) return 'Trung bình';
        if (value <= 254) return 'Không lành mạnh cho nhóm nhạy cảm';
        if (value <= 354) return 'Không lành mạnh';
        if (value <= 424) return 'Rất không lành mạnh';
        return 'Nguy hiểm';
      case 'CO':
        if (value <= 4400) return 'Tốt';
        if (value <= 9400) return 'Trung bình';
        if (value <= 12400) return 'Không lành mạnh cho nhóm nhạy cảm';
        if (value <= 15400) return 'Không lành mạnh';
        if (value <= 30400) return 'Rất không lành mạnh';
        return 'Nguy hiểm';
      case 'SO₂':
        if (value <= 35) return 'Tốt';
        if (value <= 75) return 'Trung bình';
        if (value <= 185) return 'Không lành mạnh cho nhóm nhạy cảm';
        if (value <= 304) return 'Không lành mạnh';
        if (value <= 604) return 'Rất không lành mạnh';
        return 'Nguy hiểm';
      case 'NO₂':
        if (value <= 53) return 'Tốt';
        if (value <= 100) return 'Trung bình';
        if (value <= 360) return 'Không lành mạnh cho nhóm nhạy cảm';
        if (value <= 649) return 'Không lành mạnh';
        if (value <= 1249) return 'Rất không lành mạnh';
        return 'Nguy hiểm';
      case 'O₃':
        if (value <= 100) return 'Tốt';
        if (value <= 168) return 'Trung bình';
        if (value <= 208) return 'Không lành mạnh cho nhóm nhạy cảm';
        if (value <= 748) return 'Không lành mạnh';
        if (value <= 1184) return 'Rất không lành mạnh';
        return 'Nguy hiểm';
      default:
        return 'Không xác định';
    }
  }

  Color _getLevelColor() {
    switch (_getPollutantLevel()) {
      case 'Tốt':
        return Colors.green[700]!; // Xanh lá đậm
      case 'Trung bình':
        return Colors.yellow[700]!; // Vàng đậm
      case 'Không lành mạnh cho nhóm nhạy cảm':
        return Colors.orange[700]!; // Cam đậm
      case 'Không lành mạnh':
        return Colors.red[700]!; // Đỏ đậm
      case 'Rất không lành mạnh':
        return Colors.purple[700]!; // Tím đậm
      case 'Nguy hiểm':
        return Colors.brown[700]!; // Nâu đậm
      default:
        return Colors.grey[600]!; // Xám trung tính
    }
  }

  IconData _getPollutantIcon() {
    switch (title) {
      case 'PM2.5':
        return Icons.opacity;
      case 'PM10':
        return Icons.opacity_outlined;
      case 'CO':
        return Icons.local_fire_department;
      case 'SO₂':
        return Icons.cloud;
      case 'NO₂':
        return Icons.cloud;
      case 'O₃':
        return Icons.wb_sunny;
      default:
        return Icons.info;
    }
  }

  String _getPollutantDescription() {
    switch (title) {
      case 'PM2.5':
        return 'Bụi PM2.5 là vật chất dạng hạt rất nhỏ trong không khí có đường kính bằng hoặc nhỏ hơn 2.5 micromet. Chúng có thể xâm nhập sâu vào phổi và máu, gây ảnh hưởng nghiêm trọng đến sức khỏe. PM2.5 xuất hiện do ô nhiễm không khí từ khói, bụi, và các chất gây ô nhiễm khác.';
      case 'PM10':
        return 'Bụi PM10 là các hạt bụi có đường kính nhỏ hơn hoặc bằng 10 micromet. Chúng thường xuất phát từ bụi đường, xây dựng, và các hoạt động công nghiệp. PM10 có thể gây kích ứng đường hô hấp và ảnh hưởng đến phổi.';
      case 'CO':
        return 'Carbon Monoxide (CO) là khí không màu, không mùi, được sinh ra từ quá trình đốt cháy không hoàn toàn nhiên liệu hóa thạch. Nó có thể gây ngộ độc nếu tích tụ trong không khí trong nhà hoặc môi trường kín.';
      case 'SO₂':
        return 'Sulfur Dioxide (SO₂) là khí độc hại phát sinh từ hoạt động đốt nhiên liệu chứa lưu huỳnh, như than đá và dầu. Nó gây kích ứng đường hô hấp và góp phần tạo thành mưa axit.';
      case 'NO₂':
        return 'Nitrogen Dioxide (NO₂) là khí độc hại phát sinh từ khí thải xe cộ và các hoạt động công nghiệp. Nó gây kích ứng đường hô hấp và góp phần tạo thành sương mù quang hóa.';
      case 'O₃':
        return 'Ozone (O₃) ở tầng mặt đất là chất ô nhiễm hình thành từ phản ứng hóa học dưới ánh nắng mặt trời. Nó gây kích ứng phổi và ảnh hưởng đến hệ hô hấp.';
      default:
        return 'Không có thông tin mô tả cho chất này.';
    }
  }

  String _getHealthImpact() {
    switch (title) {
      case 'PM2.5':
        return 'Nó có thể làm tăng nguy cơ mắc các bệnh về phổi, tim mạch và gây kích ứng mắt, mũi, họng. Những người nhạy cảm như trẻ em, người già, và người có bệnh nền dễ bị ảnh hưởng hơn.';
      case 'PM10':
        return 'PM10 có thể gây kích ứng đường hô hấp, ho, khó thở, và làm nặng thêm các bệnh như hen suyễn hoặc viêm phổi, đặc biệt ở người nhạy cảm.';
      case 'CO':
        return 'CO ngăn cản máu vận chuyển oxy, dẫn đến nhức đầu, chóng mặt, buồn nôn, và trong trường hợp nặng có thể gây tử vong nếu không được xử lý kịp thời.';
      case 'SO₂':
        return 'SO₂ gây kích ứng mắt, mũi, họng, và đường hô hấp, đặc biệt nguy hiểm cho người bị bệnh phổi hoặc hen suyễn khi tiếp xúc lâu.';
      case 'NO₂':
        return 'NO₂ gây kích ứng đường hô hấp, tăng nguy cơ viêm phổi và hen suyễn, đặc biệt ở trẻ em và người già.';
      case 'O₃':
        return 'O₃ gây kích ứng phổi, ho, đau ngực, và làm nặng thêm các bệnh hô hấp như hen suyễn.';
      default:
        return 'Không có thông tin về ảnh hưởng sức khỏe.';
    }
  }

  List<String> _getLongTermEffects() {
    switch (title) {
      case 'PM2.5':
        return [
          'Bệnh hô hấp mãn tính như viêm phổi, hen suyễn.',
          'Tăng nguy cơ đột quỵ và bệnh tim.',
          'Ảnh hưởng lâu dài đến chức năng phổi.',
        ];
      case 'PM10':
        return [
          'Gây tổn thương phổi mãn tính.',
          'Tăng nguy cơ viêm phế quản và các bệnh hô hấp khác.',
          'Ảnh hưởng đến hệ hô hấp của trẻ em.',
        ];
      case 'CO':
        return [
          'Tổn thương não và hệ thần kinh do thiếu oxy kéo dài.',
          'Tăng nguy cơ bệnh tim mạch.',
          'Hậu quả lâu dài nếu tiếp xúc lặp lại.',
        ];
      case 'SO₂':
        return [
          'Gây viêm phổi hoặc hen suyễn mãn tính.',
          'Ảnh hưởng đến chức năng phổi lâu dài.',
          'Tăng nguy cơ bệnh tim mạch do ô nhiễm kéo dài.',
        ];
      case 'NO₂':
        return [
          'Tăng nguy cơ bệnh phổi mãn tính.',
          'Ảnh hưởng đến sự phát triển phổi ở trẻ em.',
          'Tăng nguy cơ bệnh tim mạch.',
        ];
      case 'O₃':
        return [
          'Giảm chức năng phổi lâu dài.',
          'Tăng nguy cơ hen suyễn và bệnh hô hấp mãn tính.',
          'Ảnh hưởng đến hệ tim mạch.',
        ];
      default:
        return ['Không có thông tin về ảnh hưởng lâu dài.'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor();
    final icon = _getPollutantIcon();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [levelColor, levelColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [levelColor.withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: levelColor, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.grey, thickness: 1, height: 30),
                  const Text(
                    'Thông tin chi tiết',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getPollutantDescription(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify, // Căn đều hai bên
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tác động đến sức khỏe',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getHealthImpact(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify, // Căn đều hai bên
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ảnh hưởng lâu dài',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._getLongTermEffects().map((effect) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.black54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              effect,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify, // Căn đều hai bên
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}