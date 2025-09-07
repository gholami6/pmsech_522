import 'package:flutter/material.dart';
import '../models/production_data.dart';
import '../services/data_sync_service.dart';
import 'equipment_details_screen.dart';
// removed unused: import '../config/app_colors.dart';
import '../config/standard_page_config.dart';

class EquipmentListScreen extends StatefulWidget {
  final List<ProductionData> allData;

  const EquipmentListScreen({
    Key? key,
    required this.allData,
  }) : super(key: key);

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  List<String> equipmentList = [];
  Map<String, dynamic> equipmentStats = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEquipmentData();
  }

  void _loadEquipmentData() {
    equipmentList = DataSyncService.getUniqueEquipment(widget.allData);
    final stats = DataSyncService.calculateEquipmentStatistics(widget.allData);
    equipmentStats = stats['equipmentStats'] ?? {};
  }

  List<String> get filteredEquipmentList {
    if (searchQuery.isEmpty) {
      return equipmentList;
    }
    return equipmentList
        .where((equipment) =>
            equipment.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageConfig.buildStandardPage(
      title: 'مدیریت تجهیزات',
      content: Column(
        children: [
          // جستجو
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'جستجو در تجهیزات...',
                hintStyle: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Vazirmatn',
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                filled: true,
                fillColor: const Color(0xFF1565c0).withOpacity(0.3),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Vazirmatn',
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // لیست تجهیزات
          Expanded(
            child: filteredEquipmentList.isEmpty
                ? const Center(
                    child: Text(
                      'هیچ تجهیزی یافت نشد',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFFF9800),
                        fontFamily: 'Vazirmatn',
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEquipmentList.length,
                    itemBuilder: (context, index) {
                      final equipmentName = filteredEquipmentList[index];
                      final stats = equipmentStats[equipmentName] ?? {};

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white, // سفید
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EquipmentDetailsScreen(
                                  equipmentName: equipmentName,
                                  allData: widget.allData,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.precision_manufacturing,
                                      color: const Color(0xFFFF9800), // نارنجی
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end, // راست چین
                                        children: [
                                          Text(
                                            equipmentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87, // سیاه
                                              fontSize: 16,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'رتبه ${_getStopRank(equipmentName)} از نظر تعداد توقف',
                                            style: TextStyle(
                                              color:
                                                  Colors.grey[600], // خاکستری
                                              fontSize: 12,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'رتبه ${_getDurationRank(equipmentName)} از نظر مدت توقف',
                                            style: TextStyle(
                                              color:
                                                  Colors.grey[600], // خاکستری
                                              fontSize: 12,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey[600], // خاکستری
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // آمار سریع
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickStat(
                                        'تولید',
                                        '${stats['totalProducedProduct']?.toStringAsFixed(1) ?? '0'} تن',
                                        Icons.production_quantity_limits,
                                        const Color(0xFF4CAF50), // سبز
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildQuickStat(
                                        'توقف',
                                        '${(stats['totalStopDuration'] ?? 0.0).toStringAsFixed(0)} دقیقه',
                                        Icons.stop_circle,
                                        const Color(0xFFF44336), // قرمز
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildQuickStat(
                                        'اضطراری',
                                        '${stats['emergencyStops'] ?? 0}',
                                        Icons.emergency,
                                        const Color(0xFFFF9800), // نارنجی
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // ریز تجهیزات
                                FutureBuilder<List<String>>(
                                  future: Future.value(
                                    DataSyncService.getSubEquipmentForEquipment(
                                      widget.allData,
                                      equipmentName,
                                    ),
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data!.isNotEmpty) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ریز تجهیزات:',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87, // سیاه
                                              fontSize: 12,
                                              fontFamily: 'Vazirmatn',
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0.5, 0.5),
                                                  blurRadius: 1,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: snapshot.data!
                                                .take(3)
                                                .map((subEquipment) => Chip(
                                                      label: Text(
                                                        subEquipment,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xFFFF9800),
                                                          fontFamily:
                                                              'Vazirmatn',
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          const Color(
                                                                  0xFF1565c0)
                                                              .withOpacity(0.3),
                                                      side: const BorderSide(
                                                          color: Color(
                                                              0xFFFF9800)),
                                                    ))
                                                .toList(),
                                          ),
                                          if (snapshot.data!.length > 3)
                                            Text(
                                              'و ${snapshot.data!.length - 3} مورد دیگر...',
                                              style: const TextStyle(
                                                color: Color(
                                                    0xFFFFB74D), // نارنجی روشن
                                                fontSize: 10,
                                                fontFamily: 'Vazirmatn',
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0.5, 0.5),
                                                    blurRadius: 1,
                                                    color: Colors.black54,
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _getStopRank(String equipmentName) {
    // مرتب‌سازی تجهیزات بر اساس تعداد توقف
    final sortedEquipment = equipmentStats.entries.toList()
      ..sort((a, b) => (b.value['totalStops'] ?? 0.0)
          .compareTo(a.value['totalStops'] ?? 0.0));

    // پیدا کردن رتبه تجهیز
    for (int i = 0; i < sortedEquipment.length; i++) {
      if (sortedEquipment[i].key == equipmentName) {
        return i + 1;
      }
    }
    return 0;
  }

  int _getDurationRank(String equipmentName) {
    // مرتب‌سازی تجهیزات بر اساس مدت توقف
    final sortedEquipment = equipmentStats.entries.toList()
      ..sort((a, b) => (b.value['totalStopDuration'] ?? 0.0)
          .compareTo(a.value['totalStopDuration'] ?? 0.0));

    // پیدا کردن رتبه تجهیز
    for (int i = 0; i < sortedEquipment.length; i++) {
      if (sortedEquipment[i].key == equipmentName) {
        return i + 1;
      }
    }
    return 0;
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
            fontFamily: 'Vazirmatn',
            shadows: [
              Shadow(
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFB74D), // نارنجی روشن
            fontSize: 10,
            fontFamily: 'Vazirmatn',
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
