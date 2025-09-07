// 📱 نمونه استفاده از API جدید در اپلیکیشن Flutter

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/services/simple_api_service.dart';

class TestApiPage extends StatefulWidget {
  @override
  _TestApiPageState createState() => _TestApiPageState();
}

class _TestApiPageState extends State<TestApiPage> {
  late SimpleApiService _apiService;
  List<Map<String, dynamic>> _productionData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = SimpleApiService();
  }

  // تست اتصال به API
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    try {
      final isOnline = await _apiService.testConnection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isOnline ? '✅ اتصال موفقیت‌آمیز' : '❌ خطا در اتصال'),
          backgroundColor: isOnline ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  // دریافت داده‌های تولید
  Future<void> _loadProductionData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getProductionData();
      setState(() => _productionData = data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${data.length} رکورد تولید دریافت شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  // دریافت همه داده‌ها
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final allData = await _apiService.getAllData();

      setState(() {
        _productionData = allData['production'] ?? [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ همه داده‌ها دریافت شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تست API جدید'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // دکمه‌های تست
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('تست API',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testConnection,
                            icon: Icon(Icons.wifi),
                            label: Text('تست اتصال'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadAllData,
                            icon: Icon(Icons.download),
                            label: Text('دریافت همه'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadProductionData,
                            icon: Icon(Icons.factory),
                            label: Text('داده‌های تولید'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // نمایش وضعیت
            if (_isLoading)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('در حال دریافت داده‌ها...'),
                    ],
                  ),
                ),
              ),

            // نمایش آمار
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آمار داده‌ها',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('📊 تعداد رکوردهای تولید: ${_productionData.length}'),
                    SizedBox(height: 8),
                    Text(
                        '🌐 آدرس API: https://sechah.liara.run/simple_xlsx_to_json.php'),
                  ],
                ),
              ),
            ),

            // نمایش نمونه داده‌ها
            if (_productionData.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('نمونه داده‌های تولید',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _productionData.take(3).length,
                            itemBuilder: (context, index) {
                              final item = _productionData[index];
                              return ListTile(
                                title:
                                    Text('تاریخ: ${item['date'] ?? 'نامشخص'}'),
                                subtitle: Text(
                                    'تولید: ${item['production'] ?? 0} | هدف: ${item['target'] ?? 0}'),
                                trailing: Text(
                                    'راندمان: ${item['efficiency'] ?? 0}%'),
                              );
                            },
                          ),
                        ),
                      ],
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

// 🔧 نحوه اضافه کردن به main.dart:
/*
import 'نمونه_استفاده_API_جدید.dart';
import 'lib/services/simple_api_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SimpleApiService(),
      child: MyApp(),
    ),
  );
}

// سپس می‌توانید از TestApiPage استفاده کنید:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TestApiPage()),
);
*/ 