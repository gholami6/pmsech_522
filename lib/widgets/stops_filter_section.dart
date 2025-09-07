import 'package:flutter/material.dart';
import '../config/stops_screen_styles.dart';

class StopsFilterSection extends StatelessWidget {
  final String title;
  final List<String> selectedFilters;
  final List<String> allFilters;
  final Function(String) onFilterSelected;
  final Function(String) onFilterRemoved;
  final VoidCallback onShowDialog;

  const StopsFilterSection({
    Key? key,
    required this.title,
    required this.selectedFilters,
    required this.allFilters,
    required this.onFilterSelected,
    required this.onFilterRemoved,
    required this.onShowDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: StopsScreenStyles.cardMargin,
      padding: StopsScreenStyles.cardPadding,
      decoration: BoxDecoration(
        color: StopsScreenStyles.cardBackgroundColor,
        borderRadius: StopsScreenStyles.cardBorderRadius,
        border: Border.all(
          color: StopsScreenStyles.cardBorderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: StopsScreenStyles.titleStyle,
              ),
              const Spacer(),
              IconButton(
                onPressed: onShowDialog,
                icon: const Icon(Icons.filter_list, size: 20.0),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (selectedFilters.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: selectedFilters.map((filter) {
                return Chip(
                  label: Text(
                    filter,
                    style: StopsScreenStyles.filterChipStyle,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16.0),
                  onDeleted: () => onFilterRemoved(filter),
                  backgroundColor:
                      StopsScreenStyles.cardBorderColor.withOpacity(0.1),
                  deleteIconColor: StopsScreenStyles.cardBorderColor,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
