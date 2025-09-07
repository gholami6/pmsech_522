import 'package:flutter/material.dart';

class MachineStatusList extends StatelessWidget {
  final List<Map<String, dynamic>> machines;

  const MachineStatusList({
    super.key,
    required this.machines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وضعیت ماشین‌آلات',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: machines.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final machine = machines[index];
                final isActive = machine['isActive'] as bool;
                final status = machine['status'] as String;

                Color statusColor;
                switch (status) {
                  case 'در حال کار':
                    statusColor = Colors.green;
                    break;
                  case 'توقف':
                    statusColor = Colors.red;
                    break;
                  case 'سرویس':
                    statusColor = Colors.orange;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    machine['name'] as String,
                    style: theme.textTheme.titleMedium,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
