import 'package:flutter/material.dart';
import '../models/alert_notification.dart';

class PremiumAlertCard extends StatelessWidget {
  final AlertNotification alert;
  final bool isNew;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PremiumAlertCard({
    super.key,
    required this.alert,
    required this.isNew,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // بخش راست - آیکن و نوار رنگی
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _getAccentColor(),
                        _getAccentColor().withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // آیکن اصلی
                      Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getAlertIcon(),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      // نشان جدید
                      if (isNew)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // بخش چپ - اطلاعات
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // عنوان تجهیزات
                        Flexible(
                          child: Text(
                            _truncateText(alert.equipmentId, 20),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                              fontFamily: 'Vazirmatn',
                              height: 1.2,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // دسته‌بندی
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getAccentColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getAccentColor().withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _truncateText(alert.category, 15),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getAccentColor(),
                                fontFamily: 'Vazirmatn',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // زمان و وضعیت
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // زمان
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: _getAccentColor(),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _formatTime(alert.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getAccentColor(),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // وضعیت
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isNew
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isNew ? 'جدید' : 'خوانده شده',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isNew ? Colors.red : Colors.green,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAccentColor() {
    switch (alert.category.toLowerCase()) {
      case 'مکانیک':
        return const Color(0xFFE74C3C); // قرمز
      case 'برق':
        return const Color(0xFFF39C12); // نارنجی
      case 'پروسس':
        return const Color(0xFF3498DB); // آبی
      case 'عمومی':
        return const Color(0xFF2ECC71); // سبز
      case 'ایمنی':
        return const Color(0xFF9B59B6); // بنفش
      default:
        return const Color(0xFF34495E); // خاکستری تیره
    }
  }

  IconData _getAlertIcon() {
    switch (alert.category.toLowerCase()) {
      case 'مکانیک':
        return Icons.build_rounded;
      case 'برق':
        return Icons.electric_bolt_rounded;
      case 'پروسس':
        return Icons.science_rounded;
      case 'عمومی':
        return Icons.info_rounded;
      case 'ایمنی':
        return Icons.security_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}س';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}روز';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
