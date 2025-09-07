import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/server_alert_service.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../widgets/page_header.dart';
import '../services/notification_service.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import '../models/stop_data.dart';
import 'package:file_picker/file_picker.dart';

class NewAlertPage extends StatefulWidget {
  const NewAlertPage({super.key});

  @override
  State<NewAlertPage> createState() => _NewAlertPageState();
}

class _NewAlertPageState extends State<NewAlertPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedEquipment;
  String? _selectedCategory;
  bool _isLoading = false;
  bool _allowReplies = true;
  bool _isEditing = false;
  String? _editingAlertId;
  File? _selectedFile;
  String? _selectedFileName;
  List<String> _equipmentList = [];

  // لیست دسته‌بندی‌های اعلان - محدود به 5 مورد اصلی
  final List<String> _categories = [
    'عمومی',
    'مکانیکی',
    'برقی',
    'پروسسی',
    'سایر',
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipmentList();
  }

  Future<void> _loadEquipmentList() async {
    try {
      print('🔧 NewAlertPage: شروع بارگذاری لیست تجهیزات از دیتابیس...');

      final equipmentList = await _getEquipmentListFromDatabase();

      if (mounted) {
        setState(() {
          _equipmentList = equipmentList;
        });
      }

      print(
          '📋 NewAlertPage: تعداد تجهیزات بارگذاری شده: ${_equipmentList.length}');
      print('📋 NewAlertPage: لیست تجهیزات: $_equipmentList');
    } catch (e) {
      print('❌ NewAlertPage: خطا در بارگذاری لیست تجهیزات: $e');
    }
  }

  /// دریافت لیست تجهیزات از دیتابیس StopData
  Future<List<String>> _getEquipmentListFromDatabase() async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      Set<String> uniqueEquipments = {};

      for (var stopData in stopBox.values) {
        // اول از equipmentName استفاده کن، اگر نبود از equipment
        String equipmentName = stopData.equipmentName ?? stopData.equipment;
        if (equipmentName.isNotEmpty) {
          uniqueEquipments.add(equipmentName);
        }
      }

      final result = uniqueEquipments.toList()..sort();

      // اگر هیچ تجهیزی یافت نشد، لیست پیش‌فرض استفاده کن
      if (result.isEmpty) {
        return [
          'خط یک',
          'خط دو',
          'خط سه',
          'خط چهار',
          'خط پنج',
          'خط شش',
          'خط هفت',
          'خط هشت',
          'سنگ‌شکن فکی',
          'سنگ‌شکن مخروطی',
          'آسیاب گلوله‌ای',
          'آسیاب میله‌ای',
          'هیدروسیکلون',
          'فیلترپرس',
          'کوره دوار',
          'کولر',
          'الواتور',
          'کانوایر',
          'پمپ',
          'کمپرسور',
          'موتور',
          'ژنراتور',
          'تابلو برق',
          'سیستم کنترل',
          'سایر',
        ];
      }

      return result;
    } catch (e) {
      print('خطا در دریافت لیست تجهیزات: $e');
      // در صورت خطا، لیست پیش‌فرض استفاده کن
      return [
        'خط یک',
        'خط دو',
        'خط سه',
        'خط چهار',
        'خط پنج',
        'خط شش',
        'خط هفت',
        'خط هشت',
        'سنگ‌شکن فکی',
        'سنگ‌شکن مخروطی',
        'آسیاب گلوله‌ای',
        'آسیاب میله‌ای',
        'هیدروسیکلون',
        'فیلترپرس',
        'کوره دوار',
        'کولر',
        'الواتور',
        'کانوایر',
        'پمپ',
        'کمپرسور',
        'موتور',
        'ژنراتور',
        'تابلو برق',
        'سیستم کنترل',
        'سایر',
      ];
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx'
        ],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
        print('📎 فایل انتخاب شده: $_selectedFileName');
      }
    } catch (e) {
      print('❌ خطا در انتخاب فایل: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در انتخاب فایل: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showAlertPreview() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً تجهیز را انتخاب کنید',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // پیش‌نمایش با نمایش دیالوگ مدیریت می‌شود

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.stopsAppBar.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notification_important,
                        color: const Color(0xFF2196F3),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'پیش‌نمایش اعلان کارشناسی',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E3A59),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // عنوان
                        _buildPreviewSection(
                          'عنوان اعلان',
                          _titleController.text,
                          Icons.title,
                        ),
                        const SizedBox(height: 16),
                        // تجهیز
                        _buildPreviewSection(
                          'تجهیز',
                          _selectedEquipment ?? '',
                          Icons.build,
                        ),
                        const SizedBox(height: 16),
                        // دسته‌بندی
                        _buildPreviewSection(
                          'دسته‌بندی',
                          _selectedCategory ?? '',
                          Icons.category,
                        ),
                        const SizedBox(height: 16),
                        // متن اعلان
                        _buildPreviewSection(
                          'متن اعلان',
                          _messageController.text,
                          Icons.message,
                          isMultiline: true,
                        ),
                        const SizedBox(height: 16),
                        // تنظیمات پاسخ‌دهی
                        _buildPreviewSection(
                          'تنظیمات پاسخ‌دهی',
                          _allowReplies ? 'اجازه پاسخ‌دهی' : 'بدون پاسخ‌دهی',
                          Icons.reply,
                        ),
                        const SizedBox(height: 16),
                        // فایل پیوست
                        if (_selectedFileName != null)
                          _buildPreviewSection(
                            'فایل پیوست',
                            _selectedFileName!,
                            Icons.attach_file,
                          ),
                      ],
                    ),
                  ),
                ),
                // Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'بازگشت',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _submitAlert();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'تایید و ثبت',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(String title, String content, IconData icon,
      {bool isMultiline = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2196F3), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A59),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.isEmpty ? 'تعریف نشده' : content,
            style: TextStyle(
              fontSize: 14,
              color: content.isEmpty ? Colors.grey[500] : Colors.grey[800],
            ),
            maxLines: isMultiline ? null : 2,
            overflow: isMultiline ? null : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _submitAlert() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      print('🔍 شروع ثبت اعلان...');
      print('👤 کاربر: ${currentUser.id}');
      print('🏭 تجهیز: $_selectedEquipment');
      print('📝 پیام: ${_messageController.text}');
      print('📋 دسته‌بندی: $_selectedCategory');
      print('💬 اجازه پاسخ: $_allowReplies');

      // آپلود فایل اگر انتخاب شده باشد
      String? attachmentPath;
      if (_selectedFile != null) {
        print('📎 فایل انتخاب شده: $_selectedFileName');
        // اینجا باید فایل را به سرور آپلود کنید
        // attachmentPath = await uploadFile(_selectedFile!);
      }

      // تلاش برای ذخیره در سرور
      String? alertId;
      bool serverSuccess = false;

      try {
        print('🌐 تلاش برای ارسال به سرور...');
        final isConnected = await ServerAlertService.testConnection();
        if (isConnected) {
          alertId = await ServerAlertService.createAlert(
            userId: currentUser.id,
            equipmentId: _selectedEquipment!,
            message: _messageController.text,
            attachmentPath: attachmentPath,
            category: _selectedCategory ?? 'عمومی',
            allowReplies: _allowReplies,
          );
          serverSuccess = true;
          print('✅ اعلان در سرور با موفقیت ثبت شد. ID: $alertId');
        } else {
          print('⚠️ سرور در دسترس نیست، ذخیره محلی...');
        }
      } catch (serverError) {
        print('❌ خطا در سرور: $serverError');
        print('⚠️ ذخیره محلی...');
      }

      // ذخیره محلی فقط در صورت عدم موفقیت سرور
      if (!serverSuccess) {
        try {
          await NotificationService.createAlert(
            userId: currentUser.id,
            equipmentId: _selectedEquipment!,
            message: _messageController.text,
            attachmentPath: attachmentPath,
            allowReplies: _allowReplies,
          );
          print('💾 اعلان در حافظه محلی ذخیره شد');
        } catch (localError) {
          print('❌ خطا در ذخیره محلی: $localError');
          throw Exception(
              'خطا در ذخیره اعلان: سرور و حافظه محلی در دسترس نیستند');
        }
      }

      if (mounted) {
        String message = serverSuccess
            ? 'اعلان با موفقیت ثبت شد و برای همه کاربران ارسال شد'
            : 'اعلان در حافظه محلی ذخیره شد (سرور در دسترس نبود)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: serverSuccess ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ خطا در ثبت اعلان: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ثبت اعلان: ${e.toString()}',
            ),
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
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: _isEditing
                    ? 'ویرایش اعلان کارشناسی'
                    : 'ایجاد اعلان کارشناسی جدید',
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.mainBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان اعلان
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.title,
                                        color: AppColors.secondaryBlue,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'عنوان اعلان *',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryBlue,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _titleController,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style:
                                      const TextStyle(fontFamily: 'Vazirmatn'),
                                  decoration: InputDecoration(
                                    hintText: 'عنوان اعلان را وارد کنید',
                                    hintStyle: const TextStyle(
                                        fontFamily: 'Vazirmatn'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: AppColors.secondaryBlue),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'عنوان اعلان الزامی است';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // تجهیز
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.build,
                                        color: AppColors.secondaryBlue,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تجهیز *',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryBlue,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedEquipment,
                                  decoration: InputDecoration(
                                    hintText: 'تجهیز را انتخاب کنید',
                                    hintStyle: const TextStyle(
                                        fontFamily: 'Vazirmatn'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: AppColors.secondaryBlue),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  items: _equipmentList.map((equipment) {
                                    return DropdownMenuItem(
                                      value: equipment,
                                      child: Text(equipment,
                                          style: const TextStyle(
                                              fontFamily: 'Vazirmatn')),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedEquipment = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'تجهیز الزامی است';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // دسته‌بندی
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.category,
                                        color: AppColors.secondaryBlue,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'دسته‌بندی *',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryBlue,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    hintText: 'دسته‌بندی را انتخاب کنید',
                                    hintStyle: const TextStyle(
                                        fontFamily: 'Vazirmatn'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: AppColors.secondaryBlue),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  items: _categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(category,
                                          style: const TextStyle(
                                              fontFamily: 'Vazirmatn')),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'دسته‌بندی الزامی است';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // متن اعلان
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.message,
                                        color: AppColors.secondaryBlue,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'متن اعلان *',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryBlue,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _messageController,
                                  maxLines: 4,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style:
                                      const TextStyle(fontFamily: 'Vazirmatn'),
                                  decoration: InputDecoration(
                                    hintText: 'متن اعلان را وارد کنید',
                                    hintStyle: const TextStyle(
                                        fontFamily: 'Vazirmatn'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: AppColors.secondaryBlue),
                                    ),
                                    alignLabelWithHint: true,
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'متن اعلان الزامی است';
                                    }
                                    return null;
                                  },
                                ),
                                // آیکن فایل پیوست در پایین
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (_selectedFile == null)
                                        IconButton(
                                          onPressed: _pickFile,
                                          icon: Icon(
                                            Icons.attach_file,
                                            color: AppColors.secondaryBlue,
                                            size: 24,
                                          ),
                                          tooltip: 'افزودن فایل پیوست',
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.attach_file,
                                              color: const Color(0xFF4CAF50),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _selectedFileName!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF4CAF50),
                                                fontFamily: 'Vazirmatn',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: _removeFile,
                                              icon: const Icon(
                                                Icons.close,
                                                size: 16,
                                              ),
                                              color: Colors.red,
                                              tooltip: 'حذف فایل',
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // تنظیمات پاسخ‌دهی
                          _buildAllowRepliesSection(),
                          const SizedBox(height: 18),

                          // دکمه‌های عملیات
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _showAlertPreview,
                                  icon: const Icon(Icons.preview),
                                  label: const Text(
                                    'پیش‌نمایش',
                                    style: TextStyle(fontFamily: 'Vazirmatn'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _submitAlert,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                  label: Text(
                                    _isLoading ? 'در حال ثبت...' : 'ثبت اعلان',
                                    style: const TextStyle(
                                        fontFamily: 'Vazirmatn'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllowRepliesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تنظیمات پاسخ‌دهی',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'اجازه پاسخ‌دهی',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2E3A59),
              ),
            ),
            subtitle: const Text(
              'کاربران می‌توانند به این اعلان پاسخ دهند',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            value: _allowReplies,
            onChanged: (value) {
              setState(() {
                _allowReplies = value;
              });
            },
            activeColor: const Color(0xFF4CAF50),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
