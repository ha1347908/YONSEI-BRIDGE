import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../services/language_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() => _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState extends State<AdminAnalyticsDashboardScreen> {
  bool _isLoading = true;
  String _selectedPeriod = '30'; // 7, 30, or 'all'
  
  // Retention data
  Map<String, Map<String, double>> _retentionData = {};
  
  // MAU by Visa Type
  Map<String, int> _mauByVisa = {};
  
  // Living Setup clicks
  Map<String, int> _livingSetupClicks = {};
  
  // NeedJob conversion rate
  Map<String, Map<String, int>> _needJobData = {};
  
  // Chat response time
  Map<String, double> _chatResponseTime = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final cutoffDate = _selectedPeriod == 'all' 
          ? DateTime(2020, 1, 1)
          : now.subtract(Duration(days: int.parse(_selectedPeriod)));

      // 1. Load Retention Data
      await _loadRetentionData(prefs, cutoffDate);
      
      // 2. Load MAU by Visa Type
      await _loadMAUByVisa(prefs, cutoffDate);
      
      // 3. Load Living Setup Clicks
      await _loadLivingSetupClicks(prefs, cutoffDate);
      
      // 4. Load NeedJob Conversion Rate
      await _loadNeedJobData(prefs, cutoffDate);
      
      // 5. Load Chat Response Time
      await _loadChatResponseTime(prefs, cutoffDate);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading analytics: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRetentionData(SharedPreferences prefs, DateTime cutoffDate) async {
    // Calculate retention from user login data
    final retentionData = <String, Map<String, double>>{};
    
    // Get all user keys
    final allKeys = prefs.getKeys();
    final userKeys = allKeys.where((key) => key.startsWith('user_') && !key.contains('login_')).toList();
    
    for (final userKey in userKeys) {
      final userData = prefs.getString(userKey);
      if (userData != null) {
        try {
          final user = jsonDecode(userData);
          final signupDate = DateTime.parse(user['signup_date'] ?? DateTime.now().toIso8601String());
          
          if (signupDate.isAfter(cutoffDate)) {
            final cohortWeek = DateFormat('yyyy-MM-dd').format(signupDate);
            
            if (!retentionData.containsKey(cohortWeek)) {
              retentionData[cohortWeek] = {'day1': 0, 'day7': 0, 'day30': 0, 'total': 0};
            }
            
            retentionData[cohortWeek]!['total'] = (retentionData[cohortWeek]!['total']! + 1);
            
            // Check login activity
            final loginKey = 'user_login_${user['userId']}';
            final loginData = prefs.getString(loginKey);
            if (loginData != null) {
              final logins = jsonDecode(loginData) as List;
              
              // Day 1 retention
              final day1 = signupDate.add(const Duration(days: 1));
              if (logins.any((l) => DateTime.parse(l).isAfter(day1) && DateTime.parse(l).isBefore(day1.add(const Duration(days: 1))))) {
                retentionData[cohortWeek]!['day1'] = (retentionData[cohortWeek]!['day1']! + 1);
              }
              
              // Day 7 retention
              final day7 = signupDate.add(const Duration(days: 7));
              if (logins.any((l) => DateTime.parse(l).isAfter(day7) && DateTime.parse(l).isBefore(day7.add(const Duration(days: 1))))) {
                retentionData[cohortWeek]!['day7'] = (retentionData[cohortWeek]!['day7']! + 1);
              }
              
              // Day 30 retention
              final day30 = signupDate.add(const Duration(days: 30));
              if (logins.any((l) => DateTime.parse(l).isAfter(day30) && DateTime.parse(l).isBefore(day30.add(const Duration(days: 1))))) {
                retentionData[cohortWeek]!['day30'] = (retentionData[cohortWeek]!['day30']! + 1);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing user data: $e');
          }
        }
      }
    }
    
    // Calculate percentages
    retentionData.forEach((cohort, data) {
      final total = data['total']!;
      if (total > 0) {
        data['day1'] = (data['day1']! / total * 100);
        data['day7'] = (data['day7']! / total * 100);
        data['day30'] = (data['day30']! / total * 100);
      }
    });
    
    setState(() {
      _retentionData = retentionData;
    });
  }

  Future<void> _loadMAUByVisa(SharedPreferences prefs, DateTime cutoffDate) async {
    final mauData = <String, int>{};
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Get all users
    final allKeys = prefs.getKeys();
    final userKeys = allKeys.where((key) => key.startsWith('user_demo_') || key.startsWith('user_')).toList();
    
    for (final userKey in userKeys) {
      final userData = prefs.getString(userKey);
      if (userData != null) {
        try {
          final user = jsonDecode(userData);
          final userId = user['userId'] ?? userKey.replaceAll('user_demo_', '').replaceAll('user_', '');
          
          // Check if user was active this month
          final loginKey = 'user_login_$userId';
          final loginData = prefs.getString(loginKey);
          if (loginData != null) {
            final logins = jsonDecode(loginData) as List;
            final hasLoginThisMonth = logins.any((l) {
              final loginDate = DateTime.parse(l);
              return loginDate.isAfter(monthStart);
            });
            
            if (hasLoginThisMonth) {
              final visa = user['visa'] ?? user['visaCode'] ?? 'Unknown';
              mauData[visa] = (mauData[visa] ?? 0) + 1;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing MAU data: $e');
          }
        }
      }
    }
    
    setState(() {
      _mauByVisa = mauData;
    });
  }

  Future<void> _loadLivingSetupClicks(SharedPreferences prefs, DateTime cutoffDate) async {
    final clickData = <String, int>{};
    
    // Get all living setup click logs
    final allKeys = prefs.getKeys();
    final clickKeys = allKeys.where((key) => key.startsWith('living_setup_click_')).toList();
    
    for (final clickKey in clickKeys) {
      final clickLog = prefs.getString(clickKey);
      if (clickLog != null) {
        try {
          final log = jsonDecode(clickLog);
          final clickDate = DateTime.parse(log['timestamp']);
          
          if (clickDate.isAfter(cutoffDate)) {
            final category = log['category'] ?? 'Unknown';
            clickData[category] = (clickData[category] ?? 0) + 1;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing click data: $e');
          }
        }
      }
    }
    
    // Sort by clicks and get top 10
    final sortedEntries = clickData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top10 = Map.fromEntries(sortedEntries.take(10));
    
    setState(() {
      _livingSetupClicks = top10;
    });
  }

  Future<void> _loadNeedJobData(SharedPreferences prefs, DateTime cutoffDate) async {
    final jobData = <String, Map<String, int>>{};
    
    // Get all NeedJob interaction logs
    final allKeys = prefs.getKeys();
    final viewKeys = allKeys.where((key) => key.startsWith('needjob_view_')).toList();
    final applyKeys = allKeys.where((key) => key.startsWith('needjob_apply_')).toList();
    
    // Count views by category
    for (final viewKey in viewKeys) {
      final viewLog = prefs.getString(viewKey);
      if (viewLog != null) {
        try {
          final log = jsonDecode(viewLog);
          final viewDate = DateTime.parse(log['timestamp']);
          
          if (viewDate.isAfter(cutoffDate)) {
            final category = log['category'] ?? 'Unknown';
            if (!jobData.containsKey(category)) {
              jobData[category] = {'views': 0, 'applies': 0};
            }
            jobData[category]!['views'] = (jobData[category]!['views']! + 1);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing view data: $e');
          }
        }
      }
    }
    
    // Count applies by category
    for (final applyKey in applyKeys) {
      final applyLog = prefs.getString(applyKey);
      if (applyLog != null) {
        try {
          final log = jsonDecode(applyLog);
          final applyDate = DateTime.parse(log['timestamp']);
          
          if (applyDate.isAfter(cutoffDate)) {
            final category = log['category'] ?? 'Unknown';
            if (!jobData.containsKey(category)) {
              jobData[category] = {'views': 0, 'applies': 0};
            }
            jobData[category]!['applies'] = (jobData[category]!['applies']! + 1);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing apply data: $e');
          }
        }
      }
    }
    
    setState(() {
      _needJobData = jobData;
    });
  }

  Future<void> _loadChatResponseTime(SharedPreferences prefs, DateTime cutoffDate) async {
    final responseTimes = <double>[];
    
    // Get all chat message logs
    final allKeys = prefs.getKeys();
    final messageKeys = allKeys.where((key) => key.startsWith('chat_message_')).toList();
    
    final conversations = <String, List<Map<String, dynamic>>>{};
    
    for (final messageKey in messageKeys) {
      final messageData = prefs.getString(messageKey);
      if (messageData != null) {
        try {
          final message = jsonDecode(messageData);
          final messageDate = DateTime.parse(message['timestamp']);
          
          if (messageDate.isAfter(cutoffDate)) {
            final conversationId = message['conversationId'] ?? 'unknown';
            if (!conversations.containsKey(conversationId)) {
              conversations[conversationId] = [];
            }
            conversations[conversationId]!.add(message);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing message data: $e');
          }
        }
      }
    }
    
    // Calculate response times
    for (final messages in conversations.values) {
      messages.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
      
      for (int i = 0; i < messages.length - 1; i++) {
        if (messages[i]['senderId'] != messages[i + 1]['senderId']) {
          final firstTime = DateTime.parse(messages[i]['timestamp']);
          final secondTime = DateTime.parse(messages[i + 1]['timestamp']);
          final diffMinutes = secondTime.difference(firstTime).inMinutes.toDouble();
          
          if (diffMinutes < 1440) { // Less than 24 hours
            responseTimes.add(diffMinutes);
          }
        }
      }
    }
    
    // Calculate average and median
    if (responseTimes.isNotEmpty) {
      responseTimes.sort();
      final average = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      final median = responseTimes.length.isOdd
          ? responseTimes[responseTimes.length ~/ 2]
          : (responseTimes[responseTimes.length ~/ 2 - 1] + responseTimes[responseTimes.length ~/ 2]) / 2;
      
      setState(() {
        _chatResponseTime = {
          'average': average,
          'median': median,
        };
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final List<List<dynamic>> rows = [];
      
      // Header
      rows.add(['데이터 분석 리포트', '생성일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}']);
      rows.add([]);
      
      // 1. Retention Data
      rows.add(['1. 리텐션 분석']);
      rows.add(['코호트', 'Day 1 (%)', 'Day 7 (%)', 'Day 30 (%)']);
      _retentionData.forEach((cohort, data) {
        rows.add([
          cohort,
          data['day1']?.toStringAsFixed(1),
          data['day7']?.toStringAsFixed(1),
          data['day30']?.toStringAsFixed(1),
        ]);
      });
      rows.add([]);
      
      // 2. MAU by Visa
      rows.add(['2. 비자별 활성 유저 (MAU)']);
      rows.add(['비자 타입', '활성 유저 수']);
      _mauByVisa.forEach((visa, count) {
        rows.add([visa, count]);
      });
      rows.add([]);
      
      // 3. Living Setup Clicks
      rows.add(['3. 리빙셋업 클릭 로그 (TOP 10)']);
      rows.add(['카테고리', '클릭 수']);
      _livingSetupClicks.forEach((category, clicks) {
        rows.add([category, clicks]);
      });
      rows.add([]);
      
      // 4. NeedJob Conversion
      rows.add(['4. 니드잡 지원 전환율']);
      rows.add(['카테고리', '조회수', '지원수', '전환율 (%)']);
      _needJobData.forEach((category, data) {
        final views = data['views']!;
        final applies = data['applies']!;
        final rate = views > 0 ? (applies / views * 100) : 0;
        rows.add([category, views, applies, rate.toStringAsFixed(1)]);
      });
      rows.add([]);
      
      // 5. Chat Response Time
      rows.add(['5. 채팅 응답 속도']);
      rows.add(['지표', '시간 (분)']);
      rows.add(['평균', _chatResponseTime['average']?.toStringAsFixed(1) ?? 'N/A']);
      rows.add(['중앙값', _chatResponseTime['median']?.toStringAsFixed(1) ?? 'N/A']);
      
      // Convert to CSV
      final csv = const ListToCsvConverter().convert(rows);
      
      // Save file (Web platform - show data)
      if (kIsWeb) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('CSV 데이터'),
              content: SingleChildScrollView(
                child: SelectableText(csv),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
          );
        }
      } else {
        // Mobile platform - save to file
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/analytics_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File(path);
        await file.writeAsString(csv);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV 파일 저장 완료: $path')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting CSV: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV 내보내기 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터 분석 대시보드'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToCSV,
            tooltip: 'CSV 다운로드',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period filter
                    _buildPeriodFilter(),
                    const SizedBox(height: 24),
                    
                    // 1. Retention Analysis
                    _buildRetentionSection(),
                    const SizedBox(height: 24),
                    
                    // 2. MAU by Visa Type
                    _buildMAUSection(),
                    const SizedBox(height: 24),
                    
                    // 3. Living Setup Clicks
                    _buildLivingSetupSection(),
                    const SizedBox(height: 24),
                    
                    // 4. NeedJob Conversion Rate
                    _buildNeedJobSection(),
                    const SizedBox(height: 24),
                    
                    // 5. Chat Response Time
                    _buildChatResponseSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기간 설정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPeriodChip('최근 7일', '7'),
                const SizedBox(width: 8),
                _buildPeriodChip('최근 30일', '30'),
                const SizedBox(width: 8),
                _buildPeriodChip('전체 기간', 'all'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
          });
          _loadAnalyticsData();
        }
      },
      selectedColor: const Color(0xFF0038A8),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildRetentionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF0038A8)),
                const SizedBox(width: 8),
                const Text(
                  '1. 리텐션 분석 (Retention Analysis)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_retentionData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('리텐션 데이터가 없습니다'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('코호트')),
                    DataColumn(label: Text('Day 1 (%)')),
                    DataColumn(label: Text('Day 7 (%)')),
                    DataColumn(label: Text('Day 30 (%)')),
                  ],
                  rows: _retentionData.entries.map((entry) {
                    return DataRow(cells: [
                      DataCell(Text(entry.key)),
                      DataCell(Text(entry.value['day1']!.toStringAsFixed(1))),
                      DataCell(Text(entry.value['day7']!.toStringAsFixed(1))),
                      DataCell(Text(entry.value['day30']!.toStringAsFixed(1))),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMAUSection() {
    if (_mauByVisa.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF0038A8)),
                  const SizedBox(width: 8),
                  const Text(
                    '2. 비자별 활성 유저 (MAU by Visa Type)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('비자별 활성 유저 데이터가 없습니다'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _mauByVisa.values.reduce((a, b) => a + b);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF0038A8)),
                const SizedBox(width: 8),
                const Text(
                  '2. 비자별 활성 유저 (MAU by Visa Type)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '총 활성 유저: $total명',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._mauByVisa.entries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${entry.value}명 ($percentage%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLivingSetupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app, color: Color(0xFF0038A8)),
                const SizedBox(width: 8),
                const Text(
                  '3. 리빙셋업 클릭 로그 (TOP 10)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_livingSetupClicks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('클릭 로그 데이터가 없습니다'),
                ),
              )
            else
              ..._livingSetupClicks.entries.toList().asMap().entries.map((indexedEntry) {
                final index = indexedEntry.key;
                final entry = indexedEntry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index < 3 ? _getRankColor(index).withValues(alpha: 0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: index < 3 ? _getRankColor(index) : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index < 3 ? _getRankColor(index) : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}회',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0038A8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  Widget _buildNeedJobSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work, color: Color(0xFF0038A8)),
                const SizedBox(width: 8),
                const Text(
                  '4. 니드잡 지원 전환율',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_needJobData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('니드잡 전환율 데이터가 없습니다'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('카테고리')),
                    DataColumn(label: Text('조회수')),
                    DataColumn(label: Text('지원수')),
                    DataColumn(label: Text('전환율 (%)')),
                  ],
                  rows: _needJobData.entries.map((entry) {
                    final views = entry.value['views']!;
                    final applies = entry.value['applies']!;
                    final rate = views > 0 ? (applies / views * 100) : 0;
                    
                    return DataRow(cells: [
                      DataCell(Text(entry.key)),
                      DataCell(Text('$views')),
                      DataCell(Text('$applies')),
                      DataCell(
                        Text(
                          rate.toStringAsFixed(1),
                          style: TextStyle(
                            color: rate >= 10 ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatResponseSection() {
    final hasData = _chatResponseTime.isNotEmpty;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFF0038A8)),
                const SizedBox(width: 8),
                const Text(
                  '5. 커뮤니티 채팅 응답 속도',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!hasData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('채팅 응답 속도 데이터가 없습니다'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '평균 응답 시간',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_chatResponseTime['average']!.toStringAsFixed(1)}분',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0038A8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '중앙값',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_chatResponseTime['median']!.toStringAsFixed(1)}분',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
