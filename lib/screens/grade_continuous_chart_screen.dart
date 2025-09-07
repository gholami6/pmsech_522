import 'package:flutter/material.dart';
import '../widgets/grade_continuous_chart.dart';
import '../widgets/page_header.dart';
import '../config/app_colors.dart';

class GradeContinuousChartScreen extends StatefulWidget {
  const GradeContinuousChartScreen({Key? key}) : super(key: key);

  @override
  State<GradeContinuousChartScreen> createState() =>
      _GradeContinuousChartScreenState();
}

class _GradeContinuousChartScreenState
    extends State<GradeContinuousChartScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.stopsAppBar,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: 'نمودار پیوسته عیار خوراک و محصول',
                backRoute: '/dashboard',
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.mainContainerBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // توضیحات نمودار
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryBlue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'توضیحات نمودار',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'این نمودار نمایش پیوسته عیار خوراک و محصول را در طول ماه جاری نشان می‌دهد. نمودار از شیفت اول روز اول ماه شروع شده و تا آخرین شیفت ثبت‌شده ادامه دارد.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '• محور عمودی: همیشه ۰ تا ۱۰۰ درصد (ثابت)\n• محور افقی: شیفت‌های ماه جاری (قابل اسکرول)\n• خط آبی: عیار خوراک\n• خط سبز: عیار محصول',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // نمودار اصلی
                        const GradeContinuousChart(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
