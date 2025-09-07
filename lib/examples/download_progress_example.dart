import 'package:flutter/material.dart';
import '../widgets/professional_download_progress.dart';
import 'dart:async';

class DownloadProgressExample extends StatefulWidget {
  const DownloadProgressExample({super.key});

  @override
  State<DownloadProgressExample> createState() => _DownloadProgressExampleState();
}

class _DownloadProgressExampleState extends State<DownloadProgressExample> {
  double _progress = 0.0;
  bool _isDownloading = false;
  Timer? _progressTimer;

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _isDownloading = false;
        }
      });
    });
  }

  void _cancelDownload() {
    _progressTimer?.cancel();
    setState(() {
      _isDownloading = false;
      _progress = 0.0;
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال نوار پیشرفت دانلود'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // محتوای اصلی
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'برای شروع دانلود کلیک کنید',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isDownloading ? null : _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'شروع دانلود',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // نوار پیشرفت دانلود
          if (_isDownloading)
            ProfessionalDownloadProgress(
              progress: _progress,
              fileName: 'گزارش_تولید_ماهانه_1404.pdf',
              status: 'در حال دانلود...',
              onCancel: _cancelDownload,
            ),
        ],
      ),
    );
  }
}
