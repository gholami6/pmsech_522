import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/stop_data.dart';
import '../models/production_data.dart';
import '../services/ai_assistant_service.dart';
import '../widgets/chat_bubble.dart';
import '../providers/data_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({Key? key}) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIAssistantService _aiService = AIAssistantService.instance;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadChatHistory();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initializeAI() async {
    await _aiService.initialize();
  }

  Future<void> _loadChatHistory() async {
    // فعلاً تاریخچه خالی است - بعداً اضافه می‌شود
    setState(() {
      _messages = [];
    });
  }

  String? _detectShiftFromMessage(String message) {
    final lowerMessage = message.toLowerCase();

    // تشخیص شیفت از پیام
    if (lowerMessage.contains('شیفت') || lowerMessage.contains('shift')) {
      if (lowerMessage.contains('صبح') || lowerMessage.contains('morning')) {
        return 'صبح';
      } else if (lowerMessage.contains('عصر') ||
          lowerMessage.contains('afternoon')) {
        return 'عصر';
      } else if (lowerMessage.contains('شب') ||
          lowerMessage.contains('night')) {
        return 'شب';
      } else if (lowerMessage.contains('a') || lowerMessage.contains('الف')) {
        return 'A';
      } else if (lowerMessage.contains('b') || lowerMessage.contains('ب')) {
        return 'B';
      } else if (lowerMessage.contains('c') || lowerMessage.contains('ج')) {
        return 'C';
      } else if (lowerMessage.contains('1')) {
        return '1';
      } else if (lowerMessage.contains('2')) {
        return '2';
      } else if (lowerMessage.contains('3')) {
        return '3';
      }
    }

    return null;
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();

    // اضافه کردن پیام کاربر به لیست
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
      sessionId: _sessionId,
    );

    setState(() {
      _messages.add(userMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final stopData = dataProvider.getStopData();
      final productionData = dataProvider.getProductionData();
      final gradeData = <dynamic>[]; // فعلاً خالی - بعداً اضافه می‌شود

      // تشخیص شیفت از پیام کاربر
      String? shiftFilter = _detectShiftFromMessage(message);

      final aiResponse = await _aiService.getAIResponse(message);

      // اضافه کردن پاسخ AI به لیست
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        message: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        sessionId: _sessionId,
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ارسال پیام: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک کردن تاریخچه'),
        content: const Text(
            'آیا مطمئن هستید که می‌خواهید تمام تاریخچه چت را پاک کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('پاک کردن'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1976D2),
        appBar: AppBar(
          title: const Text(
            'دستیار هوش مصنوعی',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _clearChat,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'پاک کردن تاریخچه',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ناحیه چت
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _messages.isEmpty
                      ? SingleChildScrollView(
                          child: _buildWelcomeMessage(),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return ChatBubble(
                              message: _messages[index],
                              isLastMessage: index == _messages.length - 1,
                            );
                          },
                        ),
                ),
              ),
              // نوار جستجو (انتقال به پایین)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'پیام خود را بنویسید...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  hintStyle: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 16,
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                onPressed: _isLoading ? null : _sendMessage,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF1976D2),
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Color(0xFF1976D2),
                                        size: 24,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              size: 60,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'دستیار هوش مصنوعی',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'سلام! من دستیار هوش مصنوعی شما هستم. می‌توانم به سوالات شما در مورد آمار تولید و توقفات کارخانه پاسخ دهم.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Column(
              children: [
                Text(
                  'نمونه سوالات:',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• کدام تجهیزات بیشترین توقف را داشته‌اند؟\n'
                  '• میانگین مدت توقف چقدر است؟\n'
                  '• آمار تولید در ماه گذشته چگونه بوده؟\n'
                  '• کدام شیفت بیشترین تولید را داشته؟\n'
                  '• برای تحلیل دقیق‌تر، از فیلتر زمانی استفاده کنید',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _aiService.dispose();
    super.dispose();
  }
}
