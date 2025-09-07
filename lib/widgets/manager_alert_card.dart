import 'package:flutter/material.dart';
import '../models/manager_alert.dart';
import '../config/alert_card_config.dart';

class ManagerAlertCard extends StatelessWidget {
  final ManagerAlert alert;
  final bool isNew;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool canEdit;
  final bool canDelete;

  const ManagerAlertCard({
    super.key,
    required this.alert,
    required this.isNew,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
    this.canEdit = false,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AlertCardConfig.cardMargin,
      height: AlertCardConfig.cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AlertCardConfig.borderRadius),
        boxShadow: AlertCardConfig.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AlertCardConfig.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AlertCardConfig.borderRadius),
              gradient: AlertCardConfig.backgroundGradient,
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // بخش راست - آیکن و نوار رنگی
                Container(
                  width: AlertCardConfig.accentWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(AlertCardConfig.borderRadius),
                      bottomRight:
                          Radius.circular(AlertCardConfig.borderRadius),
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
                            AlertCardConfig.getAlertIcon(alert.category),
                            color: Colors.white,
                            size: AlertCardConfig.iconSize,
                          ),
                        ),
                      ),

                      // نشان جدید
                      if (isNew)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: AlertCardConfig.indicatorSize,
                            height: AlertCardConfig.indicatorSize,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(
                                  AlertCardConfig.indicatorSize / 2),
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
                    padding: AlertCardConfig.contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // عنوان اعلان
                        Flexible(
                          child: Text(
                            AlertCardConfig.truncateText(alert.title, 20),
                            style: AlertCardConfig.titleStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // دسته‌بندی
                        Flexible(
                          child: Text(
                            AlertCardConfig.truncateText(alert.category, 15),
                            style: AlertCardConfig.categoryStyle.copyWith(
                              color: _getAccentColor(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                        AlertCardConfig.formatTime(
                                            alert.createdAt),
                                        style: AlertCardConfig.timeStyle.copyWith(
                                          color: _getAccentColor(),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // دکمه‌های عملیات
                              if (canEdit || canDelete)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canEdit)
                                      GestureDetector(
                                        onTap: onEdit,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    if (canEdit && canDelete)
                                      const SizedBox(width: 4),
                                    if (canDelete)
                                      GestureDetector(
                                        onTap: onDelete,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.delete,
                                            size: 14,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              else
                                // وضعیت (فقط اگر دکمه‌های عملیات نباشند)
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
                                      style: AlertCardConfig.categoryStyle.copyWith(
                                        fontSize: 10,
                                        color: isNew ? Colors.red : Colors.green,
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
    // رنگ‌بندی بر اساس وضعیت خوانده شدن
    if (isNew) {
      return AlertCardConfig.unreadColor; // نارنجی برای اعلان‌های نخوانده
    } else {
      return AlertCardConfig
          .readColor; // خاکستری تیره برای اعلان‌های خوانده شده
    }
  }
}
