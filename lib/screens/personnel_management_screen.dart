import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
// removed unused: import '../models/position_model.dart';
import '../config/standard_page_config.dart';
import '../config/app_colors.dart';

class PersonnelManagementScreen extends StatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  State<PersonnelManagementScreen> createState() =>
      _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState extends State<PersonnelManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final users = await authService.getAllUsers();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری کاربران: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    return _users.where((user) {
      return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.position.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final fullNameController = TextEditingController();
    final mobileController = TextEditingController();
    String selectedPosition = 'مدیر مشاور';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('افزودن کاربر جدید'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'نام کاربری',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'نام کاربری الزامی است';
                        }
                        if (value.length < 3) {
                          return 'نام کاربری باید حداقل 3 کاراکتر باشد';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'رمز عبور',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'رمز عبور الزامی است';
                        }
                        if (value.length < 4) {
                          return 'رمز عبور باید حداقل 4 کاراکتر باشد';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'نام کامل',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'نام کامل الزامی است';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'ایمیل',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ایمیل الزامی است';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'ایمیل نامعتبر است';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: mobileController,
                      decoration: const InputDecoration(
                        labelText: 'شماره موبایل',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'شماره موبایل الزامی است';
                        }
                        if (!RegExp(r'^09[0-9]{9}$').hasMatch(value)) {
                          return 'شماره موبایل نامعتبر است';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPosition,
                      decoration: const InputDecoration(
                        labelText: 'سمت شغلی',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'مدیر مشاور',
                        'سرپرست مشاور',
                        'کارشناس صنایع مشاور',
                        'کارشناس مکانیک مشاور',
                        'کارشناس برق مشاور',
                        'کارشناس طراحی مشاور',
                        'کارشناس پروسس مشاور',
                        'رئیس مشاور',
                        'مدیر کارفرما',
                        'سرپرست کارفرما',
                        'کارشناس صنایع کارفرما',
                        'کارشناس مکانیک کارفرما',
                        'کارشناس برق کارفرما',
                        'کارشناس طراحی کارفرما',
                        'کارشناس پروسس کارفرما',
                        'رئیس کارفرما',
                        'مدیر پیمانکار',
                        'سرپرست پیمانکار',
                        'کارشناس صنایع پیمانکار',
                        'کارشناس مکانیک پیمانکار',
                        'کارشناس برق پیمانکار',
                        'کارشناس طراحی پیمانکار',
                        'کارشناس پروسس پیمانکار',
                        'رئیس پیمانکار',
                      ]
                          .map((position) => DropdownMenuItem(
                                value: position,
                                child: Text(position),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPosition = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      await authService.register(
                        username: usernameController.text.trim(),
                        password: passwordController.text,
                        mobile: mobileController.text.trim(),
                        email: emailController.text.trim(),
                        fullName: fullNameController.text.trim(),
                        position: selectedPosition,
                      );

                      Navigator.of(context).pop();
                      _loadUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('کاربر با موفقیت اضافه شد'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('خطا در افزودن کاربر: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('افزودن'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('انصراف'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: user.email);
    final fullNameController = TextEditingController(text: user.fullName);
    final mobileController = TextEditingController(text: user.mobile);
    String selectedPosition = user.position;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('ویرایش کاربر: ${user.username}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'نام کامل',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'نام کامل الزامی است';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'ایمیل',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ایمیل الزامی است';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'ایمیل نامعتبر است';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: mobileController,
                      decoration: const InputDecoration(
                        labelText: 'شماره موبایل',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'شماره موبایل الزامی است';
                        }
                        if (!RegExp(r'^09[0-9]{9}$').hasMatch(value)) {
                          return 'شماره موبایل نامعتبر است';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPosition,
                      decoration: const InputDecoration(
                        labelText: 'سمت شغلی',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'مدیر مشاور',
                        'سرپرست مشاور',
                        'کارشناس صنایع مشاور',
                        'کارشناس مکانیک مشاور',
                        'کارشناس برق مشاور',
                        'کارشناس طراحی مشاور',
                        'کارشناس پروسس مشاور',
                        'رئیس مشاور',
                        'مدیر کارفرما',
                        'سرپرست کارفرما',
                        'کارشناس صنایع کارفرما',
                        'کارشناس مکانیک کارفرما',
                        'کارشناس برق کارفرما',
                        'کارشناس طراحی کارفرما',
                        'کارشناس پروسس کارفرما',
                        'رئیس کارفرما',
                        'مدیر پیمانکار',
                        'سرپرست پیمانکار',
                        'کارشناس صنایع پیمانکار',
                        'کارشناس مکانیک پیمانکار',
                        'کارشناس برق پیمانکار',
                        'کارشناس طراحی پیمانکار',
                        'کارشناس پروسس پیمانکار',
                        'رئیس پیمانکار',
                      ]
                          .map((position) => DropdownMenuItem(
                                value: position,
                                child: Text(position),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPosition = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      await authService.updateUser(
                        userId: user.id,
                        email: emailController.text.trim(),
                        fullName: fullNameController.text.trim(),
                        mobile: mobileController.text.trim(),
                        position: selectedPosition,
                      );

                      Navigator.of(context).pop();
                      _loadUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('کاربر با موفقیت ویرایش شد'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('خطا در ویرایش کاربر: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('ذخیره'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('انصراف'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف کاربر'),
          content: Text('آیا از حذف کاربر "${user.fullName}" اطمینان دارید؟'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final authService =
                      Provider.of<AuthService>(context, listen: false);

                  // استفاده از تابع حذف امن به جای حذف معمولی
                  await authService.deleteUserSafely(user.id);

                  Navigator.of(context).pop();
                  _loadUsers();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('کاربر با موفقیت حذف شد'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطا در حذف کاربر: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDatabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('بازنشانی دیتابیس'),
          content: const Text(
              'آیا از بازنشانی دیتابیس کاربران اطمینان دارید؟ این کار تمام کاربران را حذف کرده و فقط کاربر پیش‌فرض را باقی می‌گذارد.'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final authService =
                      Provider.of<AuthService>(context, listen: false);

                  await authService.resetUserDatabase();

                  Navigator.of(context).pop();
                  _loadUsers();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('دیتابیس با موفقیت بازنشانی شد'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطا در بازنشانی دیتابیس: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('بازنشانی'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDatabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('پاک کردن کامل دیتابیس'),
          content: const Text(
              'آیا از پاک کردن کامل دیتابیس اطمینان دارید؟ این کار تمام داده‌ها را حذف کرده و دیتابیس را مجدداً راه‌اندازی می‌کند.'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final authService =
                      Provider.of<AuthService>(context, listen: false);

                  await authService.clearAndReinitializeDatabase();

                  Navigator.of(context).pop();
                  _loadUsers();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('دیتابیس با موفقیت پاک و مجدداً راه‌اندازی شد'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطا در پاک کردن دیتابیس: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('پاک کردن'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          backgroundImage: const AssetImage('assets/images/profile.png'),
          child: user.fullName.isEmpty ? Text(
            'U',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ) : null,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نام کاربری: ${user.username}'),
            Text('سمت: ${user.position}'),
            Text('ایمیل: ${user.email}'),
            Text('موبایل: ${user.mobile}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditUserDialog(user);
                break;
              case 'delete':
                _showDeleteUserDialog(user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('ویرایش'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StandardPageConfig.buildStandardPage(
        title: 'مدیریت پرسنل',
        content: Stack(
          children: [
            Column(
              children: [
                // جستجو و دکمه‌های مدیریت
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
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'جستجو در کاربران',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showResetDatabaseDialog(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('بازنشانی دیتابیس'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showClearDatabaseDialog(),
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('پاک کردن کامل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // لیست کاربران
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredUsers.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'هیچ کاربری یافت نشد',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(_filteredUsers[index]);
                              },
                            ),
                ),
              ],
            ),
            // FloatingActionButton
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showAddUserDialog,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.person_add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
