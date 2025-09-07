import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/manager_alert_service.dart';
import '../config/app_colors.dart';
import '../widgets/page_header.dart';
import '../models/manager_alert.dart';
import 'dart:io';
import '../models/position_model.dart';
import '../services/auth_service.dart';

class NewManagerAlertPage extends StatefulWidget {
  const NewManagerAlertPage({super.key});

  @override
  State<NewManagerAlertPage> createState() => _NewManagerAlertPageState();
}

class _NewManagerAlertPageState extends State<NewManagerAlertPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedCategory;
  String? _selectedAdministrativeOrder;
  List<String> _selectedStakeholderTypes = [];
  List<String> _selectedRoleTypes = [];
  // گروه‌های هدف جدید - بر اساس پوزیشن‌های فعال
  List<String> _selectedEmployerPositions = [];
  List<String> _selectedConsultantPositions = [];
  List<String> _selectedContractorPositions = [];

  bool _isLoading = false;
  bool _allowReplies = true;
  bool _isEditing = false;
  String? _editingAlertId;
  File? _selectedFile;
  String? _selectedFileName;

  // لیست‌های انتخاب
  final List<String> _categories = ManagerAlertService.getAlertCategories();
  final List<String> _administrativeOrders = [
    'جهت اطلاع',
    'جهت اقدام لازم',
    'بررسی و اعلام نظر',
    'بررسی و همکاری لازم',
    'بایگانی شود',
    'پاسخ مناسب تهیه گردد',
    'بلا مانع است',
    'مورد تایید نیست',
  ];
  // لیست‌های پوزیشن‌های فعال
  List<String> _employerPositions = [];
  List<String> _consultantPositions = [];
  List<String> _contractorPositions = [];

  bool _hasCheckedEditMode = false;

  @override
  void initState() {
    super.initState();
    // بارگذاری داینامیک گروه‌های هدف بر اساس Position کاربران ثبت‌شده
    // نیاز به context دارد، پس یک میکروتسک در صف می‌گذاریم تا بعد از mount اجرا شود
    Future.microtask(() => _loadTargetOptions());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedEditMode) {
      _checkForEditMode();
      _hasCheckedEditMode = true;
    }
  }

  void _checkForEditMode() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isEditing'] == true) {
      final alert = args['alert'] as ManagerAlert;
      _isEditing = true;
      _editingAlertId = alert.id;
      _titleController.text = alert.title;
      _messageController.text = alert.message;
      _selectedCategory = alert.category;
      // تبدیل انتخاب‌های قدیمی به جدید
      _convertOldSelectionsToNew();
      _allowReplies = alert.allowReplies;
      setState(() {});
    }
  }

  Future<void> _loadTargetOptions() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final users = await authService.getAllUsers();

      final Map<StakeholderType, Set<String>> positionsByStakeholder = {
        StakeholderType.employer: <String>{},
        StakeholderType.consultant: <String>{},
        StakeholderType.contractor: <String>{},
      };

      for (final user in users) {
        try {
          final pos = PositionModel.fromTitle(user.position);
          // اضافه کردن پوزیشن کامل به گروه مربوطه
          positionsByStakeholder[pos.stakeholderType]!.add(pos.title);
        } catch (_) {
          // رد کردن پوزیشن‌های نامعتبر بدون قطع جریان
        }
      }

      // اگر در حالت ویرایش هستیم، پوزیشن‌های انتخاب‌شده را هم اضافه کنیم
      if (_isEditing) {
        // تبدیل انتخاب‌های قدیمی به پوزیشن‌های جدید (برای سازگاری)
        _convertOldSelectionsToNew();
      }

      setState(() {
        _employerPositions =
            positionsByStakeholder[StakeholderType.employer]!.toList()..sort();
        _consultantPositions =
            positionsByStakeholder[StakeholderType.consultant]!.toList()
              ..sort();
        _contractorPositions =
            positionsByStakeholder[StakeholderType.contractor]!.toList()
              ..sort();
      });
    } catch (e) {
      // در صورت خطا، لیست‌ها خالی می‌ماند و پیام اعتبارسنجی نمایش داده می‌شود
    }
  }

  void _convertOldSelectionsToNew() {
    // تبدیل انتخاب‌های قدیمی به پوزیشن‌های جدید برای سازگاری
    // این متد فقط برای حالت ویرایش استفاده می‌شود
    if (_selectedStakeholderTypes.isNotEmpty || _selectedRoleTypes.isNotEmpty) {
      // در اینجا می‌توان منطق تبدیل را اضافه کرد اگر نیاز باشد
      // فعلاً انتخاب‌های جدید را خالی می‌کنیم
      _selectedEmployerPositions.clear();
      _selectedConsultantPositions.clear();
      _selectedContractorPositions.clear();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showAlertPreview() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً دسته‌بندی را انتخاب کنید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedEmployerPositions.isEmpty &&
        _selectedConsultantPositions.isEmpty &&
        _selectedContractorPositions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً حداقل یک گروه هدف انتخاب کنید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // حالت پیش‌نمایش فقط با دیالوگ مدیریت می‌شود

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
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: const Color(0xFF4CAF50),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'پیش‌نمایش اعلان مدیریت',
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
                        // گروه‌های هدف
                        _buildTargetGroupsPreview(),
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
                            backgroundColor: const Color(0xFF4CAF50),
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
              Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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

  Widget _buildTargetGroupsPreview() {
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
              Icon(Icons.group, color: const Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 8),
              const Text(
                'گروه‌های هدف',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A59),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // نمایش پوزیشن‌های انتخاب شده بر اساس گروه
          if (_selectedEmployerPositions.isNotEmpty) ...[
            _buildPreviewSectionForPositions(
                'کارفرما', _selectedEmployerPositions, const Color(0xFF2196F3)),
            const SizedBox(height: 8),
          ],
          if (_selectedConsultantPositions.isNotEmpty) ...[
            _buildPreviewSectionForPositions('مشاوران',
                _selectedConsultantPositions, const Color(0xFF9C27B0)),
            const SizedBox(height: 8),
          ],
          if (_selectedContractorPositions.isNotEmpty) ...[
            _buildPreviewSectionForPositions('پیمانکاران',
                _selectedContractorPositions, const Color(0xFF4CAF50)),
          ],
          if (_selectedEmployerPositions.isEmpty &&
              _selectedConsultantPositions.isEmpty &&
              _selectedContractorPositions.isEmpty)
            Text(
              'هیچ گروه هدفی انتخاب نشده',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewSectionForPositions(
      String title, List<String> positions, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: positions
              .map((position) => Chip(
                    label: Text(position),
                    backgroundColor: color.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Future<void> _submitAlert() async {
    setState(() => _isLoading = true);

    try {
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);

      // تبدیل انتخاب‌های جدید به فرمت قدیمی برای سازگاری با سرور
      final targetStakeholderTypes = <String>[];
      final targetRoleTypes = <String>[];

      // استخراج stakeholder types از پوزیشن‌های انتخاب شده
      final allSelectedPositions = [
        ..._selectedEmployerPositions,
        ..._selectedConsultantPositions,
        ..._selectedContractorPositions,
      ];

      for (final position in allSelectedPositions) {
        try {
          final pos = PositionModel.fromTitle(position);
          targetStakeholderTypes.add(pos.stakeholderType.title);
          targetRoleTypes.add(pos.roleType.title);
        } catch (e) {
          print('⚠️ خطا در پردازش پوزیشن: $position - $e');
        }
      }

      if (_isEditing) {
        print('🔍 شروع ویرایش اعلان مدیریت...');
        print('📝 عنوان: ${_titleController.text}');
        print('📋 دسته‌بندی: $_selectedCategory');
        print('📄 متن: ${_messageController.text}');
        print('👥 پوزیشن‌های انتخاب شده: ${allSelectedPositions.length}');

        await managerAlertService.updateManagerAlert(
          alertId: _editingAlertId!,
          title: _titleController.text,
          message: _messageController.text,
          category: _selectedCategory!,
          targetStakeholderTypes: targetStakeholderTypes,
          targetRoleTypes: targetRoleTypes,
          allowReplies: _allowReplies,
        );
      } else {
        print('🔍 شروع ثبت اعلان مدیریت...');
        print('📝 عنوان: ${_titleController.text}');
        print('📋 دسته‌بندی: $_selectedCategory');
        print('📄 متن: ${_messageController.text}');
        print('👥 پوزیشن‌های انتخاب شده: ${allSelectedPositions.length}');

        await managerAlertService.createManagerAlert(
          title: _titleController.text,
          message: _messageController.text,
          category: _selectedCategory!,
          targetStakeholderTypes: targetStakeholderTypes,
          targetRoleTypes: targetRoleTypes,
          attachmentPath: _selectedFile?.path,
          allowReplies: _allowReplies,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'اعلان مدیریت با موفقیت ویرایش شد'
                : 'اعلان مدیریت با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ خطا در ثبت اعلان مدیریت: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت اعلان: ${e.toString()}'),
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
        backgroundColor: AppColors.stopsAppBar,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: _isEditing
                    ? 'ویرایش اعلان مدیریت'
                    : 'ایجاد اعلان مدیریت جدید',
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFCFD8DC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 9),

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
                              ],
                            ),
                          ),
                          const SizedBox(height: 9),

                                                     // دسته‌بندی و دستور اداری
                           Column(
                             children: [
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
                                           borderSide: BorderSide(
                                               color: Colors.grey[300]!),
                                         ),
                                         enabledBorder: OutlineInputBorder(
                                           borderRadius: BorderRadius.circular(12),
                                           borderSide: BorderSide(
                                               color: Colors.grey[300]!),
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
                               // دستور اداری
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
                                         Icon(Icons.admin_panel_settings,
                                             color: AppColors.secondaryBlue,
                                             size: 20),
                                         const SizedBox(width: 8),
                                         Text(
                                           'دستور اداری',
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
                                       value: _selectedAdministrativeOrder,
                                       decoration: InputDecoration(
                                         hintText: 'دستور اداری را انتخاب کنید',
                                         hintStyle: const TextStyle(
                                             fontFamily: 'Vazirmatn'),
                                         border: OutlineInputBorder(
                                           borderRadius: BorderRadius.circular(12),
                                           borderSide: BorderSide(
                                               color: Colors.grey[300]!),
                                         ),
                                         enabledBorder: OutlineInputBorder(
                                           borderRadius: BorderRadius.circular(12),
                                           borderSide: BorderSide(
                                               color: Colors.grey[300]!),
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
                                       items: _administrativeOrders.map((order) {
                                         return DropdownMenuItem(
                                           value: order,
                                           child: Text(order,
                                               style: const TextStyle(
                                                   fontFamily: 'Vazirmatn')),
                                         );
                                       }).toList(),
                                       onChanged: (value) {
                                         setState(() {
                                           _selectedAdministrativeOrder = value;
                                         });
                                       },
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                          const SizedBox(height: 9),

                          // گروه‌های هدف
                          _buildTargetGroupsSection(),
                          const SizedBox(height: 9),

                          // تنظیمات پاسخ‌دهی
                          _buildAllowRepliesSection(),
                          const SizedBox(height: 9),

                          // دکمه‌های عملیات
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _showAlertPreview,
                                  icon: const Icon(Icons.preview),
                                  label: const Text('پیش‌نمایش'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
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
                                  label: Text(_isLoading
                                      ? 'در حال ثبت...'
                                      : 'ثبت اعلان'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
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

  Widget _buildTargetGroupsSection() {
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
            'گروه‌های هدف *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 16),

          // باکس کارفرما
          _buildStakeholderBox(
            'کارفرما',
            Icons.business,
            const Color(0xFF2196F3),
            _employerPositions,
            _selectedEmployerPositions,
            (selected) => setState(() {
              if (selected) {
                _selectedEmployerPositions.add(_employerPositions.first);
              } else {
                _selectedEmployerPositions.clear();
              }
            }),
          ),
          const SizedBox(height: 16),

          // باکس مشاوران
          _buildStakeholderBox(
            'مشاوران',
            Icons.people,
            const Color(0xFF9C27B0),
            _consultantPositions,
            _selectedConsultantPositions,
            (selected) => setState(() {
              if (selected) {
                _selectedConsultantPositions.add(_consultantPositions.first);
              } else {
                _selectedConsultantPositions.clear();
              }
            }),
          ),
          const SizedBox(height: 16),

          // باکس پیمانکاران
          _buildStakeholderBox(
            'پیمانکاران',
            Icons.engineering,
            const Color(0xFF4CAF50),
            _contractorPositions,
            _selectedContractorPositions,
            (selected) => setState(() {
              if (selected) {
                _selectedContractorPositions.add(_contractorPositions.first);
              } else {
                _selectedContractorPositions.clear();
              }
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'حداقل یک گروه هدف باید انتخاب شود',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeholderBox(
    String title,
    IconData icon,
    Color color,
    List<String> positions,
    List<String> selectedPositions,
    Function(bool) onToggle,
  ) {
    final hasPositions = positions.isNotEmpty;
    final isSelected = selectedPositions.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.3) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر باکس
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (hasPositions)
                Switch(
                  value: isSelected,
                  onChanged: onToggle,
                  activeColor: color,
                ),
            ],
          ),
          if (hasPositions && isSelected) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // لیست پوزیشن‌های انتخاب شده
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: positions.map((position) {
                final isPositionSelected = selectedPositions.contains(position);
                return FilterChip(
                  label: Text(
                    position,
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: isPositionSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedPositions.add(position);
                      } else {
                        selectedPositions.remove(position);
                      }
                    });
                  },
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isPositionSelected ? color : Colors.grey[700],
                    fontWeight: isPositionSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ] else if (!hasPositions) ...[
            const SizedBox(height: 4),
            Text(
              'هیچ پوزیشن فعالی موجود نیست',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllowRepliesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text(
              'اجازه پاسخ‌دهی',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2E3A59),
              ),
            ),
            subtitle: const Text(
              'کاربران می‌توانند به این اعلان پاسخ دهند',
              style: TextStyle(
                fontSize: 10,
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
            dense: true,
          ),
        ],
      ),
    );
  }
}
