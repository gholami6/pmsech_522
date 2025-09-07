import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/grade_data.dart';
import '../config/app_colors.dart';

class ProductGradeBox extends StatefulWidget {
  const ProductGradeBox({Key? key}) : super(key: key);

  @override
  _ProductGradeBoxState createState() => _ProductGradeBoxState();
}

class _ProductGradeBoxState extends State<ProductGradeBox> {
  bool _isLoading = false;
  List<GradeData> _currentMonthGrades = [];

  @override
  void initState() {
    super.initState();
    _loadGradeData();
  }

  Future<void> _loadGradeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // دریافت داده‌های عیار از DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final allGradeData = dataProvider.getGradeData();

      if (allGradeData.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // یافتن ماه جاری (ماه آخرین داده عیار موجود)
      allGradeData.sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        if (a.month != b.month) return b.month.compareTo(a.month);
        if (a.day != b.day) return b.day.compareTo(a.day);
        return b.shift.compareTo(a.shift);
      });

      final latestGrade = allGradeData.first;
      final currentYear = latestGrade.year;
      final currentMonth = latestGrade.month;

      // فیلتر کردن داده‌های ماه جاری
      final currentMonthGrades = allGradeData
          .where((g) => g.year == currentYear && g.month == currentMonth)
          .toList();

      setState(() {
        _currentMonthGrades = currentMonthGrades;
        _isLoading = false;
      });
    } catch (e) {
      print('خطا در بارگذاری داده‌های عیار: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // گوش دادن به تغییرات DataProvider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentGradeData = dataProvider.getGradeData();
          if (currentGradeData.length != _currentMonthGrades.length) {
            _loadGradeData();
          }
        });

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // عنوان باکس
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'نمودار عیار ماهانه',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // محتوای نمودار
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _currentMonthGrades.isEmpty
                        ? const Center(
                            child: Text(
                              'داده‌ای برای نمایش وجود ندارد',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // آمار ساده
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatCard(
                                      'تعداد رکوردها',
                                      _currentMonthGrades.length.toString(),
                                      Icons.data_usage,
                                      AppColors.feedColor,
                                    ),
                                    _buildStatCard(
                                      'آخرین روز',
                                      _currentMonthGrades.isNotEmpty
                                          ? _currentMonthGrades.first.day.toString()
                                          : '-',
                                      Icons.calendar_today,
                                      AppColors.productColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // راهنما
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem(
                                      'عیار محصول',
                                      AppColors.productColor,
                                    ),
                                    const SizedBox(width: 24),
                                    _buildLegendItem(
                                      'عیار خوراک',
                                      AppColors.feedColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
