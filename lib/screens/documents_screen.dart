import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
// removed unused: import '../models/user_model.dart';
import '../config/app_colors.dart';
import '../config/standard_page_config.dart';
// removed unused: import '../widgets/page_header.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentModel> documents = [];
  bool isLoading = false;
  String selectedCategory = 'همه';
  String selectedEquipment = 'همه';
  bool showOnlyPublic = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      print(
          'DocumentsScreen: Loading documents for user: ${currentUser?.fullName}');

      // تست اتصال به سرور اصلی
      print('DocumentsScreen: Testing connection to main server...');
      final isConnected = await DocumentService.checkConnection();
      print('DocumentsScreen: Connection test result: $isConnected');

      final result = await DocumentService.getDocuments(user: currentUser);

      print('DocumentsScreen: Result received: $result');

      if (result['success']) {
        final docs = (result['documents'] as List)
            .map((doc) => DocumentModel.fromJson(doc))
            .toList();

        setState(() {
          documents = docs;
          isLoading = false;
        });

        print('DocumentsScreen: Loaded ${docs.length} documents');
      } else {
        setState(() {
          isLoading = false;
        });
        _showSnackBar(result['message'] ?? 'خطا در بارگذاری مدارک');
      }
    } catch (e) {
      print('DocumentsScreen: Exception in _loadDocuments: $e');
      setState(() {
        isLoading = false;
      });
      _showSnackBar('خطا در ارتباط با سرور: $e');
    }
  }

  Future<void> _downloadDocument(DocumentModel document) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      // نمایش نشانگر بارگذاری
      _showSnackBar('در حال دانلود فایل...');

      // Get download directory
      // استفاده از پوشه Downloads عمومی تلفن
      final directory = await getExternalStorageDirectory();
      String? downloadPath;

      if (directory != null) {
        // تلاش برای دسترسی به پوشه Downloads عمومی
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          downloadPath = downloadsDir.path;
        } else {
          // اگر پوشه Downloads عمومی موجود نباشد، از پوشه Documents استفاده کن
          downloadPath = '${directory.path}/Downloads';
        }
      } else {
        // اگر دسترسی به external storage نباشد، از internal استفاده کن
        final internalDir = await getApplicationDocumentsDirectory();
        downloadPath = '${internalDir.path}/Downloads';
      }

      final downloadDir = Directory(downloadPath);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final savePath = '${downloadDir.path}/${document.fileName}';

      print('DocumentsScreen: Downloading to: $savePath');

      final result = await DocumentService.downloadDocument(
        document.id,
        savePath,
        user: currentUser,
      );

      if (result['success']) {
        final message = result['message'] ?? 'فایل با موفقیت دانلود شد';
        _showSnackBar('✅ $message\n📁 مسیر: ${result['file_path']}');

        // نمایش اطلاعات بیشتر
        print('DocumentsScreen: Download successful');
        print('DocumentsScreen: File path: ${result['file_path']}');
      } else {
        final errorMessage = result['message'] ?? 'خطا در دانلود فایل';
        _showSnackBar('❌ $errorMessage');
        print('DocumentsScreen: Download failed: $errorMessage');
      }
    } catch (e) {
      print('DocumentsScreen: Download exception: $e');
      _showSnackBar('❌ خطا در دانلود فایل: $e');
    }
  }

  List<String> get categories {
    final categories = <String>{'همه'};
    for (final doc in documents) {
      categories.add(doc.category);
    }
    return categories.toList()..sort();
  }

  List<String> get equipmentList {
    final equipment = <String>{'همه'};
    for (final doc in documents) {
      if (doc.equipment != null && doc.equipment!.isNotEmpty) {
        equipment.add(doc.equipment!);
      }
    }
    return equipment.toList()..sort();
  }

  List<DocumentModel> get filteredDocuments {
    return documents.where((doc) {
      // Filter by category
      if (selectedCategory != 'همه' && doc.category != selectedCategory) {
        return false;
      }

      // Filter by equipment
      if (selectedEquipment != 'همه' && doc.equipment != selectedEquipment) {
        return false;
      }

      // Filter by public/private
      if (showOnlyPublic && !doc.isPublic) {
        return false;
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return doc.name.toLowerCase().contains(query) ||
            doc.description.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.stopsAppBar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageConfig.buildStandardPage(
      title: 'مدارک و مستندات',
      content: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'جستجو در مدارک...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Category and Equipment filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'دسته‌بندی',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                            selectedEquipment =
                                'همه'; // Reset equipment when category changes
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedEquipment,
                        decoration: InputDecoration(
                          labelText: 'تجهیز',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: equipmentList.map((equipment) {
                          return DropdownMenuItem(
                            value: equipment,
                            child: Text(equipment),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedEquipment = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Documents List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDocuments.isEmpty
                    ? const Center(
                        child: Text(
                          'مدرکی برای نمایش وجود ندارد',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final document = filteredDocuments[index];
                          return _buildDocumentCard(document);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.stopsAppBar.withOpacity(0.1),
          child: Text(
            document.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          document.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  document.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.storage,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  document.formattedSize,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (!document.isPublic) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'خصوصی',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadDocument(document),
          tooltip: 'دانلود',
        ),
        onTap: () => _downloadDocument(document),
      ),
    );
  }
}
