import 'package:flutter/material.dart';
import '../config/dashboard_design_tokens.dart';

/// Bottom Navigation with 4 items: Downloads · Production · Downtimes · KPIs
class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardDesignTokens.colorSurface,
        boxShadow: [
          BoxShadow(
            color: DashboardDesignTokens.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: DashboardDesignTokens.screenPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.download,
                label: 'دانلودها',
                isActive: currentIndex == 0,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.precision_manufacturing,
                label: 'تولید',
                isActive: currentIndex == 1,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.warning_amber,
                label: 'توقفات',
                isActive: currentIndex == 2,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.analytics,
                label: 'شاخص‌ها',
                isActive: currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(DashboardDesignTokens.buttonRadius),
          color: isActive
              ? DashboardDesignTokens.colorPrimary700.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top indicator for active item
            if (isActive)
              Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: DashboardDesignTokens.colorPrimary700,
                  borderRadius: BorderRadius.circular(1),
                ),
              )
            else
              const SizedBox(height: 6),

            // Icon
            Icon(
              icon,
              size: DashboardDesignTokens.iconSize,
              color: isActive
                  ? DashboardDesignTokens.colorPrimary700
                  : DashboardDesignTokens.colorTextSecondary,
            ),

            const SizedBox(height: 4),

            // Label (only show for active item or always show based on design preference)
            Text(
              label,
              style: DashboardDesignTokens.captionStyle.copyWith(
                color: isActive
                    ? DashboardDesignTokens.colorPrimary700
                    : DashboardDesignTokens.colorTextSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
