import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../services/production_analysis_service.dart';
import '../services/data_sync_service.dart';
import '../models/production_data.dart';

class ComparisonDemoScreen extends StatelessWidget {
  const ComparisonDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 مقایسه روش‌های محاسبه'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          final allData = dataProvider.getProductionData();

          if (allData.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'هیچ داده‌ای موجود نیست',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'لطفاً ابتدا داده‌ها را همگام‌سازی کنید',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // محاسبه با روش قدیمی (دوباره‌شماری دارد)
          final oldStats = DataSyncService.calculateStatistics(allData);

          // محاسبه با روش جدید (صحیح)
          final newStats =
              ProductionAnalysisService.calculateCombinedStatistics(allData);
          final newProductionStats =
              newStats['production'] as Map<String, dynamic>;
          final newStopStats = newStats['stops'] as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // توضیح مسئله
                _buildExplanationCard(),
                const SizedBox(height: 20),

                // مقایسه آمار تولید
                _buildComparisonCard(
                  title: '🏭 مقایسه آمار تولید',
                  oldValue: ProductionAnalysisService.formatNumber(
                      oldStats['totalProducedProduct']),
                  newValue: ProductionAnalysisService.formatNumber(
                      newProductionStats['totalProducedProduct']),
                  unit: 'تن',
                  description: 'تولید کل محصول',
                  color: Colors.green,
                ),

                const SizedBox(height: 12),

                _buildComparisonCard(
                  title: '📊 مقایسه تعداد سرویس',
                  oldValue: ProductionAnalysisService.formatNumber(
                      oldStats['totalServiceCount']),
                  newValue: ProductionAnalysisService.formatNumber(
                      newProductionStats['totalServiceCount']),
                  unit: 'عدد',
                  description: 'تعداد کل سرویس‌ها',
                  color: Colors.blue,
                ),

                const SizedBox(height: 12),

                _buildComparisonCard(
                  title: '⏹️ مقایسه آمار توقفات',
                  oldValue: '${allData.length}',
                  newValue: '${newStopStats['totalStops']}',
                  unit: 'مورد',
                  description: 'تعداد کل توقفات',
                  color: Colors.red,
                ),

                const SizedBox(height: 20),

                // جدول تفصیلی
                _buildDetailedTable(
                    allData, oldStats, newProductionStats, newStopStats),

                const SizedBox(height: 20),

                // نتیجه‌گیری
                _buildConclusionCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '💡 توضیح مسئله',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '🔸 هر ردیف در اکسل = یک توقف',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '🔸 داده‌های تولید تکراری هستند (برای جلوگیری از خالی بودن سلول‌ها)',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '🔸 برای تحلیل توقفات: همه ردیف‌ها را در نظر می‌گیریم',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '🔸 برای تحلیل تولید: فقط یک ردیف از هر شیفت را در نظر می‌گیریم',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String oldValue,
    required String newValue,
    required String unit,
    required String description,
    required Color color,
  }) {
    final isDifferent = oldValue != newValue;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '❌ روش قدیمی',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$oldValue $unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const Text(
                          '(دوباره‌شماری)',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ روش جدید',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$newValue $unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Text(
                          '(صحیح)',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isDifferent) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'تفاوت معنی‌دار شناسایی شد!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTable(
    List<ProductionData> allData,
    Map<String, dynamic> oldStats,
    Map<String, dynamic> newProductionStats,
    Map<String, dynamic> newStopStats,
  ) {
    final uniqueData =
        ProductionAnalysisService.getUniqueProductionData(allData);
    final stopData = ProductionAnalysisService.getAllStopData(allData);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 جدول مقایسه تفصیلی',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('معیار',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('روش قدیمی',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('روش جدید',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('وضعیت',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                _buildTableRow(
                  'کل رکوردها',
                  '${allData.length}',
                  '${allData.length}',
                  '✅',
                ),
                _buildTableRow(
                  'رکوردهای تولید',
                  '${allData.length}',
                  '${uniqueData.length}',
                  uniqueData.length < allData.length ? '⚠️' : '✅',
                ),
                _buildTableRow(
                  'رکوردهای توقف',
                  '${allData.length}',
                  '${stopData.length}',
                  '✅',
                ),
                _buildTableRow(
                  'تولید کل (تن)',
                  ProductionAnalysisService.formatNumber(
                      oldStats['totalProducedProduct']),
                  ProductionAnalysisService.formatNumber(
                      newProductionStats['totalProducedProduct']),
                  oldStats['totalProducedProduct'] !=
                          newProductionStats['totalProducedProduct']
                      ? '⚠️'
                      : '✅',
                ),
                _buildTableRow(
                  'کل سرویس‌ها',
                  '${oldStats['totalServiceCount']}',
                  '${newProductionStats['totalServiceCount']}',
                  oldStats['totalServiceCount'] !=
                          newProductionStats['totalServiceCount']
                      ? '⚠️'
                      : '✅',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(
      String label, String oldValue, String newValue, String status) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(oldValue, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(newValue, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(status, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildConclusionCard() {
    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  '🎯 نتیجه‌گیری',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '✅ روش جدید از دوباره‌شماری جلوگیری می‌کند',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '✅ آمار تولید صحیح و دقیق محاسبه می‌شود',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '✅ آمار توقفات کامل و جامع ثبت می‌شود',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '✅ تحلیل‌های مدیریتی بر اساس داده‌های واقعی انجام می‌شود',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
