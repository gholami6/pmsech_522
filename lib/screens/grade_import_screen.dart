import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/grade_import_service.dart';

class GradeImportScreen extends StatefulWidget {
  const GradeImportScreen({super.key});

  @override
  State<GradeImportScreen> createState() => _GradeImportScreenState();
}

class _GradeImportScreenState extends State<GradeImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // برای بخش اول (عیار روزانه/شیفتی)
  final TextEditingController _csvController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _importResult;

  // برای بخش دوم (میانگین ماهیانه)
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _feedGradeController = TextEditingController();
  final TextEditingController _productGradeController = TextEditingController();
  final TextEditingController _wasteGradeController = TextEditingController();
  bool _isLoadingMonthly = false;
  Map<String, dynamic>? _monthlyImportResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _csvController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _feedGradeController.dispose();
    _productGradeController.dispose();
    _wasteGradeController.dispose();
    super.dispose();
  }

  // توابع بخش اول (عیار روزانه/شیفتی)
  Future<void> _importData() async {
    if (_csvController.text.trim().isEmpty) {
      _showMessage('لطفاً داده‌های CSV را وارد کنید', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _importResult = null;
    });

    try {
      final result = await GradeImportService.importGradeDataFromString(
        _csvController.text,
      );

      setState(() {
        _importResult = result;
      });

      if (result['success']) {
        _showMessage(
          '${result['imported_count']} رکورد با موفقیت وارد شد',
          isError: false,
        );
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('خطا در وارد کردن داده‌ها: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // وارد کردن داده‌ها با فرمت صحیح (چندین عیار در هر شیفت)
  Future<void> _importMultipleGradesData() async {
    if (_csvController.text.trim().isEmpty) {
      _showMessage('لطفاً داده‌های CSV را وارد کنید', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _importResult = null;
    });

    try {
      final result = await GradeImportService.importMultipleGradesPerShift(
        csvString: _csvController.text,
        clearExisting: true, // پاک کردن داده‌های قبلی
      );

      setState(() {
        _importResult = result;
      });

      if (result['success']) {
        _showMessage(
          '${result['imported_count']} رکورد عیار با فرمت صحیح وارد شد',
          isError: false,
        );
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('خطا در وارد کردن داده‌ها: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // توابع بخش دوم (میانگین ماهیانه)
  Future<void> _importMonthlyAverage() async {
    // اعتبارسنجی ورودی‌ها
    if (_yearController.text.trim().isEmpty ||
        _monthController.text.trim().isEmpty) {
      _showMessage('لطفاً سال و ماه را وارد کنید', isError: true);
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    final month = int.tryParse(_monthController.text.trim());

    if (year == null || year < 1380 || year > 1450) {
      _showMessage('سال نامعتبر (باید بین 1380-1450 باشد)', isError: true);
      return;
    }

    if (month == null || month < 1 || month > 12) {
      _showMessage('ماه نامعتبر (باید بین 1-12 باشد)', isError: true);
      return;
    }

    final feedGrade = double.tryParse(_feedGradeController.text.trim());
    final productGrade = double.tryParse(_productGradeController.text.trim());
    final wasteGrade = double.tryParse(_wasteGradeController.text.trim());

    if (feedGrade == null || productGrade == null || wasteGrade == null) {
      _showMessage('لطفاً تمام عیارها را به صورت عدد وارد کنید', isError: true);
      return;
    }

    if (feedGrade < 0 ||
        feedGrade > 100 ||
        productGrade < 0 ||
        productGrade > 100 ||
        wasteGrade < 0 ||
        wasteGrade > 100) {
      _showMessage('عیارها باید بین 0 تا 100 باشند', isError: true);
      return;
    }

    setState(() {
      _isLoadingMonthly = true;
      _monthlyImportResult = null;
    });

    try {
      final monthlyAverages = {
        'خوراک': feedGrade,
        'محصول': productGrade,
        'باطله': wasteGrade,
      };

      final result = await GradeImportService.importMonthlyAverageGrades(
        monthlyAverages: monthlyAverages,
        year: year,
        month: month,
        overrideExisting: false,
      );

      setState(() {
        _monthlyImportResult = result;
      });

      if (result['success']) {
        _showMessage(
          'میانگین ماهیانه $year/$month با موفقیت وارد شد (${result['imported_count']} رکورد)',
          isError: false,
        );
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('خطا در وارد کردن میانگین ماهیانه: ${e.toString()}',
          isError: true);
    } finally {
      setState(() {
        _isLoadingMonthly = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSampleFormat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نمونه فرمت CSV'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'فرمت 1: کامل (با ستون تاریخ)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  GradeImportService.getSampleCSVFormat(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'فرمت 2: ساده (بدون ستون تاریخ)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  GradeImportService.getSimpleCSVFormat(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'فرمت 3: روزانه (میانگین روزانه)',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  GradeImportService.getDailyAverageFormat(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'فرمت 4: چندین عیار در هر شیفت (صحیح)',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Text(
                  GradeImportService.getMultipleGradesPerShiftFormat(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: GradeImportService.getSimpleCSVFormat(),
              ));
              Navigator.of(context).pop();
              _showMessage('فرمت ساده کپی شد', isError: false);
            },
            child: const Text('کپی فرمت ساده'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: GradeImportService.getDailyAverageFormat(),
              ));
              Navigator.of(context).pop();
              _showMessage('فرمت روزانه کپی شد', isError: false);
            },
            child: const Text('کپی فرمت روزانه'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: GradeImportService.getMultipleGradesPerShiftFormat(),
              ));
              Navigator.of(context).pop();
              _showMessage('فرمت چندین عیار کپی شد', isError: false);
            },
            child: const Text('کپی فرمت صحیح'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.purple,
              backgroundColor: Colors.purple[50],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وارد کردن داده‌های عیار'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.view_list),
              text: 'عیار روزانه/شیفتی',
            ),
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'میانگین ماهیانه',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyImportTab(),
          _buildMonthlyImportTab(),
        ],
      ),
    );
  }

  Widget _buildDailyImportTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // راهنما
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'راهنمای وارد کردن داده‌ها',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '۱. فایل اکسل خود را باز کنید\n'
                    '۲. داده‌ها را انتخاب و کپی کنید\n'
                    '۳. در کادر زیر Paste کنید\n'
                    '۴. روی "وارد کردن داده‌ها" کلیک کنید',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // فیلد ورودی
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'داده‌های CSV:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showSampleFormat,
                          icon: const Icon(Icons.help, size: 16),
                          label: const Text('مشاهده نمونه'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: _csvController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'داده‌های اکسل را اینجا Paste کنید...\n\n'
                              'مثال (روزانه):\n'
                              '1403,10,1,خوراک,0.85\n'
                              '1403,10,1,محصول,0.42\n'
                              '1403,10,1,باطله,0.15\n\n'
                              'یا (شیفتی):\n'
                              '1403,10,1,1,خوراک,0.85',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // دکمه‌های عملیات
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _importData,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload),
                      label: Text(_isLoading
                          ? 'در حال پردازش...'
                          : 'وارد کردن (فرمت قدیم)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _csvController.clear();
                      setState(() {
                        _importResult = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('پاک کردن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importMultipleGradesData,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.science),
                  label: Text(_isLoading
                      ? 'در حال پردازش...'
                      : 'وارد کردن (فرمت صحیح - چندین عیار در شیفت)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          // نتیجه
          if (_importResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_importResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyImportTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // راهنما
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'میانگین ماهیانه برای ماه‌های قبل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'برای ماه‌هایی که فقط میانگین ماهیانه دارید:\n'
                    '• میانگین هر نوع عیار را وارد کنید\n'
                    '• این مقدار برای تمام روزهای آن ماه تکرار می‌شود\n'
                    '• برای هر روز، 3 شیفت با همان مقدار ثبت می‌شود',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // فرم ورودی
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تاریخ ماه:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // تاریخ
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سال (مثال: 1402)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _monthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ماه (1-12)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // عیارها
                    const Text(
                      'میانگین عیارهای ماهیانه:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _feedGradeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'عیار خوراک (مثال: 35.65)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _productGradeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'عیار محصول (مثال: 42.30)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _wasteGradeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'عیار باطله (مثال: 12.10)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // دکمه‌های عملیات
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingMonthly
                                ? null
                                : _importMonthlyAverage,
                            icon: _isLoadingMonthly
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.calendar_month),
                            label: Text(_isLoadingMonthly
                                ? 'در حال پردازش...'
                                : 'وارد کردن میانگین ماهیانه'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _yearController.clear();
                            _monthController.clear();
                            _feedGradeController.clear();
                            _productGradeController.clear();
                            _wasteGradeController.clear();
                            setState(() {
                              _monthlyImportResult = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('پاک کردن'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // نتیجه
          if (_monthlyImportResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_monthlyImportResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    return Card(
      color: result['success'] ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result['success'] ? Icons.check_circle : Icons.error,
                  color: result['success'] ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'نتیجه عملیات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        result['success'] ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('پیام: ${result['message']}'),
            Text('تعداد وارد شده: ${result['imported_count']}'),
            if (result['skip_count'] != null && result['skip_count'] > 0)
              Text('تعداد رد شده: ${result['skip_count']}'),
            if (result['error_count'] != null && result['error_count'] > 0)
              Text('تعداد خطا: ${result['error_count']}'),

            // نمایش جزئیات میانگین ماهیانه
            if (result['month_info'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                'جزئیات:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'ماه: ${result['month_info']['year']}/${result['month_info']['month']}'),
              Text(
                  'تعداد روزهای ماه: ${result['month_info']['days_in_month']}'),
              if (result['month_info']['averages'] != null) ...[
                const Text('میانگین‌های وارد شده:'),
                for (final entry
                    in (result['month_info']['averages'] as Map).entries)
                  Text('  ${entry.key}: ${entry.value}%'),
              ],
            ],

            // نمایش خطاها
            if (result['errors'] != null &&
                (result['errors'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'خطاها:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                height: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  itemCount: (result['errors'] as List).length,
                  itemBuilder: (context, index) {
                    return Text(
                      '${index + 1}. ${result['errors'][index]}',
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
