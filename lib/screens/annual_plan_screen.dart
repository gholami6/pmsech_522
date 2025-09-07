import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../config/app_colors.dart';

class AnnualPlanScreen extends StatefulWidget {
  const AnnualPlanScreen({Key? key}) : super(key: key);

  @override
  State<AnnualPlanScreen> createState() => _AnnualPlanScreenState();
}

class _AnnualPlanScreenState extends State<AnnualPlanScreen>
    with TickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _offsetAnimation;

  final months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند'
  ];

  final factors = [
    {
      'title': 'روزهای کاری',
      'unit': 'روز',
      'values': [
        '15.8',
        '18.4',
        '18.4',
        '16.4',
        '18.4',
        '13.4',
        '17.7',
        '17.7',
        '17.7',
        '17.2',
        '17.2',
        '8.6'
      ]
    },
    {
      'title': 'روزهای کاری و غیرکاری',
      'unit': 'روز',
      'values': [
        '31.0',
        '31.0',
        '31.0',
        '31.0',
        '31.0',
        '31.0',
        '30.0',
        '30.0',
        '30.0',
        '30.0',
        '30.0',
        '29.0'
      ]
    },
    {
      'title': 'تجمعی روزهای کاری',
      'unit': 'روز',
      'values': [
        '15.8',
        '34.2',
        '52.6',
        '69.0',
        '87.4',
        '100.8',
        '118.5',
        '136.2',
        '153.9',
        '171.0',
        '188.2',
        '196.8'
      ]
    },
    {
      'title': 'تجمعی روزهای کاری و غیرکاری',
      'unit': 'روز',
      'values': [
        '31.0',
        '62.0',
        '93.0',
        '124.0',
        '155.0',
        '186.0',
        '216.0',
        '246.0',
        '276.0',
        '306.0',
        '336.0',
        '365.0'
      ]
    },
    {
      'title': 'قابلیت دسترسی',
      'unit': 'درصد',
      'values': [
        '50.89%',
        '59.36%',
        '59.36%',
        '52.91%',
        '59.36%',
        '43.23%',
        '58.98%',
        '58.98%',
        '58.98%',
        '57.18%',
        '57.18%',
        '29.56%'
      ]
    },
    {
      'title': 'تجمعی قابلیت دسترسی',
      'unit': 'درصد',
      'values': [
        '50.89%',
        '55.13%',
        '56.54%',
        '55.63%',
        '56.38%',
        '54.19%',
        '54.85%',
        '55.36%',
        '55.75%',
        '55.89%',
        '56.01%',
        '53.90%'
      ]
    },
    {
      'title': 'قابلیت دسترسی تجهیز',
      'unit': 'درصد',
      'values': [
        '75.68%',
        '78.40%',
        '78.40%',
        '76.39%',
        '78.40%',
        '57.10%',
        '77.96%',
        '77.96%',
        '77.96%',
        '77.42%',
        '77.42%',
        '46.31%'
      ]
    },
    {
      'title': 'فید ورودی',
      'unit': 'تن',
      'values': [
        '223398',
        '260568',
        '260568',
        '232248',
        '260568',
        '189768',
        '250564',
        '250564',
        '250564',
        '242894',
        '242894',
        '121380'
      ]
    },
    {
      'title': 'تجمعی فید ورودی',
      'unit': 'تن',
      'values': [
        '223398',
        '483966',
        '744535',
        '976783',
        '1237351',
        '1427119',
        '1677684',
        '1928248',
        '2178812',
        '2421706',
        '2664600',
        '2785980'
      ]
    },
    {
      'title': 'محصول',
      'unit': 'تن',
      'values': [
        '160400',
        '187088',
        '187088',
        '166754',
        '187088',
        '136254',
        '179905',
        '179905',
        '179905',
        '174398',
        '174398',
        '87151'
      ]
    },
    {
      'title': 'تجمعی محصول',
      'unit': 'تن',
      'values': [
        '160400',
        '347488',
        '534576',
        '701330',
        '888418',
        '1024672',
        '1204577',
        '1384482',
        '1564387',
        '1738785',
        '1913183',
        '2000334'
      ]
    },
    {
      'title': 'باطله',
      'unit': 'تن',
      'values': [
        '62998',
        '73480',
        '73480',
        '65494',
        '73480',
        '53515',
        '70659',
        '70659',
        '70659',
        '68496',
        '68496',
        '34229'
      ]
    },
    {
      'title': 'تجمعی باطله',
      'unit': 'تن',
      'values': [
        '62998',
        '136478',
        '209959',
        '275453',
        '348933',
        '402448',
        '473107',
        '543766',
        '614425',
        '682921',
        '751417',
        '785646'
      ]
    },
    {
      'title': 'توقفات برنامه ریزی شده',
      'unit': 'روز',
      'values': [
        '3.0',
        '3.0',
        '3.0',
        '3.0',
        '3.0',
        '8.0',
        '3.0',
        '3.0',
        '3.0',
        '3.0',
        '3.0',
        '8.0'
      ]
    },
    {
      'title': 'توقفات مکانیکی',
      'unit': 'روز',
      'values': [
        '1.63',
        '1.63',
        '1.63',
        '1.63',
        '1.63',
        '1.63',
        '1.58',
        '1.58',
        '1.58',
        '1.58',
        '1.58',
        '1.52'
      ]
    },
    {
      'title': 'توقفات برقی',
      'unit': 'روز',
      'values': [
        '0.4',
        '0.4',
        '0.4',
        '0.4',
        '0.4',
        '0.4',
        '0.39',
        '0.39',
        '0.39',
        '0.39',
        '0.39',
        '0.37'
      ]
    },
    {
      'title': 'توقفات تاسیسات',
      'unit': 'روز',
      'values': [
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04',
        '0.04'
      ]
    },
    {
      'title': 'توقفات بهره برداری',
      'unit': 'روز',
      'values': [
        '1.34',
        '1.34',
        '1.34',
        '1.34',
        '1.34',
        '1.34',
        '1.29',
        '1.29',
        '1.29',
        '1.29',
        '1.29',
        '1.25'
      ]
    },
    {
      'title': 'توقفات معدنی',
      'unit': 'روز',
      'values': [
        '0.74',
        '0.74',
        '0.74',
        '0.74',
        '0.74',
        '0.74',
        '0.72',
        '0.72',
        '0.72',
        '0.72',
        '0.72',
        '0.70'
      ]
    },
    {
      'title': 'توقفات عمومی',
      'unit': 'روز',
      'values': [
        '3.13',
        '0.5',
        '0.5',
        '2.5',
        '0.5',
        '0.5',
        '0.5',
        '0.5',
        '0.5',
        '1.04',
        '1.04',
        '3.92'
      ]
    },
    {
      'title': 'توقفات مجاز',
      'unit': 'روز',
      'values': [
        '4.78',
        '4.78',
        '4.78',
        '4.78',
        '4.78',
        '4.78',
        '4.62',
        '4.62',
        '4.62',
        '4.62',
        '4.62',
        '4.47'
      ]
    },
    {
      'title': 'توقفات بارگیری',
      'unit': 'روز',
      'values': [
        '0.17',
        '0.17',
        '0.17',
        '0.17',
        '0.17',
        '0.17',
        '0.16',
        '0.16',
        '0.16',
        '0.16',
        '0.16',
        '0.16'
      ]
    },
    {
      'title': 'تجمعی توقفات',
      'unit': 'روز',
      'values': [
        '15.22',
        '12.60',
        '12.60',
        '14.60',
        '12.60',
        '17.60',
        '12.30',
        '12.30',
        '12.30',
        '12.85',
        '12.85',
        '20.43'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _scaleAnimation = Tween<double>(
      begin: _scale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _offsetAnimation = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _scale = 1.0;
        _offset = Offset.zero;
      });
    });

    setState(() {});
  }

  void _centerTable() {
    _offsetAnimation = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _offset = Offset.zero;
      });
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stopsAppBar,
      appBar: AppBar(
        title: const Text(
          'برنامه سالانه تولید و توقفات',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Vazirmatn',
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.stopsAppBar,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
            onPressed: _centerTable,
            tooltip: 'مرکز کردن جدول',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetZoom,
            tooltip: 'بازنشانی زوم',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.mainContainerBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // راهنمای زوم و نمایش مقیاس
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.zoom_in, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'برای زوم کردن، از دو انگشت استفاده کنید. برای حرکت دادن جدول، آن را بکشید.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(_scale * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // جدول با قابلیت زوم و پن حرفه‌ای
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      transformationController: TransformationController(),
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.3,
                      maxScale: 4.0,
                      clipBehavior: Clip.none,
                      panEnabled: true,
                      scaleEnabled: true,
                      constrained: false,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dataTableTheme: DataTableThemeData(
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                        AppColors.stopsAppBar,
                                      ),
                                      dataRowColor: MaterialStateProperty
                                          .resolveWith<Color?>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.hovered)) {
                                            return Colors.grey.withOpacity(0.1);
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  child: DataTable(
                                    columns: [
                                      ...months.reversed
                                          .map(
                                              (m) => _buildHeaderColumn(m, 110))
                                          .toList(),
                                      _buildHeaderColumn('واحد', 90),
                                      _buildHeaderColumn('شرح', 220),
                                    ],
                                    rows: factors.map((f) {
                                      final factor = f as Map<String, dynamic>;
                                      return _buildDataRow(factor);
                                    }).toList(),
                                    dataRowMinHeight: 28,
                                    dataRowMaxHeight: 32,
                                    columnSpacing: 8,
                                    horizontalMargin: 4,
                                    headingRowHeight: 28,
                                    headingTextStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                    dataTextStyle: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'Vazirmatn',
                                      color: AppColors.primaryText,
                                    ),
                                    border: TableBorder.all(
                                      color: AppColors.borderLight
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                    dividerThickness: 1,
                                    showBottomBorder: true,
                                    checkboxHorizontalMargin: 0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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

  DataColumn _buildHeaderColumn(String title, double width) {
    return DataColumn(
      label: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1976D2),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Vazirmatn',
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> factor) {
    final title = factor['title'].toString();
    final unit = factor['unit'].toString();
    final values = factor['values'] as List<String>;

    // تعیین رنگ پس‌زمینه و ویژگی‌های بصری بر اساس نوع داده
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.transparent;
    IconData? iconData;

    if (title.contains('توقفات')) {
      backgroundColor = Colors.red.withOpacity(0.08);
      borderColor = Colors.red.withOpacity(0.2);
      iconData = Icons.pause_circle_outline;
    } else if (title.contains('محصول') || title.contains('فید')) {
      backgroundColor = Colors.green.withOpacity(0.08);
      borderColor = Colors.green.withOpacity(0.2);
      iconData = title.contains('محصول')
          ? Icons.inventory_2_outlined
          : Icons.input_outlined;
    } else if (title.contains('قابلیت')) {
      backgroundColor = Colors.blue.withOpacity(0.08);
      borderColor = Colors.blue.withOpacity(0.2);
      iconData = Icons.analytics_outlined;
    } else if (title.contains('روزهای')) {
      backgroundColor = Colors.orange.withOpacity(0.08);
      borderColor = Colors.orange.withOpacity(0.2);
      iconData = Icons.calendar_today_outlined;
    }

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.hovered)) {
          return backgroundColor.withOpacity(0.15);
        }
        return backgroundColor;
      }),
      cells: [
        ...values.reversed
            .map((value) => DataCell(
                  Container(
                    width: 110,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Vazirmatn',
                        color: _getValueColor(value, title),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ))
            .toList(),
        DataCell(
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Vazirmatn',
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                if (iconData != null) ...[
                  Icon(
                    iconData,
                    size: 14,
                    color: _getValueColor('', title).withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Vazirmatn',
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getValueColor(String value, String title) {
    // رنگ‌بندی پیشرفته بر اساس نوع داده و مقدار
    if (title.contains('توقفات')) {
      // توقفات بیشتر = قرمز پررنگ‌تر
      if (value.isNotEmpty) {
        final numValue = double.tryParse(value.replaceAll('%', '')) ?? 0;
        if (numValue > 10) return Colors.red[800]!;
        if (numValue > 5) return Colors.red[600]!;
      }
      return Colors.red[700]!;
    } else if (title.contains('محصول') || title.contains('فید')) {
      // مقادیر بالا = سبز پررنگ‌تر
      if (value.isNotEmpty) {
        final numValue = double.tryParse(value.replaceAll(',', '')) ?? 0;
        if (numValue > 200000) return Colors.green[800]!;
        if (numValue > 100000) return Colors.green[600]!;
      }
      return Colors.green[700]!;
    } else if (title.contains('قابلیت')) {
      // درصد بالا = آبی پررنگ‌تر
      if (value.contains('%')) {
        final numValue = double.tryParse(value.replaceAll('%', '')) ?? 0;
        if (numValue > 70) return Colors.blue[800]!;
        if (numValue > 50) return Colors.blue[600]!;
        if (numValue < 30) return Colors.orange[700]!;
      }
      return Colors.blue[700]!;
    } else if (title.contains('روزهای')) {
      return Colors.orange[700]!;
    } else if (title.contains('تجمعی')) {
      return Colors.purple[700]!;
    }
    return AppColors.primaryText;
  }
}

// تابع استاتیک برای استخراج داده‌های برنامه سالانه
class AnnualPlanData {
  static Map<String, List<double>> getStopsPlan() {
    return {
      'برنامه ای': [3.0, 3.0, 3.0, 3.0, 3.0, 8.0, 3.0, 3.0, 3.0, 3.0, 3.0, 8.0],
      'مکانیکی': [
        1.63,
        1.63,
        1.63,
        1.63,
        1.63,
        1.63,
        1.58,
        1.58,
        1.58,
        1.58,
        1.58,
        1.52
      ],
      'برقی': [
        0.48,
        0.48,
        0.48,
        0.48,
        0.48,
        0.48,
        0.48,
        0.48,
        0.48,
        0.48,
        0.48,
        0.48
      ],
      'تاسیساتی': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      'بهره برداری': [
        1.56,
        1.56,
        1.56,
        1.56,
        1.56,
        1.56,
        1.56,
        1.56,
        1.56,
        1.56,
        1.56,
        1.56
      ],
      'معدنی': [
        0.84,
        0.84,
        0.84,
        0.84,
        0.84,
        0.84,
        0.84,
        0.84,
        0.84,
        0.84,
        0.84,
        0.84
      ],
      'عمومی': [3.0, 0.5, 0.5, 2.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 3.9],
      'مجاز': [4.8, 4.8, 4.8, 4.8, 4.8, 4.8, 4.6, 4.6, 4.6, 4.6, 4.6, 4.5],
      'بارگیری': [
        0.24,
        0.24,
        0.24,
        0.24,
        0.24,
        0.24,
        0.24,
        0.24,
        0.24,
        0.24,
        0.24,
        0.24
      ],
    };
  }
}
