import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import '../services/document_upload_service.dart';
import '../services/equipment_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/stop_data.dart';
import '../models/production_data.dart';
import '../config/app_colors.dart';
import '../config/standard_page_config.dart';
import '../config/box_configs.dart';
import '../widgets/page_header.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({Key? key}) : super(key: key);

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  File? selectedFile;
  String description = '';
  String selectedCategory = 'نامه‌های ارسالی';
  String selectedEquipment = '';
  bool isPublic = true;
  bool isUploading = false;
  String? errorMessage;
  String? successMessage;

  final List<String> categories = [
    'نامه‌های ارسالی',
    'مدارک عمومی',
    'تولید',
    'توقفات',
    'کیفیت',
    'تعمیرات',
    'آموزش',
    'سایر'
  ];

  List<String> equipments = [];

  @override
  void initState() {
    super.initState();
    // استخراج تجهیزات از دیتابیس
    _loadEquipments();
  }

  Future<void> _loadEquipments() async {
    try {
      // ابتدا از StopData تجهیزات را استخراج کن
      final stopDataBox = Hive.box<StopData>('stopDataBox');
      final stopDataEquipments = stopDataBox.values
          .map((e) => e.equipment)
          .where((e) => e.isNotEmpty)
          .toSet();

      // سپس از ProductionData تجهیزات را استخراج کن
      final productionBox = Hive.box<ProductionData>('productionData');
      final productionEquipments = productionBox.values
          .map((e) => e.equipmentName)
          .where((e) => e.isNotEmpty)
          .toSet();

      // ترکیب تجهیزات از هر دو منبع
      final allEquipments = <String>{};
      allEquipments.addAll(stopDataEquipments);
      allEquipments.addAll(productionEquipments);

      setState(() {
        equipments = allEquipments.toList()..sort();
        // اضافه کردن گزینه "سایر" در انتها
        if (!equipments.contains('سایر')) {
          equipments.add('سایر');
        }
      });

      print(
          'DocumentUploadScreen: Loaded ${equipments.length} equipments from database');
      print('DocumentUploadScreen: Equipments: $equipments');
    } catch (e) {
      print('DocumentUploadScreen: Error loading equipments: $e');
      // در صورت خطا، لیست پیش‌فرض استفاده کن
      setState(() {
        equipments = [
          'خط یک',
          'خط دو',
          'سنگ شکن',
          'تلشکی',
          'سرند',
          'بی سنگی',
          'تعویض شیفت',
          'سایر'
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageConfig.buildStandardPage(
      title: 'آپلود فایل جدید',
      content: Padding(
        padding: StandardPageConfig.mainContainerPadding,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // فایل انتخاب شده
              _buildFileSelectionCard(),
              const SizedBox(height: 12),

              // فرم آپلود
              _buildUploadForm(),
              const SizedBox(height: 12),

              // دکمه آپلود
              _buildUploadButton(),
              const SizedBox(height: 12),

              // پیام‌های خطا و موفقیت
              if (errorMessage != null) _buildErrorMessage(),
              if (successMessage != null) _buildSuccessMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BorderRadiusStandards.contentCard),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // راست چین
          children: [
            // عنوان باکس
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: const Color(0x4D9E9E9E),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // راست چین
                children: [
                  Text(
                    'انتخاب فایل',
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.file_upload,
                      color: AppColors.stopsAppBar, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius:
                      BorderRadius.circular(BorderRadiusStandards.input),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, // راست چین
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end, // راست چین
                        children: [
                          Text(
                            selectedFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.end,
                          ),
                          Text(
                            DocumentUploadService.formatFileSize(
                                selectedFile!.lengthSync()),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          selectedFile = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius:
                      BorderRadius.circular(BorderRadiusStandards.input),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'برای انتخاب فایل کلیک کنید',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حداکثر حجم: 50 مگابایت',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('انتخاب فایل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stopsAppBar,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(BorderRadiusStandards.button),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BorderRadiusStandards.contentCard),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // راست چین
          children: [
            // عنوان باکس
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: const Color(0x4D9E9E9E),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // راست چین
                children: [
                  Text(
                    'اطلاعات فایل',
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, color: AppColors.stopsAppBar, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // توضیحات و دسته‌بندی
            Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.end, // راست چین
                    textDirection: TextDirection.rtl, // راست به چپ
                    decoration: InputDecoration(
                      labelText: 'توضیحات (اختیاری)',
                      hintText: 'توضیحات مربوط به فایل را وارد کنید...',
                      hintTextDirection: TextDirection.rtl, // راست به چپ
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(BorderRadiusStandards.input),
                      ),
                      prefixIcon: const Icon(Icons.description, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      alignLabelWithHint: true, // تراز برچسب با متن
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      setState(() {
                        description = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'دسته‌بندی',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(BorderRadiusStandards.input),
                      ),
                      prefixIcon: const Icon(Icons.category, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      alignLabelWithHint: true, // تراز برچسب با متن
                    ),
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 11),
                          textDirection: TextDirection.rtl, // راست به چپ
                          textAlign: TextAlign.end, // راست چین
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                        // اگر دسته‌بندی "نامه‌های ارسالی" انتخاب شد، تجهیز را اجباری کن
                        if (value == 'نامه‌های ارسالی' &&
                            selectedEquipment.isEmpty) {
                          selectedEquipment = equipments.isNotEmpty
                              ? equipments.first
                              : 'خط یک'; // مقدار پیش‌فرض
                        }
                        // اگر دسته‌بندی تغییر کرد و تجهیز انتخاب شده در لیست جدید نیست، آن را ریست کن
                        if (value != 'نامه‌های ارسالی') {
                          selectedEquipment = '';
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // انتخاب تجهیز (فقط برای نامه‌های ارسالی)
            if (selectedCategory == 'نامه‌های ارسالی')
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'تجهیز *',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(BorderRadiusStandards.input),
                  ),
                  prefixIcon: const Icon(Icons.build, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  alignLabelWithHint: true, // تراز برچسب با متن
                ),
                value: selectedEquipment.isEmpty ? null : selectedEquipment,
                items: equipments.map((equipment) {
                  return DropdownMenuItem(
                    value: equipment,
                    child: Text(
                      equipment,
                      style: const TextStyle(fontSize: 11),
                      textDirection: TextDirection.rtl, // راست به چپ
                      textAlign: TextAlign.end, // راست چین
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEquipment = value!;
                  });
                },
                validator: (value) {
                  if (selectedCategory == 'نامه‌های ارسالی' &&
                      (value == null || value.isEmpty)) {
                    return 'انتخاب تجهیز برای نامه‌های ارسالی اجباری است';
                  }
                  return null;
                },
              ),
            if (selectedCategory == 'نامه‌های ارسالی')
              const SizedBox(height: 12),

            // عمومی/خصوصی
            SwitchListTile(
              title: const Text('فایل عمومی', style: TextStyle(fontSize: 12)),
              subtitle: const Text('همه کاربران می‌توانند این فایل را ببینند',
                  style: TextStyle(fontSize: 10)),
              value: isPublic,
              onChanged: (value) {
                setState(() {
                  isPublic = value;
                });
              },
              activeColor: AppColors.stopsAppBar,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: selectedFile != null && !isUploading ? _uploadFile : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.stopsAppBar,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusStandards.button),
        ),
      ),
      child: isUploading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('در حال آپلود...'),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload),
                SizedBox(width: 8),
                Text(
                  'آپلود فایل',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(BorderRadiusStandards.input),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // راست چین
        children: [
          Icon(Icons.error, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.end,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(BorderRadiusStandards.input),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // راست چین
        children: [
          Icon(Icons.check_circle, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              successMessage!,
              style: TextStyle(color: Colors.green[700]),
              textAlign: TextAlign.end,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                successMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'gif'
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        // بررسی حجم فایل
        final fileSize = await file.length();
        if (fileSize > 50 * 1024 * 1024) {
          _showError('حجم فایل بیش از 50 مگابایت است');
          return;
        }

        setState(() {
          selectedFile = file;
          errorMessage = null;
          successMessage = null;
        });
      }
    } catch (e) {
      _showError('خطا در انتخاب فایل: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (selectedFile == null) return;

    setState(() {
      isUploading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        _showError('کاربر وارد نشده است');
        return;
      }

      // بررسی اجباری بودن انتخاب تجهیز برای نامه‌های ارسالی
      if (selectedCategory == 'نامه‌های ارسالی' && selectedEquipment.isEmpty) {
        _showError('انتخاب تجهیز برای نامه‌های ارسالی اجباری است');
        setState(() {
          isUploading = false;
        });
        return;
      }

      final result = await DocumentUploadService.uploadDocument(
        file: selectedFile!,
        userId: currentUser.id.toString(),
        userName: currentUser.fullName,
        description: description,
        category: selectedCategory,
        equipment: selectedEquipment,
        isPublic: isPublic,
      );

      if (result['success']) {
        _showSuccess('فایل با موفقیت آپلود شد');
        // پاک کردن فرم
        setState(() {
          selectedFile = null;
          description = '';
          selectedCategory = 'نامه‌های ارسالی';
          selectedEquipment = '';
          isPublic = true;
        });
      } else {
        _showError(result['message'] ?? 'خطا در آپلود فایل');
      }
    } catch (e) {
      _showError('خطا در آپلود فایل: $e');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
      successMessage = null;
    });
  }

  void _showSuccess(String message) {
    setState(() {
      successMessage = message;
      errorMessage = null;
    });
  }
}
