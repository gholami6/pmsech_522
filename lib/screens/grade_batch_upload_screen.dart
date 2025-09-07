import 'package:flutter/material.dart';
import '../services/grade_batch_upload_service.dart';
import '../config/app_colors.dart';

class GradeBatchUploadScreen extends StatefulWidget {
  const GradeBatchUploadScreen({super.key});

  @override
  State<GradeBatchUploadScreen> createState() => _GradeBatchUploadScreenState();
}

class _GradeBatchUploadScreenState extends State<GradeBatchUploadScreen> {
  bool _isUploading = false;
  bool _isCheckingConnection = false;
  String _statusMessage = '';
  bool _clearExisting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('آپلود دسته‌ای عیارها'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // کارت اطلاعات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'آپلود دسته‌ای داده‌های عیار',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'این عملیات تمام داده‌های عیار موجود در فایل CSV را به سرور آپلود می‌کند.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // گزینه پاک کردن داده‌های قبلی
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _clearExisting,
                    onChanged: (value) {
                      setState(() {
                        _clearExisting = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'پاک کردن داده‌های قبلی قبل از آپلود',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // دکمه‌های عملیات
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingConnection ? null : _checkConnection,
                    icon: _isCheckingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi),
                    label: Text(
                        _isCheckingConnection ? 'بررسی...' : 'بررسی اتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadGrades,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isUploading ? 'آپلود...' : 'آپلود عیارها'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // نمایش وضعیت
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('موفقیت') ||
                          _statusMessage.contains('اتصال')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusMessage.contains('موفقیت') ||
                            _statusMessage.contains('اتصال')
                        ? Colors.green
                        : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: _statusMessage.contains('موفقیت') ||
                            _statusMessage.contains('اتصال')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isCheckingConnection = true;
      _statusMessage = '';
    });

    try {
      final isConnected = await GradeBatchUploadService.checkServerConnection();

      setState(() {
        _statusMessage = isConnected
            ? '✅ اتصال به سرور برقرار است'
            : '❌ اتصال به سرور برقرار نیست';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ خطا در بررسی اتصال: $e';
      });
    } finally {
      setState(() {
        _isCheckingConnection = false;
      });
    }
  }

  Future<void> _uploadGrades() async {
    setState(() {
      _isUploading = true;
      _statusMessage = '';
    });

    try {
      final result = await GradeBatchUploadService.uploadGradesFromCsv(
        clearExisting: _clearExisting,
      );

      setState(() {
        if (result['success']) {
          _statusMessage = '✅ ${result['message']}\n'
              'تعداد رکوردهای آپلود شده: ${result['uploaded_count']}';
        } else {
          _statusMessage = '❌ ${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ خطا در آپلود: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
