import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatefulWidget {
  final File pdfFile;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.pdfFile,
    required this.title,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isLoading = true;
  String? _error;
  bool _showPreview = true; // حالت پیش‌نمایش

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    try {
      if (await widget.pdfFile.exists()) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'فایل PDF یافت نشد';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری فایل: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    try {
      // فعلاً فقط پیام نمایش می‌دهیم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('اشتراک‌گذاری گزارش ${widget.title}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در اشتراک‌گذاری: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    try {
      // فعلاً فقط پیام نمایش می‌دهیم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('پرینت گزارش ${widget.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پرینت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToDownloads({bool askUser = false}) async {
    try {
      String? outputDirectory;
      // حذف بخش انتخاب مسیر کاربر
      // مسیر پیش‌فرض Downloads
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          outputDirectory = dir.path;
        } else {
          // حالت fallback
          outputDirectory = (await getExternalStorageDirectory())?.path;
        }
      } else {
        outputDirectory = (await getDownloadsDirectory())?.path;
      }
      if (outputDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مسیر ذخیره پیدا نشد!')),
        );
        return;
      }

      final fileName =
          'feed_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final newFile = File('$outputDirectory/$fileName');

      await widget.pdfFile.copy(newFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فایل ذخیره شد: ${newFile.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'باز کردن',
              onPressed: () async {
                // حذف شد: await OpenFile.open(newFile.path);
                // نمایش پیام ساده
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فایل در ${newFile.path} ذخیره شد')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره فایل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          actions: [
            // دکمه تغییر حالت پیش‌نمایش
            IconButton(
              onPressed: _togglePreview,
              icon: Icon(
                  _showPreview ? Icons.info_outline : Icons.picture_as_pdf),
              tooltip: _showPreview ? 'نمایش اطلاعات' : 'پیش‌نمایش PDF',
            ),
            IconButton(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              tooltip: 'اشتراک‌گذاری',
            ),
            IconButton(
              onPressed: _printPdf,
              icon: const Icon(Icons.print),
              tooltip: 'پرینت',
            ),
            IconButton(
              onPressed: _saveToDownloads,
              icon: const Icon(Icons.download),
              tooltip: 'ذخیره در دانلود',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('بازگشت'),
                        ),
                      ],
                    ),
                  )
                : _showPreview
                    ? _buildPdfPreview()
                    : _buildInfoView(),
        floatingActionButton: null,
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // هدر پیش‌نمایش
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'پیش‌نمایش گزارش PDF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${(widget.pdfFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // محتوای پیش‌نمایش
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // آیکون PDF
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),

                  // اطلاعات فایل
                  Text(
                    'فایل PDF آماده است',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نام فایل: ${widget.pdfFile.path.split('/').last}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اندازه: ${(widget.pdfFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // دکمه‌های عملیات
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.share),
                          label: const Text('اشتراک‌گذاری'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _printPdf,
                          icon: const Icon(Icons.print),
                          label: const Text('پرینت'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveToDownloads,
                          icon: const Icon(Icons.download),
                          label: const Text('ذخیره در دانلود'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // هدر اطلاعات
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اطلاعات فایل PDF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // محتوای اطلاعات
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      'نام فایل:', widget.pdfFile.path.split('/').last),
                  const SizedBox(height: 12),
                  _buildInfoRow('اندازه:',
                      '${(widget.pdfFile.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                  const SizedBox(height: 12),
                  _buildInfoRow('مسیر:', widget.pdfFile.path),
                  const SizedBox(height: 12),
                  _buildInfoRow('تاریخ ایجاد:',
                      DateTime.now().toString().substring(0, 19)),
                  const SizedBox(height: 12),
                  _buildInfoRow('نوع فایل:', 'PDF'),
                  const SizedBox(height: 12),
                  _buildInfoRow('وضعیت:', 'آماده'),

                  const Spacer(),

                  // دکمه‌های عملیات
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.share),
                          label: const Text('اشتراک‌گذاری'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _printPdf,
                          icon: const Icon(Icons.print),
                          label: const Text('پرینت'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveToDownloads,
                          icon: const Icon(Icons.download),
                          label: const Text('ذخیره در دانلود'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
