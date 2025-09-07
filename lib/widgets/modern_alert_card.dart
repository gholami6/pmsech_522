import 'package:flutter/material.dart';
import '../models/alert_notification.dart';
import '../config/alert_card_config.dart';
import 'alert_icon_widget.dart';
import 'status_badge.dart';
import 'time_badge.dart';
import 'progress_bar.dart';
import 'message_display.dart';

class ModernAlertCard extends StatelessWidget {
  final AlertNotification alert;
  final bool isNew;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ModernAlertCard({
    super.key,
    required this.alert,
    required this.isNew,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = ModernAlertCardConfig.getAccentColor(alert.message);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: ModernAlertCardConfig.cardMargin,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(ModernAlertCardConfig.cardBorderRadius),
          boxShadow: ModernAlertCardConfig.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius:
                BorderRadius.circular(ModernAlertCardConfig.cardBorderRadius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    ModernAlertCardConfig.cardBorderRadius),
                gradient: isNew
                    ? ModernAlertCardConfig.getNewCardGradient()
                    : ModernAlertCardConfig.getReadCardGradient(),
              ),
              child: Stack(
                children: [
                  // پس‌زمینه گرافیکی
                  Positioned(
                    top: -ModernAlertCardConfig.backgroundCircleOffset,
                    right: -ModernAlertCardConfig.backgroundCircleOffset,
                    child: Container(
                      width: ModernAlertCardConfig.backgroundCircleSize,
                      height: ModernAlertCardConfig.backgroundCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            ModernAlertCardConfig.getBackgroundCircleGradient(
                                accentColor),
                      ),
                    ),
                  ),

                  // نوار رنگی کناری
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: ModernAlertCardConfig.accentBarWidth,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(
                              ModernAlertCardConfig.cardBorderRadius),
                          bottomRight: Radius.circular(
                              ModernAlertCardConfig.cardBorderRadius),
                        ),
                        boxShadow: ModernAlertCardConfig.getAccentBarShadow(
                            accentColor),
                      ),
                    ),
                  ),

                  // محتوای اصلی
                  Padding(
                    padding: ModernAlertCardConfig.contentPadding,
                    child: Row(
                      children: [
                        // بخش آیکن و وضعیت
                        AnimatedAlertIcon(
                          icon:
                              ModernAlertCardConfig.getAlertIcon(alert.message),
                          color: accentColor,
                          size: ModernAlertCardConfig.iconSize,
                          isNew: isNew,
                        ),

                        SizedBox(width: ModernAlertCardConfig.iconSpacing),

                        // بخش اطلاعات
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // عنوان و زمان
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.equipmentId,
                                      style:
                                          ModernAlertCardConfig.getTitleStyle(
                                              isNew),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SmartTimeBadge(dateTime: alert.createdAt),
                                ],
                              ),

                              SizedBox(
                                  height:
                                      ModernAlertCardConfig.titleTimeSpacing),

                              // پیام
                              AlertMessageDisplay(
                                message: alert.message,
                                isNew: isNew,
                              ),

                              SizedBox(
                                  height: ModernAlertCardConfig.messageSpacing),

                              // نوار پیشرفت و وضعیت
                              Row(
                                children: [
                                  // نوار پیشرفت
                                  Expanded(
                                    child: AlertProgressBar(
                                      createdAt: alert.createdAt,
                                      color: accentColor,
                                      height: ModernAlertCardConfig
                                          .progressBarHeight,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // وضعیت
                                  isNew
                                      ? const NewStatusBadge()
                                      : const ReadStatusBadge(),
                                ],
                              ),
                            ],
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
      ),
    );
  }
}
