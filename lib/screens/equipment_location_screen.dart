import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment_location.dart';
import '../services/equipment_location_service.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';

class EquipmentLocationScreen extends StatefulWidget {
  const EquipmentLocationScreen({super.key});

  @override
  State<EquipmentLocationScreen> createState() =>
      _EquipmentLocationScreenState();
}

class _EquipmentLocationScreenState extends State<EquipmentLocationScreen> {
  List<EquipmentLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await EquipmentLocationService.initialize();
      final locations = await EquipmentLocationService.getAllLocations();
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      print('خطا در بارگذاری محل‌های باردهی: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stopsAppBar,
      appBar: AppBar(
        backgroundColor: AppColors.stopsAppBar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'مدیریت محل‌های باردهی',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFCFD8DC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _locations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'هیچ محل باردهی یافت نشد',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final location = _locations[index];
                      return _buildLocationCard(location);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLocationDialog(),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationCard(EquipmentLocation location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Icon(
              location.isActive ? Icons.location_on : Icons.location_off,
              color: location.isActive ? Colors.green : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    location.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: location.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                location.isActive ? 'فعال' : 'غیرفعال',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'ایجاد شده توسط: ${location.createdBy}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditLocationDialog(location);
            } else if (value == 'delete') {
              _showDeleteLocationDialog(location);
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
        ),
      ),
    );
  }

  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن محل باردهی جدید'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'نام محل',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً نام محل را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'توضیحات',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً توضیحات را وارد کنید';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                final currentUser = authService.currentUser;

                if (currentUser != null) {
                  // بررسی وجود نام تکراری
                  final nameExists =
                      await EquipmentLocationService.isNameExists(
                    nameController.text.trim(),
                  );

                  if (nameExists) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('این نام قبلاً استفاده شده است'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  await EquipmentLocationService.addLocation(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    userId: currentUser.id,
                  );

                  Navigator.pop(context);
                  _loadLocations();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('محل باردهی با موفقیت اضافه شد'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(EquipmentLocation location) {
    final nameController = TextEditingController(text: location.name);
    final descriptionController =
        TextEditingController(text: location.description);
    final formKey = GlobalKey<FormState>();
    bool isActive = location.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ویرایش محل باردهی'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'نام محل',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً نام محل را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً توضیحات را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value ?? false;
                        });
                      },
                    ),
                    const Text('فعال'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // بررسی وجود نام تکراری
                  final nameExists =
                      await EquipmentLocationService.isNameExists(
                    nameController.text.trim(),
                    excludeId: location.id,
                  );

                  if (nameExists) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('این نام قبلاً استفاده شده است'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  await EquipmentLocationService.updateLocation(
                    id: location.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    isActive: isActive,
                  );

                  Navigator.pop(context);
                  _loadLocations();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('محل باردهی با موفقیت آپدیت شد'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('آپدیت'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteLocationDialog(EquipmentLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف محل باردهی'),
        content:
            Text('آیا از حذف محل باردهی "${location.name}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              await EquipmentLocationService.deleteLocation(location.id);
              Navigator.pop(context);
              _loadLocations();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('محل باردهی با موفقیت حذف شد'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
