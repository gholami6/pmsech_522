import 'package:flutter/material.dart';
import '../config/dashboard_design_tokens.dart';

/// Primary FAB with bottom sheet quick actions
class DashboardFAB extends StatelessWidget {
  const DashboardFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showQuickActions(context),
      backgroundColor: DashboardDesignTokens.colorPrimary700,
      elevation: DashboardDesignTokens.fabElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardDesignTokens.fabRadius),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: DashboardDesignTokens.iconSizeLarge,
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withOpacity(0.95),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DashboardDesignTokens.headerBottomRadius),
            topRight: Radius.circular(DashboardDesignTokens.headerBottomRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: DashboardDesignTokens.colorBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardDesignTokens.screenPadding,
                ),
                child: Text(
                  'عملیات سریع',
                  style: DashboardDesignTokens.titleStyle,
                ),
              ),

              const SizedBox(height: DashboardDesignTokens.gapMedium),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardDesignTokens.screenPadding,
                ),
                child: Column(
                  children: [
                    _buildQuickAction(
                      context: context,
                      icon: Icons.add_chart,
                      title: 'افزودن گزارش',
                      subtitle: 'ثبت گزارش جدید تولید',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to add report
                      },
                    ),
                    _buildQuickAction(
                      context: context,
                      icon: Icons.filter_alt,
                      title: 'فیلتر دوره زمانی',
                      subtitle: 'تغییر بازه زمانی نمایش',
                      onTap: () {
                        Navigator.pop(context);
                        // Show date filter
                      },
                    ),
                    _buildQuickAction(
                      context: context,
                      icon: Icons.picture_as_pdf,
                      title: 'خروجی PDF',
                      subtitle: 'دریافت گزارش PDF',
                      onTap: () {
                        Navigator.pop(context);
                        // Export PDF
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DashboardDesignTokens.gapMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DashboardDesignTokens.gapSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(DashboardDesignTokens.buttonRadius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(DashboardDesignTokens.cardPadding),
            decoration: const BoxDecoration(),
            child: Row(
              children: [
                Container(
                  width: DashboardDesignTokens.touchTargetMin,
                  height: DashboardDesignTokens.touchTargetMin,
                  decoration: BoxDecoration(
                    color:
                        DashboardDesignTokens.colorPrimary700.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        DashboardDesignTokens.buttonRadius),
                  ),
                  child: Icon(
                    icon,
                    color: DashboardDesignTokens.colorPrimary700,
                    size: DashboardDesignTokens.iconSize,
                  ),
                ),
                const SizedBox(width: DashboardDesignTokens.gapMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DashboardDesignTokens.labelStyle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: DashboardDesignTokens.captionStyle,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: DashboardDesignTokens.colorTextSecondary,
                  size: DashboardDesignTokens.iconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
