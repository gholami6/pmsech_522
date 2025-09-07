import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../services/data_sync_service.dart';
import '../services/production_analysis_service.dart';
import '../widgets/downtime_chart.dart';
import '../widgets/summary_card.dart';

class EquipmentDetailsScreen extends StatefulWidget {
  final String equipmentName;
  final List<ProductionData> allData;

  const EquipmentDetailsScreen({
    Key? key,
    required this.equipmentName,
    required this.allData,
  }) : super(key: key);

  @override
  State<EquipmentDetailsScreen> createState() => _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState extends State<EquipmentDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ProductionData> filteredData = [];
  Map<String, dynamic> statistics = {};
  List<String> subEquipmentList = [];
  String selectedSubEquipment = 'همه';
  String selectedStopType = 'همه';
  List<String> allStopTypes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStopTypes();
    _filterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _filterData() {
    // فیلتر کردن داده‌ها بر اساس تجهیز انتخاب شده
    filteredData = DataSyncService.filterByEquipment(
      widget.allData,
      widget.equipmentName,
    );

    // فیلتر کردن بر اساس ریز تجهیز
    if (selectedSubEquipment != 'همه') {
      filteredData = filteredData
          .where((item) => item.subEquipment == selectedSubEquipment)
          .toList();
    }

    // فیلتر کردن بر اساس نوع توقف
    if (selectedStopType != 'همه') {
      filteredData = DataSyncService.filterByStopType(
        filteredData,
        selectedStopType,
      );
    }

    // محاسبه آمار
    statistics = DataSyncService.calculateStatistics(filteredData);

    // دریافت لیست ریز تجهیزات
    subEquipmentList = [
      'همه',
      ...DataSyncService.getSubEquipmentForEquipment(
        widget.allData,
        widget.equipmentName,
      )
    ];

    setState(() {});
  }

