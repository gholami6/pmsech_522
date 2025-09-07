import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/grade_service.dart';
import '../services/grade_api_service.dart';
import '../services/auth_service.dart';
import '../models/grade_data.dart';
import '../config/app_colors.dart';
import '../config/standard_page_config.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../services/equipment_location_service.dart';

class GradeListScreen extends StatefulWidget {
  const GradeListScreen({super.key});

  @override
  State<GradeListScreen> createState() => _GradeListScreenState();
}

class _GradeListScreenState extends State<GradeListScreen> {
  List<GradeData> _grades = [];
  bool _isLoading = true;
  String _selectedGradeType = 'همه';
  DateTime? _selectedDate;

  final List<String> _gradeTypes = ['همه', 'خوراک', 'محصول', 'باطله'];

  @override
  void initState() {
    super.initState();
    _loadGradesWithAutoSync();
  }

  /// بارگذاری عیارها با همگام‌سازی خودکار برای کاربران غیرمجاز
  Future<void> _loadGradesWithAutoSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // بررسی اینکه آیا کاربر مجاز است یا نه
      final authService = Provider.of<AuthService>(context, listen: false);
      final isUserAuthorized = true; // تمام کاربران دسترسی دارند

      // اگر کاربر غیرمجاز است، همگام‌سازی خودکار انجام بده
      if (!isUserAuthorized) {
        print('🔄 کاربر غیرمجاز - شروع همگام‌سازی خودکار...');
        try {
          await GradeService.downloadGradesFromServer();
          print('✅ همگام‌سازی خودکار تکمیل شد');
        } catch (e) {
          print('⚠️ خطا در همگام‌سازی خودکار: $e');
          // ادامه کار حتی اگر همگام‌سازی ناموفق بود
        }
      }

      final allGrades = await GradeService.getAllGradeData();

      // فیلتر بر اساس نوع عیار
      List<GradeData> filteredGrades = allGrades;
      if (_selectedGradeType != 'همه') {
        filteredGrades = allGrades
            .where((grade) => grade.gradeType == _selectedGradeType)
            .toList();
      }

      // فیلتر بر اساس تاریخ
      if (_selectedDate != null) {
        final selectedJalali = Jalali.fromDateTime(_selectedDate!);
        filteredGrades = filteredGrades
            .where((grade) =>
                grade.year == selectedJalali.year &&
                grade.month == selectedJalali.month &&
                grade.day == selectedJalali.day)
            .toList();
      }

      // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
      filteredGrades.sort((a, b) {
        final dateA = Jalali(a.year, a.month, a.day);
        final dateB = Jalali(b.year, b.month, b.day);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _grades = filteredGrades;
        _isLoading = false;
      });
    } catch (e) {
      print('خطا در بارگذاری عیارها: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allGrades = await GradeService.getAllGradeData();

      // فیلتر بر اساس نوع عیار
      List<GradeData> filteredGrades = allGrades;
      if (_selectedGradeType != 'همه') {
        filteredGrades = allGrades
            .where((grade) => grade.gradeType == _selectedGradeType)
            .toList();
      }

      // فیلتر بر اساس تاریخ
      if (_selectedDate != null) {
        final selectedJalali = Jalali.fromDateTime(_selectedDate!);
        filteredGrades = filteredGrades
            .where((grade) =>
                grade.year == selectedJalali.year &&
                grade.month == selectedJalali.month &&
                grade.day == selectedJalali.day)
            .toList();
      }

      // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
      filteredGrades.sort((a, b) {
        final dateA = Jalali(a.year, a.month, a.day);
        final dateB = Jalali(b.year, b.month, b.day);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _grades = filteredGrades;
        _isLoading = false;
      });
    } catch (e) {
      print('خطا در بارگذاری عیارها: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali(1400),
      lastDate: Jalali(1410),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked.toDateTime();
      });
      _loadGradesWithAutoSync();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _loadGradesWithAutoSync();
  }

  Future<void> _clearCacheAndSync() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // نمایش دیالوگ تایید
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تایید پاک کردن کش'),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید کش عیارها را پاک کرده و از سرور دانلود کنید؟\n\nاین کار ممکن است چند ثانیه طول بکشد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('تایید'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // پاک کردن کش و همگام‌سازی
      final success = await GradeService.forceClearAndSync();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کش پاک شد و داده‌ها از سرور دانلود شدند'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در پاک کردن کش یا دانلود از سرور'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // بارگذاری مجدد لیست
      _loadGrades();
    } catch (e) {
      print('خطا در پاک کردن کش: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageConfig.buildStandardPage(
      title: 'لیست عیارها',
      content: Column(
        children: [
          // فیلترها
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.boxOutlineColor),
            ),
            child: Column(
              children: [
                // فیلتر نوع عیار - دکمه‌های جداگانه
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'نوع عیار:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gradeTypes.map((type) {
                        final isSelected = _selectedGradeType == type;
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedGradeType = type;
                            });
                            _loadGradesWithAutoSync();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? AppColors.primaryBlue
                                : Colors.grey[200],
                            foregroundColor:
                                isSelected ? Colors.white : Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(type),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // فیلتر تاریخ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'تاریخ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedDate != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            Jalali.fromDateTime(_selectedDate!)
                                .formatCompactDate(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _clearDateFilter,
                            child: const Text('حذف فیلتر'),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: _selectDate,
                        child: const Text('انتخاب تاریخ'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // دکمه پاک کردن کش - برای همه کاربران
                if (true)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _clearCacheAndSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('پاک کردن کش و همگام‌سازی'),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // لیست عیارها
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _grades.isEmpty
                    ? const Center(
                        child: Text(
                          'هیچ عیاری یافت نشد',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _grades.length,
                        itemBuilder: (context, index) {
                          final grade = _grades[index];
                          return _buildGradeCard(grade);
                        },
                      ),
          ),
        ],
      ),
    );\n  }

  Widget _buildGradeCard(GradeData grade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.boxOutlineColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(
              grade.formattedGradeValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getGradeColor(grade.gradeType),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade.gradeTypeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'تاریخ: ${grade.fullShamsiDate} - شیفت: ${grade.shift}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  if (grade.equipmentId != null &&
                      grade.equipmentId!.isNotEmpty)
                    Text(
                      'محل باردهی: ${grade.equipmentId}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              _getGradeIcon(grade.gradeType),
              color: _getGradeColor(grade.gradeType),
              size: 24,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'ثبت شده توسط: ${grade.recordedBy}',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.end,
          ),
        ),
        trailing: true // تمام کاربران دسترسی دارند
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editGrade(grade);
                  } else if (value == 'delete') {
                    _deleteGrade(grade);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('ویرایش'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null, // کاربران غیرمجاز هیچ آیکنی نمی‌بینند
      ),
    );\n  }

  IconData _getGradeIcon(String gradeType) {
    switch (gradeType) {
      case 'خوراک':
        return Icons.input;
      case 'محصول':
        return Icons.output;
      case 'باطله':
        return Icons.delete_outline;
      default:
        return Icons.analytics;
    }
  }

  Color _getGradeColor(String gradeType) {
    switch (gradeType) {
      case 'خوراک':
        return AppColors.feedColor;
      case 'محصول':
        return AppColors.productColor;
      case 'باطله':
        return AppColors.tailingColor;
      default:
        return Colors.blue;
    }
  }

  void _editGrade(GradeData grade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradeEditScreen(grade: grade),
      ),
    ).then((_) {
      // بارگذاری مجدد لیست پس از ویرایش
      _loadGrades();
    });
  }

  void _deleteGrade(GradeData grade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف عیار'),
        content: Text('آیا از حذف عیار ${grade.gradeTypeName} اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(grade);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );\n  }

  Future<void> _confirmDelete(GradeData grade) async {
    try {
      print('=== شروع حذف عیار ===');
      print('شناسه عیار: ${grade.id}');
      print('تاریخ: ${grade.year}/${grade.month}/${grade.day}');
      print('نوع: ${grade.gradeType}');
      print('مقدار: ${grade.gradeValue}%');

      // ابتدا از سرور حذف کنیم
      bool serverDeleteSuccess = false;
      try {
        print('حذف از سرور...');
        final result = await GradeApiService.deleteGrade(
          year: grade.year,
          month: grade.month,
          day: grade.day,
          shift: grade.shift,
          gradeType: grade.gradeType,
          recordedBy: grade.recordedBy,
        );

        print('نتیجه حذف از سرور: $result');
        serverDeleteSuccess = result['success'] == true;

        if (serverDeleteSuccess) {
          print('✅ عیار از سرور حذف شد');
        } else {
          print('❌ خطا در حذف از سرور: ${result['message']}');
        }
      } catch (e) {
        print('❌ خطا در ارتباط با سرور: $e');
      }

      // سپس از دیتابیس محلی حذف کنیم
      print('حذف از دیتابیس محلی...');
      await GradeService.deleteGrade(grade.id);
      print('✅ عیار از دیتابیس محلی حذف شد');

      // اگر حذف از سرور ناموفق بود، پیام هشدار بدهیم
      if (!serverDeleteSuccess) {
        print('⚠️ عیار فقط از دیتابیس محلی حذف شد');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('عیار از برنامه حذف شد اما ممکن است در سرور باقی بماند'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('عیار با موفقیت حذف شد'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // بارگذاری مجدد لیست
      _loadGrades();
      print('=== پایان حذف عیار ===');
    } catch (e) {
      print('❌ خطا در حذف عیار: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف عیار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class GradeEditScreen extends StatefulWidget {
  final GradeData grade;

  const GradeEditScreen({super.key, required this.grade});

  @override
  State<GradeEditScreen> createState() => _GradeEditScreenState();
}

class _GradeEditScreenState extends State<GradeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _gradeController;
  late String _selectedGradeType;
  late int _selectedShift;
  late int _selectedWorkGroup;
  late String _selectedEquipmentId;
  bool _isLoading = false;

  final List<String> _gradeTypes = ['خوراک', 'محصول', 'باطله'];
  final List<int> _shifts = [1, 2, 3];
  final List<int> _workGroups = [1, 2, 3, 4];
  List<String> _equipmentIds = [];

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(
      text: widget.grade.gradeValue.toString(),
    );
    _selectedGradeType = widget.grade.gradeType;
    _selectedShift = widget.grade.shift;
    _selectedWorkGroup = widget.grade.workGroup;
    _selectedEquipmentId = widget.grade.equipmentId ?? '';
    _loadEquipmentLocations();
  }

  Future<void> _loadEquipmentLocations() async {
    try {
      await EquipmentLocationService.initialize();
      final locations = await EquipmentLocationService.getActiveLocationNames();
      setState(() {
        _equipmentIds = locations;
      });
    } catch (e) {
      print('خطا در بارگذاری محل‌های باردهی: $e');
      // استفاده از لیست پیش‌فرض در صورت خطا
      setState(() {
        _equipmentIds = ['G3-NEW', 'G3-OLD', 'SS', 'G5'];
      });
    }
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _updateGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      await GradeService.updateGrade(
        gradeId: widget.grade.id,
        year: widget.grade.year,
        month: widget.grade.month,
        day: widget.grade.day,
        shift: _selectedShift,
        gradeType: _selectedGradeType,
        gradeValue: double.parse(_gradeController.text),
        userId: currentUser.id,
        equipmentId: _selectedEquipmentId.isEmpty ? null : _selectedEquipmentId,
        workGroup: _selectedWorkGroup,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عیار با موفقیت آپدیت شد'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در آپدیت عیار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StandardPageConfig.buildStandardPage(
        title: 'ویرایش عیار',
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // اطلاعات فعلی
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.boxOutlineColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اطلاعات فعلی:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('تاریخ: ${widget.grade.fullShamsiDate}'),
                    Text('نوع عیار: ${widget.grade.gradeTypeName}'),
                    Text('مقدار: ${widget.grade.formattedGradeValue}'),
                    Text('شیفت: ${widget.grade.shift}'),
                    Text('گروه کاری: ${widget.grade.workGroup}'),
                    if (widget.grade.equipmentId != null &&
                        widget.grade.equipmentId!.isNotEmpty)
                      Text('محل باردهی: ${widget.grade.equipmentId}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // فرم ویرایش
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.boxOutlineColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ویرایش اطلاعات:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // نوع عیار
                    const Text('نوع عیار'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGradeType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _gradeTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGradeType = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً نوع عیار را انتخاب کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // مقدار عیار
                    const Text('مقدار عیار (%)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _gradeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixText: '%',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً مقدار عیار را وارد کنید';
                        }
                        final grade = double.tryParse(value);
                        if (grade == null) {
                          return 'لطفاً عدد معتبر وارد کنید';
                        }
                        if (grade < 0 || grade > 100) {
                          return 'مقدار باید بین 0 تا 100 باشد';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // شیفت
                    const Text('شیفت'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedShift,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _shifts
                          .map((shift) => DropdownMenuItem(
                                value: shift,
                                child: Text('شیفت $shift'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedShift = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // گروه کاری
                    const Text('گروه کاری'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedWorkGroup,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _workGroups
                          .map((group) => DropdownMenuItem(
                                value: group,
                                child: Text('گروه $group'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWorkGroup = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // محل باردهی
                    const Text('محل باردهی'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEquipmentId.isEmpty
                          ? null
                          : _selectedEquipmentId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        hintText: 'انتخاب محل باردهی',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('بدون محل باردهی'),
                        ),
                        ..._equipmentIds.map((equipment) => DropdownMenuItem(
                              value: equipment,
                              child: Text(equipment),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEquipmentId = value ?? '';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // دکمه‌ها
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('انصراف'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateGrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('آپدیت'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );\n  }
}

