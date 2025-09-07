import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../models/user_model.dart';
import '../providers/data_provider.dart';
import '../config/standard_page_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = Provider.of<AuthService>(context).getCurrentUser();

    return StandardPageConfig.buildStandardPage(
      title: 'پروفایل',
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Profile Header - تکمیل شده
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.primary,
                      backgroundImage: const AssetImage('assets/images/profile.png'),
                      child: user?.fullName != null ? null : Text(
                        user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'کاربر',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.position ?? 'پوزیشن نامعلوم',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // اطلاعات کامل کاربر
                    _buildInfoRow(
                        Icons.person, 'نام کاربری', user?.username ?? '-'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.email, 'ایمیل', user?.email ?? '-'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        Icons.phone, 'شماره موبایل', user?.mobile ?? '-'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.badge, 'شناسه کاربری', user?.id ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Section
            Text(
              'حساب کاربری',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.chevron_right),
                    title: const Text('ویرایش پروفایل', textAlign: TextAlign.right),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () {
                      _showEditProfileDialog(context, user);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.chevron_right),
                    title: const Text('تغییر رمز عبور', textAlign: TextAlign.right),
                    trailing: const Icon(Icons.lock_outline),
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'خروج',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.right,
                    ),
                    onTap: () {
                      Provider.of<AuthService>(context, listen: false)
                          .signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 20, color: Colors.grey[600]),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, UserModel? user) {
    if (user == null) return;

    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final mobileController = TextEditingController(text: user.mobile);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ویرایش پروفایل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'نام کامل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'ایمیل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // به‌روزرسانی اطلاعات کاربر
                  // TODO: implement update user profile in AuthService
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('پروفایل با موفقیت به‌روزرسانی شد'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطا در به‌روزرسانی: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تغییر رمز عبور'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'رمز عبور فعلی',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'رمز عبور جدید',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'تکرار رمز عبور جدید',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تکرار رمز عبور مطابقت ندارد'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await Provider.of<AuthService>(context, listen: false)
                      .changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('رمز عبور با موفقیت تغییر کرد'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطا در تغییر رمز عبور: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('تغییر رمز'),
            ),
          ],
        );
      },
    );
  }
}
