import 'package:flutter/material.dart';
import '../services/simple_data_sync_service.dart';
import '../services/data_sync_service.dart';

class SyncTestPage extends StatefulWidget {
  const SyncTestPage({super.key});

  @override
  State<SyncTestPage> createState() => _SyncTestPageState();
}

class _SyncTestPageState extends State<SyncTestPage> {
  final SimpleDataSyncService _simpleService = SimpleDataSyncService();
  final DataSyncService _dataService = DataSyncService();

  String _testResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تست اتصال سرور'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testSimpleService,
              child: const Text('تست SimpleDataSyncService'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDataService,
              child: const Text('تست DataSyncService'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testServerDirectly,
              child: const Text('تست مستقیم سرور'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: const Text('تست اتصال اینترنت'),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResult.isEmpty
                          ? 'نتایج تست اینجا نمایش داده می‌شود'
                          : _testResult,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSimpleService() async {
    setState(() {
      _isLoading = true;
      _testResult = 'در حال تست SimpleDataSyncService...\n';
    });

    try {
      final result = await _simpleService.testConnection();
      final status = _simpleService.getSyncStatus();

      setState(() {
        _testResult += '''
✅ تست SimpleDataSyncService:
- اتصال: ${result ? 'موفق' : 'ناموفق'}
- وضعیت همگام‌سازی: $status
- آخرین خطا: ${status['lastError'] ?? 'هیچ خطایی'}
- تعداد داده‌ها: ${status['productionCount']} تولید, ${status['stopCount']} توقف
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ خطا در تست SimpleDataSyncService: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testDataService() async {
    setState(() {
      _isLoading = true;
      _testResult += 'در حال تست DataSyncService...\n';
    });

    try {
      final result = await _dataService.testConnection();

      setState(() {
        _testResult += '''
✅ تست DataSyncService:
- اتصال: ${result ? 'موفق' : 'ناموفق'}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ خطا در تست DataSyncService: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testServerDirectly() async {
    setState(() {
      _isLoading = true;
      _testResult += 'در حال تست مستقیم سرور...\n';
    });

    try {
      final result = await _simpleService.testServerDirectly();

      setState(() {
        _testResult += '''
✅ تست مستقیم سرور:
- وضعیت سرور اصلی: ${result['server_status']}
- وضعیت API: ${result['api_status']}
- موفقیت: ${result['success'] ? 'بله' : 'خیر'}
- Headers سرور: ${result['server_headers']}
- Headers API: ${result['api_headers']}
- پیش‌نمایش پاسخ API: ${result['api_body_preview']}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ خطا در تست مستقیم سرور: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult += 'در حال تست اتصال اینترنت...\n';
    });

    try {
      final result = await _simpleService.checkInternetConnection();

      setState(() {
        _testResult += '''
✅ تست اتصال اینترنت:
- نتیجه: ${result ? 'متصل' : 'قطع'}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ خطا در تست اتصال اینترنت: $e\n';
        _isLoading = false;
      });
    }
  }
}
