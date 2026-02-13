import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  String _filterStatus = 'Pending';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    final users = <Map<String, dynamic>>[];
    
    // Load demo accounts
    if (_filterStatus == 'All' || _filterStatus == 'Pending') {
      users.add({
        'user_id': 'pending_user',
        'name': '대기 중 사용자',
        'nationality': 'China',
        'contact': '010-9876-5432',
        'status': 'Pending',
        'created_at': DateTime.now().subtract(const Duration(days: 1)),
      });
    }
    
    if (_filterStatus == 'All' || _filterStatus == 'Approved') {
      users.add({
        'user_id': 'testuser',
        'name': '테스트 사용자',
        'nationality': 'Korea',
        'contact': '010-1234-5678',
        'status': 'Approved',
        'created_at': DateTime.now().subtract(const Duration(days: 2)),
      });
      
      users.add({
        'user_id': 'admin',
        'name': 'System Administrator',
        'nationality': 'Korea',
        'contact': 'admin@yonseibridge.com',
        'status': 'Approved',
        'created_at': DateTime.now().subtract(const Duration(days: 30)),
      });
    }
    
    // Load custom registered users
    for (final key in allKeys) {
      if (key.startsWith('demo_user_')) {
        final userId = key.replaceFirst('demo_user_', '');
        final status = prefs.getString('demo_status_$userId') ?? 'Pending';
        
        if (_filterStatus == 'All' || _filterStatus == status) {
          final photoBase64 = prefs.getString('demo_photo_$userId');
          users.add({
            'user_id': userId,
            'name': prefs.getString('demo_name_$userId') ?? userId,
            'nationality': prefs.getString('demo_nationality_$userId') ?? 'Unknown',
            'contact': prefs.getString('demo_contact_$userId') ?? 'N/A',
            'status': status,
            'created_at': DateTime.now(),
            'id_photo_base64': photoBase64,
          });
        }
      }
    }
    
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('demo_status_${user['user_id']}', 'Approved');
    
    // 승인 후 학생증 사진 즉시 삭제
    await prefs.remove('demo_photo_${user['user_id']}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['name']} (${user['user_id']}) 승인 완료 - 학생증 사진 삭제됨'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    }
  }

  Future<void> _blockUser(Map<String, dynamic> user, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('demo_status_${user['user_id']}', 'Blocked');
    await prefs.setString('demo_block_reason_${user['user_id']}', reason);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['name']} (${user['user_id']}) 차단 완료'),
          backgroundColor: Colors.red,
        ),
      );
      _loadUsers();
    }
  }

  void _showBlockDialog(Map<String, dynamic> user) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 차단'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('사용자: ${user['name']} (${user['user_id']})'),
            const SizedBox(height: 8),
            const Text(
              '차단된 사용자는 로그인이 불가능합니다.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '차단 사유',
                hintText: '예: 이용 규칙 위반, 부적절한 게시물',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(user, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('차단'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectUser(Map<String, dynamic> user, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('demo_status_${user['user_id']}', 'Rejected');
    await prefs.setString('demo_rejection_reason_${user['user_id']}', reason);
    
    // 거부 후 학생증 사진 즉시 삭제
    await prefs.remove('demo_photo_${user['user_id']}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['name']} (${user['user_id']}) 거부 완료 - 학생증 사진 삭제됨'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadUsers();
    }
  }

  void _showRejectDialog(Map<String, dynamic> user) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가입 거부 사유'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('사용자: ${user['name']} (${user['user_id']})'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '거부 사유',
                hintText: '예: 학생증 사진 불명확, 정보 불일치',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectUser(user, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거부'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0038A8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '${user['name']} (${user['user_id']})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(user['status']),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoSection('기본 정보', [
                      _buildInfoRow('아이디', user['user_id']),
                      _buildInfoRow('이름', user['name']),
                      _buildInfoRow('국적', user['nationality']),
                      _buildInfoRow('연락처', user['contact']),
                      _buildInfoRow('신청일', _formatDate(user['created_at'])),
                    ]),
                    const SizedBox(height: 24),
                    if (user['id_photo_base64'] != null) ...[
                      _buildInfoSection('학생증 사진', [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(user['id_photo_base64']),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('사진 로드 실패'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    if (user['status'] == 'Pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showRejectDialog(user);
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('거부'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _approveUser(user);
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('승인'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (user['status'] == 'Approved')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showBlockDialog(user);
                        },
                        icon: const Icon(Icons.block),
                        label: const Text('사용자 차단'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0038A8),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        label = '대기중';
        break;
      case 'Approved':
        color = Colors.green;
        label = '승인됨';
        break;
      case 'Rejected':
        color = Colors.red;
        label = '거부됨';
        break;
      case 'Blocked':
        color = Colors.black;
        label = '차단됨';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 승인 관리'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Pending',
                        label: Text('대기중'),
                        icon: Icon(Icons.hourglass_empty),
                      ),
                      ButtonSegment(
                        value: 'Approved',
                        label: Text('승인됨'),
                        icon: Icon(Icons.check_circle),
                      ),
                      ButtonSegment(
                        value: 'Rejected',
                        label: Text('거부됨'),
                        icon: Icon(Icons.cancel),
                      ),
                      ButtonSegment(
                        value: 'Blocked',
                        label: Text('차단됨'),
                        icon: Icon(Icons.block),
                      ),
                      ButtonSegment(
                        value: 'All',
                        label: Text('전체'),
                        icon: Icon(Icons.list),
                      ),
                    ],
                    selected: {_filterStatus},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _filterStatus = newSelection.first;
                      });
                      _loadUsers();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        '해당 상태의 사용자가 없습니다',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0038A8),
                          child: Text(
                            user['name'].toString().isNotEmpty 
                                ? user['name'].toString()[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('ID: ${user['user_id']}'),
                            Text('국적: ${user['nationality']}'),
                            Text('신청일: ${_formatDate(user['created_at'])}'),
                          ],
                        ),
                        trailing: _buildStatusChip(user['status']),
                        onTap: () => _showUserDetails(user),
                      ),
                    );
                  },
                ),
    );
  }
}
