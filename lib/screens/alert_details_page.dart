import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../models/alert_notification.dart';

class AlertDetailsPage extends StatefulWidget {
  final AlertNotification alert;

  const AlertDetailsPage({
    super.key,
    required this.alert,
  });

  @override
  State<AlertDetailsPage> createState() => _AlertDetailsPageState();
}

class _AlertDetailsPageState extends State<AlertDetailsPage> {
  final _replyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _markAsSeen();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _markAsSeen() async {
    final alertService = Provider.of<AlertService>(context, listen: false);

    await alertService.markAlertAsSeen(widget.alert.id);
  }

  Future<void> _addReply() async {
    if (_replyController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final alertService = Provider.of<AlertService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      await alertService.addReply(widget.alert.id, _replyController.text);

      _replyController.clear();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteReply(String replyId) async {
    setState(() => _isLoading = true);

    try {
      final alertService = Provider.of<AlertService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      await alertService.deleteReply(widget.alert.id, replyId);

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات هشدار'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'دستگاه: ${widget.alert.equipmentId}',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.alert.message,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تاریخ: ${_formatDate(widget.alert.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.right,
                          ),
                          if (widget.alert.attachmentPath != null) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implement file download
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('دانلود فایل پیوست'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'پاسخ‌ها',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.alert.replies.isEmpty)
                    const Center(
                      child: Text('هیچ پاسخی وجود ندارد'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.alert.replies.length,
                      itemBuilder: (context, index) {
                        final reply = widget.alert.replies[index];
                        return Card(
                          child: ListTile(
                            title: Text(reply.message),
                            subtitle: Text(
                              'تاریخ: ${_formatDate(reply.createdAt)}',
                            ),
                            trailing: currentUser?.id == reply.userId
                                ? IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteReply(reply.id),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'پاسخ خود را بنویسید...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addReply,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('ارسال'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
