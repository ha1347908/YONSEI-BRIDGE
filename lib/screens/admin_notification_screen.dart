import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/language_service.dart';
import '../services/firebase_storage_service.dart';
import '../models/country_data.dart';
import '../models/chat_message_model.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<String> _selectedCountries = [];
  List<String> _filteredCountries = [];
  XFile? _selectedImage;
  bool _isSending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredCountries = CountryData.allCountries;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCountries = CountryData.allCountries;
      } else {
        _filteredCountries = CountryData.allCountries
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _pickImage() async {
    final firebaseStorageService = Provider.of<FirebaseStorageService>(context, listen: false);
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0038A8)),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                final image = await firebaseStorageService.pickImageFromGallery();
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0038A8)),
              title: const Text('사진 촬영'),
              onTap: () async {
                Navigator.pop(context);
                final image = await firebaseStorageService.takePhotoWithCamera();
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('이미지 제거', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 국가를 선택해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminUserId = prefs.getString('user_id') ?? 'bridge_master_haram';
      final adminUserName = prefs.getString('nickname') ?? 'YONSEI BRIDGE Admin';

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        final firebaseStorageService = Provider.of<FirebaseStorageService>(context, listen: false);
        imageUrl = await firebaseStorageService.uploadNotificationImage(_selectedImage!);
      }

      // Get all users with selected countries
      final allUsers = await _getUsersByCountries(_selectedCountries);

      // Send notification as chat message to each user
      final chatBox = await Hive.openBox('chat_messages');
      int recipientCount = 0;

      for (final user in allUsers) {
        final message = ChatMessage(
          id: 'notification_${DateTime.now().millisecondsSinceEpoch}_${user['userId']}',
          senderId: adminUserId,
          senderName: adminUserName,
          receiverId: user['userId'] as String,
          message: '📢 ${_titleController.text}\n\n${_messageController.text}',
          timestamp: DateTime.now(),
          isRead: false,
        );

        await chatBox.put(message.id, message.toJson());
        recipientCount++;
      }

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림이 $recipientCount명의 사용자에게 전송되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedCountries.clear();
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 전송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getUsersByCountries(List<String> countries) async {
    // In a real implementation, this would query Firebase/Firestore
    // For now, we'll simulate with demo data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final users = <Map<String, dynamic>>[];

    // Get all user IDs from SharedPreferences
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('demo_nationality_')) {
        final userId = key.replaceFirst('demo_nationality_', '');
        final nationality = prefs.getString(key);
        
        if (nationality != null && countries.contains(nationality)) {
          users.add({
            'userId': userId,
            'nationality': nationality,
            'userName': prefs.getString('demo_name_$userId') ?? 'User',
          });
        }
      }
    }

    return users;
  }

  void _showCountrySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Text('국가 선택'),
                  const Spacer(),
                  Text(
                    '${_selectedCountries.length}개 선택됨',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setDialogState(() {
                          _filterCountries(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '국가 검색...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Select all / Deselect all buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _selectedCountries = List.from(_filteredCountries);
                              });
                              setState(() {});
                            },
                            icon: const Icon(Icons.check_box),
                            label: const Text('전체 선택'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _selectedCountries.clear();
                              });
                              setState(() {});
                            },
                            icon: const Icon(Icons.check_box_outline_blank),
                            label: const Text('전체 해제'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Country list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = _filteredCountries[index];
                          final isSelected = _selectedCountries.contains(country);
                          
                          return CheckboxListTile(
                            title: Text(country),
                            value: isSelected,
                            activeColor: const Color(0xFF0038A8),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  _selectedCountries.add(country);
                                } else {
                                  _selectedCountries.remove(country);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 보내기'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '알림 제목',
                    hintText: '예: 긴급 공지',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Message field
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: '알림 내용',
                    hintText: '전달할 메시지를 입력하세요',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '내용을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image picker
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_selectedImage == null ? '이미지 추가 (선택사항)' : '이미지 변경'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedImage!.name,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Country selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.public, color: Color(0xFF0038A8)),
                    title: const Text('대상 국가 선택'),
                    subtitle: Text(
                      _selectedCountries.isEmpty
                          ? '국가를 선택하세요'
                          : '${_selectedCountries.length}개 국가 선택됨',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showCountrySelectionDialog,
                  ),
                ),
                const SizedBox(height: 8),

                // Selected countries chips
                if (_selectedCountries.isNotEmpty) ...[
                  const Text(
                    '선택된 국가:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCountries.map((country) {
                      return Chip(
                        label: Text(country),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedCountries.remove(country);
                          });
                        },
                        backgroundColor: const Color(0xFF0038A8).withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendNotification,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSending ? '전송 중...' : '알림 전송',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0038A8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Color(0xFF0038A8)),
                          SizedBox(width: 8),
                          Text(
                            '알림 전송 안내',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0038A8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• 선택한 국가의 모든 사용자에게 채팅 메시지로 전송됩니다\n'
                        '• 관리자(bridge_master_haram)에서 각 사용자로 1:1 메시지 전송\n'
                        '• 이미지는 선택사항이며, 텍스트만으로도 전송 가능합니다\n'
                        '• 알림은 채팅 목록에서 확인할 수 있습니다',
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
