import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(ConnectionTestApp());
}

class ConnectionTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تست اتصال',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Vazirmatn',
      ),
      home: ConnectionTestScreen(),
    );
  }
}

class ConnectionTestScreen extends StatefulWidget {
  @override
  _ConnectionTestScreenState createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  String _status = 'آماده';
  bool _isTesting = false;
  List<String> _testResults = [];

  Future<void> _testInternetConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'در حال تست اتصال اینترنت...';
      _testResults.clear();
    });

    try {
      // تست اتصال به Google
      final response = await http
          .get(
            Uri.parse('https://www.google.com'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _addResult('✅ اتصال اینترنت: موفق');
      } else {
        _addResult('❌ اتصال اینترنت: ناموفق (${response.statusCode})');
      }
    } catch (e) {
      _addResult('❌ اتصال اینترنت: خطا - $e');
    }
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _status = 'در حال تست اتصال به سرور...';
    });

    try {
      final response = await http.get(
        Uri.parse('http://62.60.198.11/simple_xlsx_to_json.php'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'User-Agent': 'PMSech-App/1.0',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        _addResult('✅ اتصال سرور: موفق');

        // تست JSON response
        try {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            _addResult('✅ پاسخ JSON: معتبر');
          } else {
            _addResult('⚠️ پاسخ JSON: نامعتبر');
          }
        } catch (e) {
          _addResult('❌ پاسخ JSON: خطا در تجزیه - $e');
        }
      } else {
        _addResult('❌ اتصال سرور: ناموفق (${response.statusCode})');
      }
    } catch (e) {
      _addResult('❌ اتصال سرور: خطا - $e');
    }
  }

  Future<void> _testGradeAPI() async {
    setState(() {
      _status = 'در حال تست API عیار...';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://62.60.198.11/grade_api.php?action=download&api_key=pmsech_grade_api_2024'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'User-Agent': 'PMSech-App/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _addResult('✅ API عیار: موفق');
      } else {
        _addResult('❌ API عیار: ناموفق (${response.statusCode})');
      }
    } catch (e) {
      _addResult('❌ API عیار: خطا - $e');
    }
  }

  Future<void> _runAllTests() async {
    await _testInternetConnection();
    await Future.delayed(const Duration(seconds: 1));
    await _testServerConnection();
    await Future.delayed(const Duration(seconds: 1));
    await _testGradeAPI();

    setState(() {
      _isTesting = false;
      _status = 'تست‌ها تکمیل شد';
    });
  }

  void _addResult(String result) {
    setState(() {
      _testResults
          .add('${DateTime.now().toString().substring(11, 19)}: $result');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تست اتصال'),
        backgroundColor: Color(0xFF1976D2),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // وضعیت
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'وضعیت: $_status',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_isTesting)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // دکمه‌های تست
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تست‌های اتصال',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _runAllTests,
                      child: Text('اجرای تمام تست‌ها'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _testInternetConnection,
                      child: Text('تست اتصال اینترنت'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _testServerConnection,
                      child: Text('تست اتصال سرور'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _testGradeAPI,
                      child: Text('تست API عیار'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // نتایج
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نتایج تست‌ها',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _testResults.length,
                          itemBuilder: (context, index) {
                            final result = _testResults[index];
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                result,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: result.contains('✅')
                                      ? Colors.green
                                      : result.contains('❌')
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
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
