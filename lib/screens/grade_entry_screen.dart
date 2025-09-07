import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/grade_service.dart';
import '../services/auth_service.dart';
import '../services/equipment_location_service.dart';
// removed unused: import '../widgets/page_header.dart';
import '../config/app_colors.dart';
import '../config/standard_page_config.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  int _selectedYear = 1404;
  int _selectedMonth = 4;
  int _selectedDay = 1;
  int _selectedShift = 1;
  int _selectedWorkGroup = 1;

  bool _isLoading = false;

  final List<String> _gradeTypes = ['خوراک', 'محصول', 'باطله'];
  final List<int> _shifts = [1, 2, 3];
  final List<int> _workGroups = [1, 2, 3, 4];

  // لیست محل‌های خوراک‌دهی
  List<String> _feedLocations = ['G3-NEW', 'G3-OLD', 'SS', 'G5'];

  // لیست نمونه‌های عیار برای ثبت
  final List<GradeSample> _gradeSamples = [];

  @override
  void initState() {
    super.initState();
    // اضافه کردن یک نمونه پیش‌فرض
    _addGradeSample();
    // بارگذاری محل‌های باردهی
    _loadEquipmentLocations();
  }

  Future<void> _loadEquipmentLocations() async {
    try {
      await EquipmentLocationService.initialize();
      final locations = await EquipmentLocationService.getActiveLocationNames();
      setState(() {
        _feedLocations = locations;
      });
    } catch (e) {
      print('خطا در بارگذاری محل‌های باردهی: $e');
      // استفاده از لیست پیش‌فرض در صورت خطا
      setState(() {
        _feedLocations = ['G 3-NEW', 'G 3-OLD', 'S S', 'G 5'];
      });
    }
  }

  @override
  void dispose() {
    // پاک کردن کنترلرهای نمونه‌ها
    for (final sample in _gradeSamples) {
      sample.dispose();
    }
    super.dispose();
  }

  void _addGradeSample() {
    setState(() {
      final sample = GradeSample();
      sample.gradeType = 'خوراک'; // پیش‌فرض خوراک
      _gradeSamples.add(sample);
    });
  }

  void _removeGradeSample(int index) {
    if (_gradeSamples.length > 1) {
      setState(() {
        _gradeSamples.removeAt(index);
      });
    }
  }

  Future<void> _submitGrades() async {
    if (!_formKey.currentState!.validate()) return;

    // بررسی اینکه حداقل یک نمونه معتبر وجود دارد
    bool hasValidSample = false;
    for (final sample in _gradeSamples) {
      if (sample.gradeType.isNotEmpty && sample.gradeValue > 0) {
        hasValidSample = true;
        break;
      }
    }

    if (!hasValidSample) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً حداقل یک نمونه عیار معتبر وارد کنید'),
          backgroundColor: AppColors.tailingColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      int successCount = 0;
      int errorCount = 0;

      // ثبت هر نمونه عیار
      for (int i = 0; i < _gradeSamples.length; i++) {
        final sample = _gradeSamples[i];

        // فقط نمونه‌های معتبر را ثبت کن
        if (sample.gradeType.isNotEmpty && sample.gradeValue > 0) {
          try {
            await GradeService.recordGrade(
              year: _selectedYear,
              month: _selectedMonth,
              day: _selectedDay,
              shift: _selectedShift,
              gradeType: sample.gradeType,
              gradeValue: sample.gradeValue,
              userId: currentUser.id,
              equipmentId:
                  sample.feedLocation.isEmpty ? null : sample.feedLocation,
              workGroup: _selectedWorkGroup,
            );
            successCount++;
          } catch (e) {
            errorCount++;
            print('خطا در ثبت نمونه ${i + 1}: $e');
          }
        }
      }

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount نمونه عیار با موفقیت ثبت شد'),
              backgroundColor: AppColors.stopsAccentGreen,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در ثبت عیارها: $errorCount خطا'),
              backgroundColor: AppColors.tailingColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت عیار: $e'),
            backgroundColor: AppColors.tailingColor,
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
        title: 'ثبت عیار',
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // کارت اطلاعات شیفت
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.stopsCardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.boxOutlineColor,
                      width: 1,
                    ),
                    boxShadow: [AppColors.boxShadow],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اطلاعات شیفت',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.stopsTextPrimary,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // انتخاب سال
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('سال'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _selectedYear,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.stopsAccentBlue,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    items: List.generate(
                                            5, (index) => 1402 + index)
                                        .map((year) => DropdownMenuItem(
                                              value: year,
                                              child: Text(year.toString()),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedYear = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // انتخاب ماه
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ماه'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _selectedMonth,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.stopsAccentBlue,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    items:
                                        List.generate(12, (index) => index + 1)
                                            .map((month) => DropdownMenuItem(
                                                  value: month,
                                                  child: Text(month.toString()),
                                                ))
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMonth = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // انتخاب روز
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('روز'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _selectedDay,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.stopsAccentBlue,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    items:
                                        List.generate(31, (index) => index + 1)
                                            .map((day) => DropdownMenuItem(
                                                  value: day,
                                                  child: Text(day.toString()),
                                                ))
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDay = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // انتخاب شیفت و گروه کاری
                        Row(
                          children: [
                            // انتخاب شیفت
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('شیفت'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _selectedShift,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.stopsAccentBlue,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // انتخاب گروه کاری
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('گروه کاری'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _selectedWorkGroup,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.boxOutlineColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.stopsAccentBlue,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // کارت نمونه‌های عیار
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.stopsCardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.boxOutlineColor,
                      width: 1,
                    ),
                    boxShadow: [AppColors.boxShadow],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'نمونه‌های عیار',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.stopsTextPrimary,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: _addGradeSample,
                              icon: const Icon(Icons.add,
                                  color: AppColors.stopsAccentBlue),
                              label: const Text('افزودن نمونه',
                                  style: TextStyle(
                                      color: AppColors.stopsAccentBlue)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // لیست نمونه‌های عیار
                        ...List.generate(_gradeSamples.length, (index) {
                          final sample = _gradeSamples[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.boxOutlineColor,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'نمونه ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.stopsTextPrimary,
                                          ),
                                        ),
                                        if (_gradeSamples.length > 1)
                                          IconButton(
                                            onPressed: () =>
                                                _removeGradeSample(index),
                                            icon: const Icon(Icons.delete,
                                                color: AppColors.tailingColor),
                                            iconSize: 20,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // سه باکس در یک ردیف: نوع عیار، درصد عیار، محل خوراک‌دهی
                                    Row(
                                      children: [
                                        // نوع عیار
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('نوع عیار'),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                value: sample.gradeType.isEmpty
                                                    ? null
                                                    : sample.gradeType,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .boxOutlineColor,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .boxOutlineColor,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .stopsAccentBlue,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey[50],
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                ),
                                                items: _gradeTypes
                                                    .map((type) =>
                                                        DropdownMenuItem(
                                                          value: type,
                                                          child: Text(type),
                                                        ))
                                                    .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    sample.gradeType =
                                                        value ?? '';
                                                  });
                                                },
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'لطفاً نوع عیار را انتخاب کنید';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // درصد عیار
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('درصد عیار'),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller:
                                                    sample.gradeController,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .boxOutlineColor,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .boxOutlineColor,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .stopsAccentBlue,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey[50],
                                                  hintText: '0.0',
                                                  suffixText: '%',
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 8),
                                                ),
                                                onChanged: (value) {
                                                  sample.gradeValue =
                                                      double.tryParse(value) ??
                                                          0;
                                                },
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'لطفاً درصد عیار را وارد کنید';
                                                  }
                                                  final doubleValue =
                                                      double.tryParse(value);
                                                  if (doubleValue == null) {
                                                    return 'لطفاً عدد معتبر وارد کنید';
                                                  }
                                                  if (doubleValue < 0 ||
                                                      doubleValue > 100) {
                                                    return 'درصد عیار باید بین 0 تا 100 باشد';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // محل خوراک‌دهی
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('محل خوراک‌دهی'),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                value:
                                                    sample.feedLocation.isEmpty
                                                        ? null
                                                        : sample.feedLocation,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .boxOutlineColor,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .boxOutlineColor,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: AppColors
                                                          .stopsAccentBlue,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey[50],
                                                  hintText: 'انتخاب کنید',
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                ),
                                                items: _feedLocations
                                                    .map((loc) =>
                                                        DropdownMenuItem(
                                                          value: loc,
                                                          child: Text(
                                                            loc,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ))
                                                    .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    sample.feedLocation =
                                                        value ?? '';
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // دکمه ثبت
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitGrades,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stopsAccentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'ثبت ${_gradeSamples.length} نمونه عیار',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// کلاس برای نگهداری اطلاعات هر نمونه عیار
class GradeSample {
  String gradeType = '';
  double gradeValue = 0;
  final TextEditingController gradeController = TextEditingController();
  String feedLocation = '';

  void dispose() {
    gradeController.dispose();
  }
}
