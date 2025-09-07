import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/services/data_sync_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تست DataSyncService',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Vazirmatn',
      ),
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  DataSyncService? _dataSyncService;
  String _status = 'آماده';
  double _progress = 0.0;
  Map<String, dynamic> _syncStatus = {};
  Map<String, dynamic> _healthStatus = {};

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    try {
      setState(() => _status = 'در حال راه‌اندازی...');
      
      _dataSyncService = DataSyncService();
      await _dataSyncService!.init();
      
      setState(() => _status = 'راه‌اندازی کامل');
      _updateStatus();
    } catch (e) {
      setState(() => _status = 'خطا در راه‌اندازی: $e');
    }
  }

  Future<void> _testConnection() async {
    if (_dataSyncService == null) return;
    
    setState(() => _status = 'در حال تست اتصال...');
    
    try {
      final isConnected = await _dataSyncService!.testConnection();
      setState(() => _status = isConnected ? 'اتصال موفق' : 'اتصال ناموفق');
    } catch (e) {
      setState(() => _status = 'خطا در تست اتصال: $e');
    }
  }

  Future<void> _syncData() async {
    if (_dataSyncService == null) return;
    
    setState(() {
      _status = 'شروع همگام‌سازی...';
      _progress = 0.0;
    });
    
    try {
      await _dataSyncService!.syncData(
        onProgress: (progress) {
          setState(() {
            _progress = progress;
            _status = 'همگام‌سازی: ${(progress * 100).toInt()}%';
          });
        },
      );
      
      setState(() {
        _status = 'همگام‌سازی موفقیت‌آمیز';
        _progress = 1.0;
      });
      
      _updateStatus();
    } catch (e) {
      setState(() => _status = 'خطا در همگام‌سازی: $e');
    }
  }

  void _updateStatus() {
    if (_dataSyncService == null) return;
    
    setState(() {
      _syncStatus = _dataSyncService!.getSyncStatus();
      _healthStatus = _dataSyncService!.checkDataHealth();
    });
  }

  Future<void> _clearData() async {
    if (_dataSyncService == null) return;
    
    setState(() => _status = 'در حال پاک کردن داده‌ها...');
    
    try {
      await _dataSyncService!.clearAllData();
      setState(() => _status = 'داده‌ها پاک شدند');
      _updateStatus();
    } catch (e) {
      setState(() => _status = 'خطا در پاک کردن داده‌ها: $e');
    }
  }

  Future<void> _forceFullSync() async {
    if (_dataSyncService == null) return;
    
    setState(() => _status = 'در حال مجبور کردن دانلود کامل...');
    
    try {
      await _dataSyncService!.forceFullSync();
      setState(() => _status = 'دانلود کامل مجبور شد');
    } catch (e) {
      setState(() => _status = 'خطا در مجبور کردن دانلود کامل: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تست DataSyncService'),
        backgroundColor: Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // وضعیت کلی
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضعیت کلی',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('وضعیت: $_status'),
                    if (_progress > 0)
                      Column(
                        children: [
                          SizedBox(height: 8),
                          LinearProgressIndicator(value: _progress),
                          SizedBox(height: 4),
                          Text('پیشرفت: ${(_progress * 100).toInt()}%'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // دکمه‌های کنترل
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'کنترل‌ها',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _testConnection,
                      child: Text('تست اتصال'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _syncData,
                      child: Text('همگام‌سازی'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _updateStatus,
                      child: Text('بروزرسانی وضعیت'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _forceFullSync,
                      child: Text('دانلود کامل اجباری'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _clearData,
                      child: Text('پاک کردن داده‌ها'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // وضعیت همگام‌سازی
            if (_syncStatus.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وضعیت همگام‌سازی',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      _buildStatusItem('آخرین همگام‌سازی', _syncStatus['lastSyncTime'] ?? 'نامشخص'),
                      _buildStatusItem('خطای آخر', _syncStatus['lastError'] ?? 'هیچ خطایی'),
                      _buildStatusItem('تعداد تولید', _syncStatus['productionCount']?.toString() ?? '0'),
                      _buildStatusItem('تعداد توقفات', _syncStatus['stopCount']?.toString() ?? '0'),
                      _buildStatusItem('تعداد شیفت‌ها', _syncStatus['shiftCount']?.toString() ?? '0'),
                      _buildStatusItem('دارای داده', _syncStatus['hasData'] == true ? 'بله' : 'خیر'),
                      _buildStatusItem('در حال همگام‌سازی', _syncStatus['isSyncing'] == true ? 'بله' : 'خیر'),
                      _buildStatusItem('تعداد تلاش', '${_syncStatus['retryCount'] ?? 0}/${_syncStatus['maxRetries'] ?? 3}'),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 16),
            
            // وضعیت سلامت داده‌ها
            if (_healthStatus.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سلامت داده‌ها',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      _buildStatusItem('سالم', _healthStatus['isHealthy'] == true ? 'بله' : 'خیر'),
                      _buildStatusItem('تعداد خطاها', _healthStatus['totalErrors']?.toString() ?? '0'),
                      _buildStatusItem('خطاهای تولید', _healthStatus['productionErrors']?.length?.toString() ?? '0'),
                      _buildStatusItem('خطاهای توقفات', _healthStatus['stopErrors']?.length?.toString() ?? '0'),
                      _buildStatusItem('خطاهای شیفت‌ها', _healthStatus['shiftErrors']?.length?.toString() ?? '0'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
