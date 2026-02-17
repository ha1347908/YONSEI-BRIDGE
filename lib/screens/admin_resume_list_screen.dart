import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminResumeListScreen extends StatefulWidget {
  const AdminResumeListScreen({super.key});

  @override
  State<AdminResumeListScreen> createState() => _AdminResumeListScreenState();
}

class _AdminResumeListScreenState extends State<AdminResumeListScreen> {
  List<Map<String, dynamic>> _resumes = [];
  List<Map<String, dynamic>> _filteredResumes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, pending, reviewed

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final resumeList = <Map<String, dynamic>>[];

    // Load all resumes from SharedPreferences
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('resume_')) {
        final resumeJson = prefs.getString(key);
        if (resumeJson != null) {
          try {
            final resume = jsonDecode(resumeJson) as Map<String, dynamic>;
            resume['id'] = key;
            resumeList.add(resume);
          } catch (e) {
            debugPrint('Error parsing resume: $e');
          }
        }
      }
    }

    // Sort by submission date (most recent first)
    resumeList.sort((a, b) {
      final dateA = DateTime.tryParse(a['submittedAt'] as String? ?? '');
      final dateB = DateTime.tryParse(b['submittedAt'] as String? ?? '');
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    setState(() {
      _resumes = resumeList;
      _filteredResumes = resumeList;
      _isLoading = false;
    });
  }

  void _filterResumes() {
    setState(() {
      _filteredResumes = _resumes.where((resume) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            (resume['name'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (resume['email'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (resume['phone'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

        // Status filter
        final status = resume['status'] as String? ?? 'pending';
        final matchesStatus = _filterStatus == 'all' || status == _filterStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _updateResumeStatus(String resumeId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final resumeJson = prefs.getString(resumeId);
    if (resumeJson != null) {
      final resume = jsonDecode(resumeJson) as Map<String, dynamic>;
      resume['status'] = newStatus;
      resume['reviewedAt'] = DateTime.now().toIso8601String();
      await prefs.setString(resumeId, jsonEncode(resume));
      await _loadResumes();
    }
  }

  void _showResumeDetails(Map<String, dynamic> resume) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    const Icon(Icons.description, size: 32, color: Color(0xFF0038A8)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'NeedJob 이력서',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(resume['status'] as String? ?? 'pending'),
                  ],
                ),
                const Divider(height: 32),

                // Personal Information
                _buildSection(
                  title: '개인 정보',
                  icon: Icons.person,
                  children: [
                    _buildInfoRow('이름', resume['name'] ?? '-'),
                    _buildInfoRow('이메일', resume['email'] ?? '-'),
                    _buildInfoRow('전화번호', resume['phone'] ?? '-'),
                    _buildInfoRow('국적', resume['nationality'] ?? '-'),
                    _buildInfoRow('생년월일', resume['birthDate'] ?? '-'),
                  ],
                ),

                // Education
                _buildSection(
                  title: '학력',
                  icon: Icons.school,
                  children: [
                    _buildInfoRow('학교', resume['school'] ?? '-'),
                    _buildInfoRow('전공', resume['major'] ?? '-'),
                    _buildInfoRow('학위', resume['degree'] ?? '-'),
                    _buildInfoRow('졸업 연도', resume['graduationYear'] ?? '-'),
                  ],
                ),

                // Work Experience
                if (resume['workExperience'] != null) ...[
                  _buildSection(
                    title: '경력',
                    icon: Icons.work,
                    children: [
                      Text(
                        resume['workExperience'] as String,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ],

                // Skills
                if (resume['skills'] != null) ...[
                  _buildSection(
                    title: '기술',
                    icon: Icons.star,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (resume['skills'] as String)
                            .split(',')
                            .map((skill) => Chip(
                                  label: Text(skill.trim()),
                                  backgroundColor: const Color(0xFF0038A8).withOpacity(0.1),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ],

                // Languages
                if (resume['languages'] != null) ...[
                  _buildSection(
                    title: '언어',
                    icon: Icons.language,
                    children: [
                      Text(
                        resume['languages'] as String,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ],

                // Self Introduction
                if (resume['introduction'] != null) ...[
                  _buildSection(
                    title: '자기소개',
                    icon: Icons.comment,
                    children: [
                      Text(
                        resume['introduction'] as String,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ],

                // Submission Info
                _buildSection(
                  title: '제출 정보',
                  icon: Icons.info_outline,
                  children: [
                    _buildInfoRow(
                      '제출 일시',
                      _formatDate(resume['submittedAt'] as String?),
                    ),
                    if (resume['reviewedAt'] != null)
                      _buildInfoRow(
                        '검토 일시',
                        _formatDate(resume['reviewedAt'] as String?),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateResumeStatus(resume['id'] as String, 'reviewed');
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('검토 완료'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('닫기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0038A8)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'reviewed':
        color = Colors.green;
        label = '검토 완료';
        icon = Icons.check_circle;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        label = '검토 대기';
        icon = Icons.pending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeedJob 이력서 관리'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResumes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search field
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterResumes();
                  },
                  decoration: InputDecoration(
                    hintText: '이름, 이메일, 전화번호로 검색...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter chips
                Row(
                  children: [
                    const Text('상태: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('전체'),
                            selected: _filterStatus == 'all',
                            onSelected: (selected) {
                              setState(() {
                                _filterStatus = 'all';
                              });
                              _filterResumes();
                            },
                          ),
                          FilterChip(
                            label: const Text('검토 대기'),
                            selected: _filterStatus == 'pending',
                            onSelected: (selected) {
                              setState(() {
                                _filterStatus = 'pending';
                              });
                              _filterResumes();
                            },
                          ),
                          FilterChip(
                            label: const Text('검토 완료'),
                            selected: _filterStatus == 'reviewed',
                            onSelected: (selected) {
                              setState(() {
                                _filterStatus = 'reviewed';
                              });
                              _filterResumes();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Resume list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResumes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? '제출된 이력서가 없습니다'
                                  : '검색 결과가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadResumes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredResumes.length,
                          itemBuilder: (context, index) {
                            final resume = _filteredResumes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0038A8),
                                  child: Text(
                                    (resume['name'] as String? ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  resume['name'] as String? ?? '이름 없음',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(resume['email'] as String? ?? '-'),
                                    const SizedBox(height: 4),
                                    Text(
                                      '제출: ${_formatDate(resume['submittedAt'] as String?)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: _buildStatusBadge(
                                  resume['status'] as String? ?? 'pending',
                                ),
                                onTap: () => _showResumeDetails(resume),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
