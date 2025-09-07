import 'package:flutter/material.dart';
import '../config/dashboard_design_tokens.dart';

/// Unified announcement card component for Manager and Expert announcements
class DashboardAnnouncementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DashboardAnnouncementCard({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DashboardDesignTokens.announcementCardHeight,
      decoration: BoxDecoration(
        color: DashboardDesignTokens.colorPrimary700,
        borderRadius: BorderRadius.circular(DashboardDesignTokens.cardRadius),
        boxShadow: DashboardDesignTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DashboardDesignTokens.cardRadius),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(DashboardDesignTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: DashboardDesignTokens.iconSizeLarge,
                      height: DashboardDesignTokens.iconSizeLarge,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: DashboardDesignTokens.iconSize,
                      ),
                    ),
                    const Spacer(),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: DashboardDesignTokens.primaryFont,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DashboardDesignTokens.gapSmall),
                Expanded(
                  child: Text(
                    title,
                    style: DashboardDesignTokens.cardTitleWhite,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
