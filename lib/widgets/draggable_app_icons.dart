import 'package:flutter/material.dart';

class AppIconData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  AppIconData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class DraggableAppIcons extends StatefulWidget {
  final Function(String) onIconTap;

  const DraggableAppIcons({
    super.key,
    required this.onIconTap,
  });

  @override
  State<DraggableAppIcons> createState() => _DraggableAppIconsState();
}

class _DraggableAppIconsState extends State<DraggableAppIcons> {
  List<AppIconData> _appIcons = [
    AppIconData(
      id: 'production',
      name: 'تولید',
      icon: Icons.show_chart,
      color: const Color(0xFF2196F3),
    ),
    AppIconData(
      id: 'stoppages',
      name: 'توقفات',
      icon: Icons.timer,
      color: const Color(0xFFF44336),
    ),
    AppIconData(
      id: 'indicators',
      name: 'شاخص‌ها',
      icon: Icons.analytics,
      color: const Color(0xFF4CAF50),
    ),
    AppIconData(
      id: 'profile',
      name: 'پروفایل',
      icon: Icons.person,
      color: const Color(0xFF9C27B0),
    ),
    AppIconData(
      id: 'annual_plan',
      name: 'برنامه سالانه',
      icon: Icons.calendar_today,
      color: const Color(0xFFFF9800),
    ),
    AppIconData(
      id: 'personnel',
      name: 'مدیریت پرسنل',
      icon: Icons.people,
      color: const Color(0xFF607D8B),
    ),
    AppIconData(
      id: 'documents_and_files',
      name: 'مدارک و مستندات',
      icon: Icons.folder_open,
      color: const Color(0xFF795548),
    ),
    AppIconData(
      id: 'equipment',
      name: 'لیست تجهیزات',
      icon: Icons.build,
      color: const Color(0xFF3F51B5),
    ),
    AppIconData(
      id: 'grades',
      name: 'لیست عیارها',
      icon: Icons.analytics,
      color: const Color(0xFFE91E63),
    ),
    AppIconData(
      id: 'reports',
      name: 'گزارشات',
      icon: Icons.assessment,
      color: const Color(0xFF009688),
    ),
    AppIconData(
      id: 'alerts',
      name: 'اعلان‌ها',
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFFFF5722),
    ),
    AppIconData(
      id: 'grade_entry',
      name: 'ثبت عیار',
      icon: Icons.analytics,
      color: const Color(0xFFE91E63),
    ),
    AppIconData(
      id: 'ai_assistant',
      name: 'دستیار هوش مصنوعی',
      icon: Icons.assistant,
      color: const Color(0xFF673AB7),
    ),
    AppIconData(
      id: 'equipment_location',
      name: 'محل‌های باردهی',
      icon: Icons.location_on,
      color: const Color(0xFF8BC34A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 15,
        ),
        itemCount: _appIcons.length,
        itemBuilder: (context, index) {
          final appIcon = _appIcons[index];
          return LongPressDraggable<AppIconData>(
            data: appIcon,
            feedback: _buildIconWidget(appIcon, isDragging: true),
            childWhenDragging: _buildIconWidget(appIcon, isPlaceholder: true),
            onDragEnd: (details) {
              // محاسبه موقعیت جدید بر اساس محل رها شدن
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(details.offset);

              // محاسبه ردیف و ستون جدید
              final itemWidth =
                  (renderBox.size.width - 30) / 4; // 30 = total spacing
              final itemHeight = (renderBox.size.height - 45) /
                  (_appIcons.length / 4).ceil(); // 45 = total spacing

              final newColumn =
                  (localPosition.dx / itemWidth).floor().clamp(0, 3);
              final newRow = (localPosition.dy / itemHeight)
                  .floor()
                  .clamp(0, (_appIcons.length / 4).ceil() - 1);
              final newIndex = newRow * 4 + newColumn;

              if (newIndex != index && newIndex < _appIcons.length) {
                setState(() {
                  final item = _appIcons.removeAt(index);
                  _appIcons.insert(newIndex, item);
                });
              }
            },
            child: GestureDetector(
              onTap: () => widget.onIconTap(appIcon.id),
              child: _buildIconWidget(appIcon),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconWidget(AppIconData appIcon,
      {bool isDragging = false, bool isPlaceholder = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // آیکن اصلی
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isPlaceholder
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: isPlaceholder
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(
            appIcon.icon,
            color: isPlaceholder ? Colors.transparent : appIcon.color,
            size: 24,
          ),
        ),
        const SizedBox(height: 5),
        // نام آیکن
        Flexible(
          child: Text(
            appIcon.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