  Future<void> _loadStopTypes() async {
    try {
      allStopTypes = await ProductionAnalysisService.getAllStopTypes();
      setState(() {});
    } catch (e) {
      print('خطا در بارگذاری انواع توقف: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('جزئیات ${widget.equipmentName}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'خلاصه', icon: Icon(Icons.summarize)),
            Tab(text: 'توقفات', icon: Icon(Icons.stop_circle)),
            Tab(text: 'آمار', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          // فیلترها
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // فیلتر ریز تجهیز
                Row(
                  children: [
                    const Text('ریز تجهیز: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedSubEquipment,
                        isExpanded: true,
                        items: subEquipmentList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSubEquipment = newValue!;
                            _filterData();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // فیلتر نوع توقف
                Row(
                  children: [
                    const Text('نوع توقف: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedStopType,
                        isExpanded: true,
                        items: ['همه', ...allStopTypes].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedStopType = newValue!;
                            _filterData();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // محتوای تب‌ها
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildStopsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خلاصه عملکرد ${widget.equipmentName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
          ),
          const SizedBox(height: 16),
          // کارت‌های خلاصه
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              SummaryCard(
                title: 'تناژ ورودی',
                value:
                    '${statistics['totalInputTonnage']?.toStringAsFixed(1) ?? '0'} تن',
                icon: Icons.input,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
              ),
              SummaryCard(
                title: 'تعداد سرویس',
                value: '${statistics['totalServiceCount'] ?? '0'}',
                icon: Icons.local_shipping,
                backgroundColor: Colors.orange,
                textColor: Colors.white,
              ),
              SummaryCard(
                title: 'توقفات اضطراری',
                value: '${statistics['emergencyStops'] ?? '0'}',
                icon: Icons.emergency,
                backgroundColor: Colors.red[700]!,
                textColor: Colors.white,
              ),
              SummaryCard(
                title: 'توقفات فنی',
                value: '${statistics['technicalStops'] ?? '0'}',
                icon: Icons.build,
                backgroundColor: Colors.purple,
                textColor: Colors.white,
              ),
              SummaryCard(
                title: 'فید مستقیم',
                value: '${statistics['directFeedCount'] ?? '0'}',
                icon: Icons.route,
                backgroundColor: Colors.teal,
                textColor: Colors.white,
              ),
              SummaryCard(
                title: 'پرعیارسازی',
                value: '${statistics['enrichmentCount'] ?? '0'}',
                icon: Icons.tune,
                backgroundColor: Colors.indigo,
                textColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // اطلاعات اضافی
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اطلاعات تکمیلی',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      'تعداد ریز تجهیزات', '${subEquipmentList.length - 1}'),
                  _buildInfoRow('کل مدت توقف',
                      '${statistics['totalStopDuration'] ?? '0'} دقیقه'),
                  _buildInfoRow('میانگین مدت توقف',
                      '${statistics['averageStopDuration']?.toStringAsFixed(1) ?? '0'} دقیقه'),
                  _buildInfoRow('تعداد رکوردها', '${filteredData.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopsTab() {
    // محاسبه داده‌های توقف از filteredData
    Map<String, double> stopTypeDuration = {};
    Map<String, int> stopTypeCount = {};

    for (var item in filteredData) {
      if (item.stopType.isNotEmpty && item.stopDurationMinutes > 0) {
        stopTypeDuration[item.stopType] =
            (stopTypeDuration[item.stopType] ?? 0) + item.stopDurationMinutes;
        stopTypeCount[item.stopType] = (stopTypeCount[item.stopType] ?? 0) + 1;
      }
    }

    // مرتب‌سازی بر اساس مدت توقف (نزولی)
    var sortedStops = stopTypeDuration.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // آماده‌سازی داده‌ها برای نمودار
    List<double> downtimeData = [];
    List<String> labels = [];
    List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];

    for (int i = 0; i < sortedStops.length && i < colors.length; i++) {
      downtimeData.add(sortedStops[i].value);
      labels.add(sortedStops[i].key);
    }

    // اگر داده‌ای وجود ندارد، پیام نمایش دهید
    if (downtimeData.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نمودار توقفات',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Container(
                height: 200,
                child: Center(
                  child: Text(
                    'داده‌ای برای نمایش وجود ندارد',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نمودار توقفات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
          ),
          const SizedBox(height: 16),
          DowntimeChart(
            downtimeData: downtimeData,
            labels: labels,
            colors: colors.take(downtimeData.length).toList(),
          ),
          const SizedBox(height: 24),
          // جدول توقفات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جدول توقفات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('تاریخ')),
                        DataColumn(label: Text('شیفت')),
                        DataColumn(label: Text('ریز تجهیز')),
                        DataColumn(label: Text('نوع توقف')),
                        DataColumn(label: Text('علت')),
                        DataColumn(label: Text('مدت')),
                        DataColumn(label: Text('شروع')),
                        DataColumn(label: Text('پایان')),
                      ],
                      rows: filteredData.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item.fullShamsiDate)),
                            DataCell(Text('شیفت ${item.shift}')),
                            DataCell(Text(item.subEquipment)),
                            DataCell(Text(item.stopType)),
                            DataCell(Text(item.stopReason)),
                            DataCell(Text(item.stopDuration)),
                            DataCell(Text(item.stopStartTime)),
                            DataCell(Text(item.stopEndTime)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    // گروه‌بندی داده‌ها بر اساس نوع توقف
    final stopTypeGroups = DataSyncService.groupByStopType(filteredData);
    final dateGroups = DataSyncService.groupByDate(filteredData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تحلیل آماری',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
          ),
          const SizedBox(height: 16),
          // آمار بر اساس نوع توقف
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'آمار بر اساس نوع توقف',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...stopTypeGroups.entries.map((entry) {
                    final stats =
                        DataSyncService.calculateStatistics(entry.value);
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${entry.value.length} توقف'),
                      trailing: Text('${stats['totalStopDuration']} دقیقه'),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          // آمار بر اساس تاریخ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'آمار بر اساس تاریخ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...dateGroups.entries.take(10).map((entry) {
                    final stats =
                        DataSyncService.calculateStatistics(entry.value);
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${entry.value.length} رکورد'),
                      trailing: Text(
                          '${stats['totalInputTonnage']?.toStringAsFixed(1) ?? '0'} تن'),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
