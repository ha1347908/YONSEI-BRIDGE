import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  List<Map<String, dynamic>> _symptomCards = [];
  bool _isLoading = true;
  
  int _totalCards = 0;
  Map<String, int> _symptomCounts = {};
  Map<String, int> _monthlyStats = {};
  String _selectedMonth = 'all';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final cardList = <Map<String, dynamic>>[];

    // Load all symptom cards from SharedPreferences
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('symptom_card_')) {
        final cardJson = prefs.getString(key);
        if (cardJson != null) {
          try {
            final card = jsonDecode(cardJson) as Map<String, dynamic>;
            card['id'] = key;
            cardList.add(card);
          } catch (e) {
            debugPrint('Error parsing symptom card: $e');
          }
        }
      }
    }

    // Sort by creation date (most recent first)
    cardList.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt'] as String? ?? '');
      final dateB = DateTime.tryParse(b['createdAt'] as String? ?? '');
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    // Calculate statistics
    final symptomCounts = <String, int>{};
    final monthlyStats = <String, int>{};

    for (final card in cardList) {
      // Count by symptom
      final symptoms = card['symptoms'] as List<dynamic>?;
      if (symptoms != null) {
        for (final symptom in symptoms) {
          final symptomName = symptom.toString();
          symptomCounts[symptomName] = (symptomCounts[symptomName] ?? 0) + 1;
        }
      }

      // Count by month
      final createdAt = DateTime.tryParse(card['createdAt'] as String? ?? '');
      if (createdAt != null) {
        final monthKey = DateFormat('yyyy-MM').format(createdAt);
        monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
      }
    }

    setState(() {
      _symptomCards = cardList;
      _totalCards = cardList.length;
      _symptomCounts = symptomCounts;
      _monthlyStats = monthlyStats;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredCards {
    if (_selectedMonth == 'all') {
      return _symptomCards;
    }

    return _symptomCards.where((card) {
      final createdAt = DateTime.tryParse(card['createdAt'] as String? ?? '');
      if (createdAt == null) return false;
      final monthKey = DateFormat('yyyy-MM').format(createdAt);
      return monthKey == _selectedMonth;
    }).toList();
  }

  void _showCardDetails(Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
                const Row(
                  children: [
                    Icon(Icons.medical_services, size: 32, color: Color(0xFFFF9800)),
                    SizedBox(width: 12),
                    Text(
                      '증상카드 상세',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // User information
                _buildSection(
                  title: '사용자 정보',
                  icon: Icons.person,
                  children: [
                    _buildInfoRow('이름', card['userName'] ?? '-'),
                    _buildInfoRow('사용자 ID', card['userId'] ?? '-'),
                  ],
                ),

                // Symptoms
                _buildSection(
                  title: '증상',
                  icon: Icons.healing,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (card['symptoms'] as List<dynamic>? ?? [])
                          .map((symptom) => Chip(
                                label: Text(symptom.toString()),
                                backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                                avatar: const Icon(Icons.local_hospital, size: 16),
                              ))
                          .toList(),
                    ),
                  ],
                ),

                // Additional notes
                if (card['notes'] != null && (card['notes'] as String).isNotEmpty) ...[
                  _buildSection(
                    title: '추가 메모',
                    icon: Icons.note,
                    children: [
                      Text(
                        card['notes'] as String,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ],

                // Timestamp
                _buildSection(
                  title: '생성 정보',
                  icon: Icons.access_time,
                  children: [
                    _buildInfoRow(
                      '생성 일시',
                      _formatDate(card['createdAt'] as String?),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0038A8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('닫기'),
                  ),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatMonth(String monthKey) {
    try {
      final date = DateTime.parse('$monthKey-01');
      return DateFormat('yyyy년 MM월').format(date);
    } catch (e) {
      return monthKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('증상카드 통계'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF9800),
                            Color(0xFFFF5722),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bar_chart, color: Colors.white, size: 32),
                              SizedBox(width: 12),
                              Text(
                                '총 누적 통계',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '총 출력 건수',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_totalCards건',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    '증상 종류',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_symptomCounts.length}종',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Month filter
                  const Text(
                    '📅 기간별 조회',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('전체'),
                        selected: _selectedMonth == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _selectedMonth = 'all';
                          });
                        },
                      ),
                      ..._monthlyStats.keys.map((month) {
                        return FilterChip(
                          label: Text('${_formatMonth(month)} (${_monthlyStats[month]}건)'),
                          selected: _selectedMonth == month,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMonth = month;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Top symptoms
                  const Text(
                    '📊 주요 증상 TOP 10',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: () {
                          final sortedSymptoms = _symptomCounts.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          
                          return sortedSymptoms
                            .take(10)
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final symptomEntry = entry.value;
                          final percentage = (_totalCards > 0
                              ? (symptomEntry.value / _totalCards * 100)
                              : 0.0);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: _getColorForRank(index),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              symptomEntry.key,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${symptomEntry.value}건 (${percentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getColorForRank(index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                        }(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📋 최근 출력 내역',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_filteredCards.length}건',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_filteredCards.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '출력된 증상카드가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...(_filteredCards.take(20).map((card) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFF9800),
                            child: Icon(
                              Icons.medical_services,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            card['userName'] as String? ?? '사용자',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '증상: ${(card['symptoms'] as List<dynamic>? ?? []).join(', ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(card['createdAt'] as String?),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _showCardDetails(card),
                        ),
                      );
                    }).toList()),
                  
                  if (_filteredCards.length > 20)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '+ ${_filteredCards.length - 20}건 더 있습니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Color _getColorForRank(int rank) {
    if (rank == 0) return const Color(0xFFFFD700); // Gold
    if (rank == 1) return const Color(0xFFC0C0C0); // Silver
    if (rank == 2) return const Color(0xFFCD7F32); // Bronze
    return const Color(0xFF0038A8); // Yonsei Blue
  }
}
