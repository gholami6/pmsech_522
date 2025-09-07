import 'package:flutter/material.dart';
import '../services/connection_manager.dart';
import '../services/simple_data_sync_service.dart';
import '../widgets/page_header.dart';
import '../config/app_colors.dart';
import 'dart:async';

class NetworkPerformanceTestScreen extends StatefulWidget {
  const NetworkPerformanceTestScreen({super.key});

  @override
  State<NetworkPerformanceTestScreen> createState() =>
      _NetworkPerformanceTestScreenState();
}

class _NetworkPerformanceTestScreenState
    extends State<NetworkPerformanceTestScreen> {
  final ConnectionManager _connectionManager = ConnectionManager();
  final SimpleDataSyncService _syncService = SimpleDataSyncService();

  bool _isTestRunning = false;
  final List<String> _testResults = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectionManager.init();
  }

  @override
  void dispose() {
    _connectionManager.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addResult(String result) {
    setState(() {
      _testResults
          .add('[${DateTime.now().toString().substring(11, 19)}] $result');
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runPerformanceTest() async {
    if (_isTestRunning) return;

    setState(() {
      _isTestRunning = true;
      _testResults.clear();
    });

    _addResult('🚀 شروع تست عملکرد شبکه');

    try {
      // تست ۱: بررسی اتصال اینترنت
      _addResult('📶 تست اتصال اینترنت...');
      final stopwatch1 = Stopwatch()..start();
      final hasInternet = await _connectionManager.hasInternetConnection();
      stopwatch1.stop();
      _addResult(
          '${hasInternet ? "✅" : "❌"} اتصال اینترنت: ${stopwatch1.elapsedMilliseconds}ms');

      if (!hasInternet) {
        _addResult('❌ عدم دسترسی به شبکه - متوقف شدن تست');
        return;
      }

      // تست ۲: اتصال سرور اصلی
      _addResult('🌐 تست اتصال سرور...');
      final stopwatch2 = Stopwatch()..start();
      final serverConnected =
          await _connectionManager.testServerConnection('http://62.60.198.11');
      stopwatch2.stop();
      _addResult(
          '${serverConnected ? "✅" : "❌"} سرور: ${stopwatch2.elapsedMilliseconds}ms');

      // تست ۳: کش اتصال
      _addResult('💾 تست کش اتصال...');
      final stopwatch3 = Stopwatch()..start();
      final cachedResult = await _connectionManager
          .testServerConnection('http://62.60.198.11', useCache: true);
      stopwatch3.stop();
      _addResult(
          '${cachedResult ? "✅" : "❌"} کش: ${stopwatch3.elapsedMilliseconds}ms');

      // تست ۴: درخواست GET بهینه‌سازی شده
      _addResult('📡 تست درخواست GET...');
      final stopwatch4 = Stopwatch()..start();
      try {
        final response = await _connectionManager.get(
          'http://62.60.198.11/simple_xlsx_to_json.php?type=test',
          timeout: const Duration(seconds: 5),
        );
        stopwatch4.stop();
        _addResult(
            '✅ GET: ${response.statusCode} (${stopwatch4.elapsedMilliseconds}ms, ${response.bodyBytes.length} bytes)');
      } catch (e) {
        stopwatch4.stop();
        _addResult('❌ GET Error: ${stopwatch4.elapsedMilliseconds}ms - $e');
      }

      // تست ۵: همگام‌سازی کامل
      _addResult('🔄 تست همگام‌سازی...');
      final stopwatch5 = Stopwatch()..start();
      try {
        await _syncService.init();
        await _syncService.syncAllData();
        stopwatch5.stop();
        _addResult('✅ همگام‌سازی: ${stopwatch5.elapsedMilliseconds}ms');
      } catch (e) {
        stopwatch5.stop();
        _addResult(
            '❌ همگام‌سازی Error: ${stopwatch5.elapsedMilliseconds}ms - $e');
      }

      // نمایش وضعیت کش
      _addResult('📊 وضعیت کش:');
      final cacheStatus = _connectionManager.getCacheStatus();
      _addResult('   📋 تعداد: ${cacheStatus['total_entries']}');
      _addResult('   ⏰ Timeout: ${cacheStatus['cache_timeout_minutes']} دقیقه');

      _addResult('🎉 تست کامل شد!');
    } catch (e) {
      _addResult('💥 خطای کلی: $e');
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  void _clearCache() {
    _connectionManager.clearCache();
    _addResult('🗑️ کش پاک شد');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: Column(
        children: [
          PageHeader(
            title: 'تست عملکرد شبکه',
            onBackPressed: () => Navigator.pop(context),
          ),

          // دکمه‌های کنترل
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.boxOutlineColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTestRunning ? null : _runPerformanceTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isTestRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.speed),
                    label: Text(_isTestRunning ? 'در حال تست...' : 'شروع تست'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isTestRunning ? null : _clearResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.clear),
                  label: const Text('پاک کردن'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isTestRunning ? null : _clearCache,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('پاک کش'),
                ),
              ],
            ),
          ),

          // نتایج تست
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.boxOutlineColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'نتایج تست',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_testResults.length} خط',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _testResults.isEmpty
                        ? const Center(
                            child: Text(
                              'برای شروع، دکمه "شروع تست" را بزنید',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _testResults.length,
                            itemBuilder: (context, index) {
                              final result = _testResults[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  result,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: result.contains('❌')
                                        ? Colors.red[300]
                                        : result.contains('✅')
                                            ? Colors.green[300]
                                            : result.contains('⚠️')
                                                ? Colors.orange[300]
                                                : Colors.white70,
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
        ],
      ),
    );
  }
}
