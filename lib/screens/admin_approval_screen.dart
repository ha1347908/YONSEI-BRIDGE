import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final FirestoreService _fs = FirestoreService();

  String _filterStatus = 'Pending';
  bool _isLoading = false;

  // ── Tab: Users ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _users = [];

  // ── Tab: Recovery Requests ────────────────────────────────────────────────
  List<Map<String, dynamic>> _recoveryRequests = [];
  int _unreadRecoveryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadRecoveryRequests();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snap = _filterStatus == 'All'
          ? await _fs.usersCol.get()
          : await _fs.usersCol
              .where('status', isEqualTo: _filterStatus)
              .get();

      final users = snap.docs.map((d) {
        final data = d.data();
        data['uid'] = d.id;
        return data;
      }).toList();

      // Sort by created_at descending (in memory – no composite index needed)
      users.sort((a, b) {
        final aT = a['created_at'];
        final bT = b['created_at'];
        if (aT == null || bT == null) return 0;
        if (aT is Timestamp && bT is Timestamp) return bT.compareTo(aT);
        return 0;
      });

      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecoveryRequests() async {
    try {
      final snap = await _fs.recoveryCol.get();
      final requests = snap.docs.map((d) {
        final data = d.data();
        data['doc_id'] = d.id;
        return data;
      }).toList();

      // Sort by requested_at descending
      requests.sort((a, b) {
        final aT = a['requested_at'];
        final bT = b['requested_at'];
        if (aT == null || bT == null) return 0;
        if (aT is Timestamp && bT is Timestamp) return bT.compareTo(aT);
        return 0;
      });

      final unread = requests.where((r) => r['read_by_admin'] == false).length;

      if (mounted) {
        setState(() {
          _recoveryRequests = requests;
          _unreadRecoveryCount = unread;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recovery requests: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAllRecoveryRead() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final r in _recoveryRequests) {
      if (r['read_by_admin'] == false) {
        final docId = r['doc_id'] as String? ?? r['email'] as String;
        batch.update(_fs.recoveryCol.doc(docId), {'read_by_admin': true});
      }
    }
    await batch.commit();
    if (mounted) setState(() => _unreadRecoveryCount = 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USER ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _approveUser(Map<String, dynamic> user) async {
    try {
      await _fs.updateUserStatus(user['uid'] as String, 'Approved');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name'] ?? user['email']} approved'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user, String reason) async {
    try {
      await _fs.updateUserStatus(user['uid'] as String, 'Rejected', reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name'] ?? user['email']} rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _blockUser(Map<String, dynamic> user, String reason) async {
    try {
      await _fs.updateUserStatus(user['uid'] as String, 'Blocked', reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name'] ?? user['email']} blocked'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _filterStatus = 'Blocked');
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unblockUser(Map<String, dynamic> user) async {
    try {
      await _fs.updateUserStatus(user['uid'] as String, 'Approved');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name'] ?? user['email']} unblocked'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _filterStatus = 'Approved');
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════════════════════════════════════════

  void _showBlockDialog(Map<String, dynamic> user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${user['name'] ?? user['email']}'),
            const SizedBox(height: 8),
            const Text(
              'Blocked users cannot log in.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Block Reason',
                hintText: 'e.g. Terms of Service violation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _blockUser(user, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${user['name'] ?? user['email']}'),
            const SizedBox(height: 8),
            const Text(
              'The user will be able to log in again.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _unblockUser(user);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${user['name'] ?? user['email']}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g. Unclear student ID photo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _rejectUser(user, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (ctx, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
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
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      Expanded(
                        child: Text(
                          '${user['name'] ?? 'Unknown'} (${user['email'] ?? ''})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(user['status'] as String? ?? ''),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Basic info
                      _buildInfoSection('Basic Information', [
                        _buildInfoRow('Email (Login ID)', user['email'] ?? '—'),
                        _buildInfoRow('Full Name', user['name'] ?? '—'),
                        if ((user['nickname'] as String? ?? '').isNotEmpty)
                          _buildInfoRow('Nickname', user['nickname'] as String),
                        _buildInfoRow('Nationality', user['nationality'] ?? '—'),
                        _buildInfoRow('Contact', user['contact'] ?? '—'),
                        _buildInfoRow('Role', user['role'] ?? '—'),
                        _buildInfoRow('Applied', _formatTimestamp(user['created_at'])),
                        if ((user['status_reason'] as String? ?? '').isNotEmpty)
                          _buildInfoRow('Status Reason', user['status_reason'] as String),
                      ]),
                      const SizedBox(height: 16),

                      // UID info
                      _buildInfoSection('Account ID', [
                        _buildInfoRow('Firebase UID', user['uid'] ?? '—'),
                      ]),
                      const SizedBox(height: 16),

                      // Admin-only warning
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin-only information — do not share externally',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      if (user['status'] == 'Pending')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showRejectDialog(user);
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
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
                                  Navigator.pop(ctx);
                                  _approveUser(user);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showBlockDialog(user);
                            },
                            icon: const Icon(Icons.block),
                            label: const Text('Block User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      if (user['status'] == 'Blocked')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showUnblockDialog(user);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Unblock'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
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

  void _showRecoveryDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Recovery Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Email', request['email'] ?? '—'),
            _buildInfoRow('Requested', _formatTimestamp(request['requested_at'])),
            _buildInfoRow('Status', request['status'] ?? '—'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to process:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Verify the user by sending a confirmation email\n'
                    '2. Click Approve after confirming identity\n'
                    '3. Send a temporary password to the user\'s email',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveRecoveryRequest(request);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Approve Recovery'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRecoveryRequest(Map<String, dynamic> request) async {
    final docId = request['doc_id'] as String? ?? request['email'] as String;
    final tempPw = 'Temp${DateTime.now().millisecondsSinceEpoch % 10000}!';

    try {
      await _fs.recoveryCol.doc(docId).update({
        'status': 'Approved',
        'temp_password': tempPw,
        'approved_at': FieldValue.serverTimestamp(),
        'read_by_admin': true,
      });

      await _loadRecoveryRequests();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Recovery Approved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recovery has been approved.\n\nTemporary password:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    tempPw,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please send this password to the user\'s email (${request['email']}).',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0038A8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0038A8),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final Map<String, Color> colors = {
      'Pending': Colors.orange,
      'Approved': Colors.green,
      'Rejected': Colors.red,
      'Blocked': Colors.black87,
    };
    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      backgroundColor: colors[status] ?? Colors.grey,
      padding: EdgeInsets.zero,
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) {
      final dt = ts.toDate().toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (ts is DateTime) {
      return '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} '
          '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isRecoveryTab = _filterStatus == 'Recovery';
    final listItems = isRecoveryTab ? _recoveryRequests : _users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Management'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _loadUsers();
              _loadRecoveryRequests();
            },
          ),
          // Recovery badge
          if (_unreadRecoveryCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.white),
                    tooltip: 'New recovery requests',
                    onPressed: () {
                      setState(() => _filterStatus = 'Recovery');
                      _markAllRecoveryRead();
                    },
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_unreadRecoveryCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: [
                  const ButtonSegment(
                    value: 'Pending',
                    label: Text('Pending'),
                    icon: Icon(Icons.hourglass_empty, size: 16),
                  ),
                  const ButtonSegment(
                    value: 'Approved',
                    label: Text('Approved'),
                    icon: Icon(Icons.check_circle, size: 16),
                  ),
                  const ButtonSegment(
                    value: 'Rejected',
                    label: Text('Rejected'),
                    icon: Icon(Icons.cancel, size: 16),
                  ),
                  const ButtonSegment(
                    value: 'Blocked',
                    label: Text('Blocked'),
                    icon: Icon(Icons.block, size: 16),
                  ),
                  ButtonSegment(
                    value: 'Recovery',
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Recovery'),
                        if (_unreadRecoveryCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_unreadRecoveryCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    icon: const Icon(Icons.restore, size: 16),
                  ),
                  const ButtonSegment(
                    value: 'All',
                    label: Text('All'),
                    icon: Icon(Icons.list, size: 16),
                  ),
                ],
                selected: {_filterStatus},
                onSelectionChanged: (Set<String> sel) async {
                  setState(() => _filterStatus = sel.first);
                  if (sel.first == 'Recovery') {
                    await _markAllRecoveryRead();
                  } else {
                    await _loadUsers();
                  }
                },
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : listItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        isRecoveryTab
                            ? 'No recovery requests'
                            : 'No users in this status',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _loadUsers();
                          _loadRecoveryRequests();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadUsers();
                    await _loadRecoveryRequests();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      final item = listItems[index];
                      if (isRecoveryTab) {
                        // Recovery request tile
                        final isUnread = item['read_by_admin'] == false;
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          color: isUnread ? Colors.orange.shade50 : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: isUnread ? Colors.orange : Colors.grey,
                              child: const Icon(Icons.restore, color: Colors.white),
                            ),
                            title: Text(
                              item['email'] ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Requested: ${_formatTimestamp(item['requested_at'])}'),
                                Text('Status: ${item['status'] ?? '—'}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isUnread)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.circle, color: Colors.orange, size: 10),
                                  ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () => _showRecoveryDetails(item),
                          ),
                        );
                      } else {
                        // User tile
                        final name = item['name'] as String? ?? '?';
                        final email = item['email'] as String? ?? '';
                        final nationality = item['nationality'] as String? ?? '';
                        final status = item['status'] as String? ?? '';
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0038A8),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Email: $email'),
                                if (nationality.isNotEmpty)
                                  Text('Nationality: $nationality'),
                                Text('Applied: ${_formatTimestamp(item['created_at'])}'),
                              ],
                            ),
                            trailing: _buildStatusChip(status),
                            onTap: () => _showUserDetails(item),
                          ),
                        );
                      }
                    },
                  ),
                ),
    );
  }
}
