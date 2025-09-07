import 'package:flutter/material.dart';
import '../widgets/header_box_widget.dart';
import '../config/box_configs.dart';

/// نمونه صفحه برای نمایش استفاده از HeaderBoxWidget
class HeaderBoxExampleScreen extends StatelessWidget {
  const HeaderBoxExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نمونه باکس‌های عناوین'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF1EFEC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان
            const Text(
              'باکس‌های عناوین تکی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 16),

            // نمونه باکس‌های تکی
            Row(
              children: [
                Expanded(
                  child: HeaderBoxWidget(
                    title: 'نوع توقف',
                    height: 50,
                    onTap: () => _showSnackBar(context, 'نوع توقف کلیک شد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HeaderBoxWidget(
                    title: 'واقعی',
                    height: 50,
                    onTap: () => _showSnackBar(context, 'واقعی کلیک شد'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: HeaderBoxWidget(
                    title: 'برنامه',
                    height: 50,
                    onTap: () => _showSnackBar(context, 'برنامه کلیک شد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HeaderBoxWidget(
                    title: 'انحراف',
                    height: 50,
                    onTap: () => _showSnackBar(context, 'انحراف کلیک شد'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // عنوان ردیف
            const Text(
              'ردیف عناوین (مشابه صفحه توقفات)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 16),

            // نمونه ردیف عناوین
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const StopsHeaderRowWidget(),
            ),

            const SizedBox(height: 32),

            // کانفیگ سفارشی
            const Text(
              'کانفیگ سفارشی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 16),

            // نمونه با کانفیگ سفارشی
            Row(
              children: [
                Expanded(
                  child: HeaderBoxWidget(
                    title: 'کانفیگ آبی',
                    height: 50,
                    config: const HeaderBoxConfig(
                      backgroundColor: Color(0xFFE3F2FD),
                      textColor: Color(0xFF1976D2),
                      borderColor: Color(0xFF1976D2),
                      borderWidth: 2.0,
                    ),
                    onTap: () => _showSnackBar(context, 'کانفیگ آبی کلیک شد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HeaderBoxWidget(
                    title: 'کانفیگ سبز',
                    height: 50,
                    config: const HeaderBoxConfig(
                      backgroundColor: Color(0xFFE8F5E8),
                      textColor: Color(0xFF388E3C),
                      borderColor: Color(0xFF388E3C),
                      borderWidth: 2.0,
                    ),
                    onTap: () => _showSnackBar(context, 'کانفیگ سبز کلیک شد'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // راهنمای استفاده
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF9800),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'راهنمای استفاده:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• برای باکس تکی: HeaderBoxWidget(title: "عنوان")\n'
                    '• برای ردیف عناوین: HeaderRowWidget(headers: ["عنوان1", "عنوان2"])\n'
                    '• برای کانفیگ سفارشی: config پارامتر را تنظیم کنید\n'
                    '• پس‌زمینه پیش‌فرض: خاکستری ملایم (#F5F5F5)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFBF360C),
                      fontFamily: 'Vazirmatn',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF388E3C),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

