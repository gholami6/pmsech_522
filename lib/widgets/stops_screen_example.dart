import 'package:flutter/material.dart';
import '../config/stops_screen_styles.dart';
import 'stops_widgets.dart';

class StopsScreenExample extends StatelessWidget {
  const StopsScreenExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StopsScreenStyles.cardBackgroundColor,
      appBar: AppBar(
        title: const Text('مدیریت توقفات'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // بخش فیلترها
            StopsFilterSection(
              title: 'فیلتر تجهیزات',
              selectedFilters: ['سنگ‌شکن 1', 'سنگ‌شکن 2'],
              allFilters: ['سنگ‌شکن 1', 'سنگ‌شکن 2', 'سنگ‌شکن 3'],
              onFilterSelected: (filter) => print('انتخاب: $filter'),
              onFilterRemoved: (filter) => print('حذف: $filter'),
              onShowDialog: () => print('نمایش dialog'),
            ),

            // آمار کلی
            StopsSummaryGrid(
              stats: {
                'توقفات واقعی': '167.97 ساعت',
                'توقفات برنامه': '168.00 ساعت',
                'انحراف': '0.02%',
                'دسترسی': '95.8%',
              },
              valueColors: {
                'توقفات واقعی': Colors.orange,
                'توقفات برنامه': Colors.blue,
                'انحراف': Colors.green,
                'دسترسی': Colors.green,
              },
              icons: {
                'توقفات واقعی': Icons.access_time,
                'توقفات برنامه': Icons.schedule,
                'انحراف': Icons.trending_up,
                'دسترسی': Icons.check_circle,
              },
            ),

            // کارت نمودار
            StopsChartSection(
              title: 'نمودار توقفات',
              subtitle: 'مقایسه توقفات واقعی و برنامه‌ای',
              chart: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Text('نمودار اینجا قرار می‌گیرد'),
                ),
              ),
            ),

            // کارت اطلاعات
            StopsCard(
              title: 'جزئیات توقفات',
              child: Column(
                children: [
                  Text(
                    'اطلاعات تفصیلی توقفات در این بخش نمایش داده می‌شود.',
                    style: StopsScreenStyles.bodyTextStyle,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: StopsStatCard(
                          label: 'برنامه‌ای',
                          value: '11.6 ساعت',
                          valueColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: StopsStatCard(
                          label: 'مکانیکی',
                          value: '8.2 ساعت',
                          valueColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
