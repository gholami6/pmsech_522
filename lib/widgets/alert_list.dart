import 'package:flutter/material.dart';

class AlertList extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const AlertList({
    super.key,
    required this.alerts,
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
              'هشدارها',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final severity = alert['severity'] as String;

                Color severityColor;
                IconData severityIcon;
                switch (severity) {
                  case 'high':
                    severityColor = Colors.red;
                    severityIcon = Icons.error;
                    break;
                  case 'medium':
                    severityColor = Colors.orange;
                    severityIcon = Icons.warning;
                    break;
                  case 'low':
                    severityColor = Colors.blue;
                    severityIcon = Icons.info;
                    break;
                  default:
                    severityColor = Colors.grey;
                    severityIcon = Icons.notifications;
                }

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      severityIcon,
                      color: severityColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    alert['title'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    alert['message'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Text(
                    alert['time'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
