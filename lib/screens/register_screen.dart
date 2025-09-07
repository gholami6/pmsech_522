import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/position_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  StakeholderType? _selectedStakeholder;
  RoleType? _selectedRole;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateUsername(String mobile) {
    return mobile.substring(mobile.length - 4);
  }

  void _showStakeholderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب ذینفع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: StakeholderType.values.map((type) {
            return ListTile(
              title: Text(type.title),
              onTap: () {
                setState(() {
                  _selectedStakeholder = type;
                  _selectedRole = null;
                });
                Navigator.pop(context);
                _showRoleDialog();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('انتخاب ${_selectedStakeholder!.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoleType.values.map((role) {
            return ListTile(
              title: Text(role.title),
              onTap: () {
                setState(() {
                  _selectedRole = role;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String get _positionText {
    if (_selectedStakeholder == null || _selectedRole == null) {
      return 'انتخاب نشده';
    }
    return '${_selectedRole!.title} ${_selectedStakeholder!.title}';
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final position = PositionModel(
          stakeholderType: _selectedStakeholder!,
          roleType: _selectedRole!,
        );

        await Provider.of<AuthService>(context, listen: false).register(
          username: _generateUsername(_mobileController.text),
          password: _passwordController.text,
          mobile: _mobileController.text,
          email: _emailController.text,
          fullName: '${_firstNameController.text} ${_lastNameController.text}',
          position: position.title,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ثبت نام با موفقیت انجام شد. نام کاربری شما: ${_generateUsername(_mobileController.text)}',
                textAlign: TextAlign.right,
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString(),
                textAlign: TextAlign.right,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double boxWidth = MediaQuery.of(context).size.width * 0.8; // فرم اصلی
    final double innerBoxWidth =
        boxWidth * 0.7 * 1.2; // باکس‌های داخلی (۲۰٪ بیشتر)
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/register_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // لوگو و عنوان
                    Container(
                      width: boxWidth, // هدر
                      padding: const EdgeInsets.all(16), // ۲۰٪ کمتر از ۲۰
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3)
                            .withOpacity(0.3), // آبی با شفافیت ۳۰٪
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ثبت نام در سیستم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سیستم مدیریت تولید',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 27),
                    _buildInputField(
                      controller: _firstNameController,
                      label: 'نام',
                      icon: Icons.person_outline,
                      width: innerBoxWidth,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً نام را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _lastNameController,
                      label: 'نام خانوادگی',
                      icon: Icons.person_outline,
                      width: innerBoxWidth,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً نام خانوادگی را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _mobileController,
                      label: 'شماره موبایل',
                      icon: Icons.phone_outlined,
                      width: innerBoxWidth,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً شماره موبایل را وارد کنید';
                        }
                        if (!RegExp(r'^09[0-9]{9}').hasMatch(value)) {
                          return 'شماره موبایل نامعتبر است';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _emailController,
                      label: 'ایمیل',
                      icon: Icons.email_outlined,
                      width: innerBoxWidth,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً ایمیل را وارد کنید';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}')
                            .hasMatch(value)) {
                          return 'ایمیل نامعتبر است';
                        }
                        return null;
                      },
                    ),
                    // انتخاب موقعیت
                    Container(
                      width: innerBoxWidth,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: InkWell(
                        onTap: _showStakeholderDialog,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.work_outline,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              Text(
                                _positionText,
                                style: TextStyle(
                                  color: _selectedStakeholder == null
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.white,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'رمز عبور',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      width: innerBoxWidth,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً رمز عبور را وارد کنید';
                        }
                        if (value.length < 4) {
                          return 'رمز عبور باید حداقل 4 کاراکتر باشد';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _confirmPasswordController,
                      label: 'تأیید رمز عبور',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      width: innerBoxWidth,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً تأیید رمز عبور را وارد کنید';
                        }
                        if (value != _passwordController.text) {
                          return 'رمز عبور و تأیید آن مطابقت ندارند';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: boxWidth, // دکمه ثبت‌نام به اندازه هدر
                      height: 50, // ۲۵٪ بیشتر از ۴۰
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2196F3).withOpacity(0.3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'ثبت نام',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    double? width,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: width ?? double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45), // سفید با شفافیت ۴۵٪
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword
            ? (isPassword == _obscurePassword
                ? _obscurePassword
                : _obscureConfirmPassword)
            : false,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: 'Vazirmatn',
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontFamily: 'Vazirmatn',
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isPassword == _obscurePassword
                            ? _obscurePassword
                            : _obscureConfirmPassword)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPassword == _obscurePassword) {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          alignLabelWithHint: true,
          floatingLabelAlignment: FloatingLabelAlignment.start,
        ),
        validator: validator,
      ),
    );
  }
}
