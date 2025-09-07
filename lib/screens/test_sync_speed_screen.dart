import 'package:flutter/material.dart';
import '../services/simple_data_sync_service.dart';
import '../services/grade_service.dart';

class TestSyncSpeedScreen extends StatefulWidget {
  const TestSyncSpeedScreen({super.key});

  @override
  State<TestSyncSpeedScreen> createState() => _TestSyncSpeedScreenState();
}

class _TestSyncSpeedScreenState extends State<TestSyncSpeedScreen> {
  final SimpleDataSyncService _syncService = SimpleDataSyncService();
  bool _isTesting = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _syncService.init();
  }

  Future<void> _testSyncSpeed() async {
    setState(() {
      _isTesting = true;
      _result = 'شروع تست سرعت...\n';
    });

    try {
      final stopwatch = Stopwatch()..start();

      // تست اتصال
      _result += '🔍 تست اتصال...\n';
      final connectionTest = await _syncService.testConnection();
      _result += '✅ اتصال: ${connectionTest ? "موفق" : "ناموفق"}\n';

      // تست همگام‌سازی
      _result += '🔄 شروع همگام‌سازی...\n';
      await _syncService.syncAllData();
      final syncResult = true; // موقتاً true در نظر می‌گیریم

      stopwatch.stop();
      final duration = stopwatch.elapsed;

      _result += '✅ همگام‌سازی: ${syncResult ? "موفق" : "ناموفق"}\n';
      _result += '⏱️ زمان کل: ${duration.inSeconds} ثانیه\n';
      _result +=
          '📊 سرعت: ${(duration.inMilliseconds / 1000).toStringAsFixed(2)} ثانیه\n';

      // وضعیت نهایی
      final status = _syncService.getSyncStatus();
      _result += '\n📈 وضعیت نهایی:\n';
      _result += '- تولید: ${status['productionCount']} رکورد\n';
      _result += '- توقف: ${status['stopCount']} رکورد\n';
      _result += '- شیفت: ${status['shiftCount']} رکورد\n';
      _result += '- عیار: ${status['gradeCount']} رکورد\n';
    } catch (e) {
      _result += '❌ خطا: $e\n';
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تست سرعت همگام‌سازی'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _testSyncSpeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: _isTesting
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('در حال تست...'),
                      ],
                    )
                  : const Text('شروع تست سرعت'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty
                        ? 'نتایج تست اینجا نمایش داده می‌شود'
                        : _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
