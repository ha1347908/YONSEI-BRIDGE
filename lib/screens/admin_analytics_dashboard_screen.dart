import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

/// MVP 핵심 성장 지표 대시보드
/// 4개 섹션: 사용자 활성 지표 / 콘텐츠 반응도 / 리텐션 분석 / 관리자 운영 지표
class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() =>
      _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState
    extends State<AdminAnalyticsDashboardScreen> {
  bool _isLoading = true;
  String _selectedPeriod = '30'; // '7', '30', 'all'

  // ── 1. 사용자 활성 지표 ──────────────────────────────
  int _dau = 0;
  int _mau = 0;
  int _pendingApprovalCount = 0;
  Map<String, int> _usersByLanguage = {};

  // ── 2. 콘텐츠 반응도 ──────────────────────────────────
  List<Map<String, dynamic>> _topInfoPosts = []; // TOP 5 조회수 (정보게시판)
  int _freeBoardPostCount = 0;
  int _freeBoardCommentCount = 0;
  int _scrapCount = 0;

  // ── 3. 리텐션 분석 ────────────────────────────────────
  Map<String, Map<String, double>> _retentionData = {};
  double _actionRateReadInfo = 0; // 정보글 1개 이상 읽기 비율
  double _actionRateWriteComment = 0; // 댓글 작성 비율

  // ── 4. 관리자 운영 지표 ───────────────────────────────
  double _avgApprovalHours = 0;
  int _blockedUserCount = 0;
  int _rejectedUserCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ─────────────────────────────────────────────────────
  // 데이터 로드
  // ─────────────────────────────────────────────────────
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final cutoff = _selectedPeriod == 'all'
          ? DateTime(2020, 1, 1)
          : now.subtract(Duration(days: int.parse(_selectedPeriod)));

      await Future.wait([
        _loadUserActiveMetrics(prefs, now, cutoff),
        _loadContentMetrics(prefs, cutoff),
        _loadRetentionMetrics(prefs, cutoff),
        _loadAdminOperationMetrics(prefs),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 1. 사용자 활성 지표
  Future<void> _loadUserActiveMetrics(
      SharedPreferences prefs, DateTime now, DateTime cutoff) async {
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    int dau = 0, mau = 0, pending = 0;
    final langCount = <String, int>{};

    final allKeys = prefs.getKeys();

    // 가입 승인 대기
    for (final key in allKeys) {
      if (key.startsWith('user_') && !key.contains('login_')) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          final u = jsonDecode(raw) as Map<String, dynamic>;
          final status = u['status'] ?? u['approvalStatus'] ?? '';
          if (status == 'Pending' || status == 'pending') pending++;

          // 언어별 분류
          final lang = u['preferredLanguage'] ?? u['language'] ?? 'ko';
          langCount[lang] = (langCount[lang] ?? 0) + 1;

          // 로그인 기록으로 DAU/MAU 계산
          final uid = u['userId'] ?? u['id'] ?? '';
          if (uid.isEmpty) continue;
          final loginRaw = prefs.getString('user_login_$uid');
          if (loginRaw == null) continue;
          final logins = (jsonDecode(loginRaw) as List).cast<String>();
          for (final l in logins) {
            final d = DateTime.tryParse(l);
            if (d == null) continue;
            if (d.isAfter(today)) dau++;
            if (d.isAfter(monthStart)) mau++;
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _dau = dau;
        _mau = mau;
        _pendingApprovalCount = pending;
        _usersByLanguage = langCount;
      });
    }
  }

  /// 2. 콘텐츠 반응도
  Future<void> _loadContentMetrics(
      SharedPreferences prefs, DateTime cutoff) async {
    // 정보게시판 TOP 5 (posts_info_board)
    final infoRaw = prefs.getString('posts_info_board');
    final infoPosts = <Map<String, dynamic>>[];
    if (infoRaw != null) {
      try {
        final list = (jsonDecode(infoRaw) as List).cast<Map<String, dynamic>>();
        infoPosts.addAll(list);
      } catch (_) {}
    }
    infoPosts.sort((a, b) =>
        ((b['viewCount'] ?? 0) as int).compareTo((a['viewCount'] ?? 0) as int));

    // 자유게시판 게시글·댓글 수
    final freeRaw = prefs.getString('posts_free_board');
    int freePostCount = 0, commentCount = 0;
    if (freeRaw != null) {
      try {
        final list = (jsonDecode(freeRaw) as List).cast<Map<String, dynamic>>();
        freePostCount = list.length;
        for (final p in list) {
          final cmts = p['comments'] as List? ?? [];
          commentCount += cmts.length;
        }
      } catch (_) {}
    }

    // 스크랩 수 (saved_posts_*)
    int scrap = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('saved_posts_')) {
        final raw = prefs.getString(key);
        if (raw != null) {
          try {
            scrap += (jsonDecode(raw) as List).length;
          } catch (_) {}
        }
      }
    }

    if (mounted) {
      setState(() {
        _topInfoPosts = infoPosts.take(5).toList();
        _freeBoardPostCount = freePostCount;
        _freeBoardCommentCount = commentCount;
        _scrapCount = scrap;
      });
    }
  }

  /// 3. 리텐션 분석
  Future<void> _loadRetentionMetrics(
      SharedPreferences prefs, DateTime cutoff) async {
    final retentionData = <String, Map<String, double>>{};
    int totalApproved = 0, readInfo = 0, wroteComment = 0;

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('user_') || key.contains('login_')) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final u = jsonDecode(raw) as Map<String, dynamic>;
        final signupStr = u['signup_date'] ?? u['createdAt'];
        if (signupStr == null) continue;
        final signupDate = DateTime.tryParse(signupStr);
        if (signupDate == null || signupDate.isBefore(cutoff)) continue;

        final status = u['status'] ?? '';
        if (status == 'Approved' || status == 'approved') totalApproved++;

        final cohort = DateFormat('yyyy-MM-dd').format(signupDate);
        retentionData.putIfAbsent(
            cohort, () => {'day1': 0, 'day7': 0, 'day30': 0, 'total': 0});
        retentionData[cohort]!['total'] =
            retentionData[cohort]!['total']! + 1;

        final uid = u['userId'] ?? u['id'] ?? '';
        if (uid.isEmpty) continue;
        final loginRaw = prefs.getString('user_login_$uid');
        if (loginRaw != null) {
          final logins = (jsonDecode(loginRaw) as List).cast<String>();
          _checkRetention(logins, signupDate, retentionData[cohort]!);
        }

        // 핵심 액션: 정보글 읽기 여부
        final readRaw = prefs.getString('read_info_$uid');
        if (readRaw != null && (jsonDecode(readRaw) as List).isNotEmpty) {
          readInfo++;
        }

        // 핵심 액션: 댓글 작성 여부
        final cmtRaw = prefs.getString('comment_history_$uid');
        if (cmtRaw != null && (jsonDecode(cmtRaw) as List).isNotEmpty) {
          wroteComment++;
        }
      } catch (_) {}
    }

    // 비율(%) 변환
    retentionData.forEach((_, data) {
      final t = data['total']!;
      if (t > 0) {
        data['day1'] = data['day1']! / t * 100;
        data['day7'] = data['day7']! / t * 100;
        data['day30'] = data['day30']! / t * 100;
      }
    });

    if (mounted) {
      setState(() {
        _retentionData = retentionData;
        _actionRateReadInfo =
            totalApproved > 0 ? readInfo / totalApproved * 100 : 0;
        _actionRateWriteComment =
            totalApproved > 0 ? wroteComment / totalApproved * 100 : 0;
      });
    }
  }

  void _checkRetention(List<String> logins, DateTime signupDate,
      Map<String, double> cohortData) {
    bool d1 = false, d7 = false, d30 = false;
    for (final l in logins) {
      final d = DateTime.tryParse(l);
      if (d == null) continue;
      final diff = d.difference(signupDate).inDays;
      if (diff >= 1 && diff < 2) d1 = true;
      if (diff >= 7 && diff < 8) d7 = true;
      if (diff >= 30 && diff < 31) d30 = true;
    }
    if (d1) cohortData['day1'] = cohortData['day1']! + 1;
    if (d7) cohortData['day7'] = cohortData['day7']! + 1;
    if (d30) cohortData['day30'] = cohortData['day30']! + 1;
  }

  /// 4. 관리자 운영 지표
  Future<void> _loadAdminOperationMetrics(SharedPreferences prefs) async {
    int blocked = 0, rejected = 0;
    final approvalTimes = <double>[];

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('user_') || key.contains('login_')) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final u = jsonDecode(raw) as Map<String, dynamic>;
        final status = u['status'] ?? u['approvalStatus'] ?? '';
        if (status == 'Blocked' || status == 'blocked') blocked++;
        if (status == 'Rejected' || status == 'rejected') rejected++;

        // 승인 소요 시간 (신청일 → 승인일)
        final signupStr = u['signup_date'] ?? u['createdAt'];
        final approvedStr = u['approvedAt'] ?? u['approved_at'];
        if (signupStr != null && approvedStr != null) {
          final signup = DateTime.tryParse(signupStr);
          final approved = DateTime.tryParse(approvedStr);
          if (signup != null && approved != null) {
            approvalTimes
                .add(approved.difference(signup).inMinutes.toDouble() / 60);
          }
        }
      } catch (_) {}
    }

    final avgHours = approvalTimes.isNotEmpty
        ? approvalTimes.reduce((a, b) => a + b) / approvalTimes.length
        : 0.0;

    if (mounted) {
      setState(() {
        _blockedUserCount = blocked;
        _rejectedUserCount = rejected;
        _avgApprovalHours = avgHours;
      });
    }
  }

  // ─────────────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('데이터 분석 대시보드'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodFilter(),
                    const SizedBox(height: 20),

                    // ① 사용자 활성 지표
                    _buildSectionHeader(
                        '① 사용자 활성 지표', Icons.people_alt, const Color(0xFF0038A8)),
                    const SizedBox(height: 12),
                    _buildUserActiveSection(),
                    const SizedBox(height: 24),

                    // ② 콘텐츠 반응도
                    _buildSectionHeader(
                        '② 콘텐츠 반응도', Icons.bar_chart, const Color(0xFF6B4EFF)),
                    const SizedBox(height: 12),
                    _buildContentSection(),
                    const SizedBox(height: 24),

                    // ③ 리텐션 분석
                    _buildSectionHeader(
                        '③ 리텐션 분석', Icons.trending_up, const Color(0xFF00897B)),
                    const SizedBox(height: 12),
                    _buildRetentionSection(),
                    const SizedBox(height: 24),

                    // ④ 관리자 운영 지표
                    _buildSectionHeader(
                        '④ 관리자 운영 지표', Icons.admin_panel_settings, Colors.orange[700]!),
                    const SizedBox(height: 12),
                    _buildAdminOperationSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 공통 헬퍼 위젯
  // ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildStatTile(String label, String value,
      {Color? valueColor, IconData? icon}) {
    return Column(
      children: [
        if (icon != null) Icon(icon, color: valueColor ?? Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0038A8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('기간 설정',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _periodChip('최근 7일', '7'),
              const SizedBox(width: 8),
              _periodChip('최근 30일', '30'),
              const SizedBox(width: 8),
              _periodChip('전체', 'all'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) {
          setState(() => _selectedPeriod = value);
          _loadAllData();
        }
      },
      selectedColor: const Color(0xFF0038A8),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87,
          fontSize: 13),
    );
  }

  // ─────────────────────────────────────────────────────
  // ① 사용자 활성 지표
  // ─────────────────────────────────────────────────────
  Widget _buildUserActiveSection() {
    return Column(
      children: [
        // DAU / MAU / 승인 대기
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile('DAU\n(오늘 접속)', '$_dau명',
                  valueColor: const Color(0xFF0038A8), icon: Icons.today),
              _verticalDivider(),
              _buildStatTile('MAU\n(이번 달 접속)', '$_mau명',
                  valueColor: const Color(0xFF6B4EFF), icon: Icons.calendar_month),
              _verticalDivider(),
              _buildStatTile('신규 가입\n승인 대기', '$_pendingApprovalCount명',
                  valueColor: Colors.orange[700], icon: Icons.hourglass_top),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 언어별 사용자 비율
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('언어별 사용자 비율',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              if (_usersByLanguage.isEmpty)
                const Center(
                    child: Text('데이터 없음',
                        style: TextStyle(color: Colors.grey)))
              else
                ..._buildLanguageBar(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLanguageBar() {
    final labels = {'ko': '한국어', 'en': 'English', 'zh': '中文', 'ja': '日本語'};
    final colors = {
      'ko': const Color(0xFF0038A8),
      'en': const Color(0xFF6B4EFF),
      'zh': Colors.red[400]!,
      'ja': Colors.green[600]!,
    };
    final total = _usersByLanguage.values.fold(0, (a, b) => a + b);
    return _usersByLanguage.entries.map((e) {
      final pct = total > 0 ? e.value / total : 0.0;
      final label = labels[e.key] ?? e.key;
      final color = colors[e.key] ?? Colors.grey;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${e.value}명 (${(pct * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 13, color: color,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _verticalDivider() {
    return Container(height: 48, width: 1, color: Colors.grey[200]);
  }

  // ─────────────────────────────────────────────────────
  // ② 콘텐츠 반응도
  // ─────────────────────────────────────────────────────
  Widget _buildContentSection() {
    return Column(
      children: [
        // 자유게시판 게시글-댓글 비율 + 스크랩 수
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile('자유게시판\n게시글 수', '$_freeBoardPostCount건',
                  valueColor: const Color(0xFF6B4EFF), icon: Icons.edit_note),
              _verticalDivider(),
              _buildStatTile('댓글 수', '$_freeBoardCommentCount건',
                  valueColor: const Color(0xFF00897B), icon: Icons.comment),
              _verticalDivider(),
              _buildStatTile('게시글\n스크랩 수', '$_scrapCount건',
                  valueColor: Colors.orange[700], icon: Icons.bookmark),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 정보게시판 TOP 5 조회수
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('정보게시판 TOP 5 조회수',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              if (_topInfoPosts.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('게시글 데이터 없음',
                      style: TextStyle(color: Colors.grey)),
                ))
              else
                ..._topInfoPosts.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final post = e.value;
                  final title =
                      post['title'] as String? ?? '(제목 없음)';
                  final views =
                      (post['viewCount'] ?? post['views'] ?? 0) as int;
                  return _buildRankRow(rank, title, '$views회');
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(int rank, String title, String metric) {
    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.grey[400]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: rankColor,
            child: Text('$rank',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13))),
          Text(metric,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0038A8))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // ③ 리텐션 분석
  // ─────────────────────────────────────────────────────
  Widget _buildRetentionSection() {
    return Column(
      children: [
        // 핵심 액션 수행률
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('핵심 액션 수행률',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _buildActionRateRow(
                  '정보글 1개 이상 읽기', _actionRateReadInfo, const Color(0xFF0038A8)),
              const SizedBox(height: 10),
              _buildActionRateRow(
                  '댓글 작성 경험', _actionRateWriteComment, const Color(0xFF6B4EFF)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Day-N 리텐션 테이블
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Day-N 리텐션 (코호트별)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              if (_retentionData.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('리텐션 데이터 없음',
                      style: TextStyle(color: Colors.grey)),
                ))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                    columns: const [
                      DataColumn(label: Text('코호트')),
                      DataColumn(label: Text('Day 1 (%)')),
                      DataColumn(label: Text('Day 7 (%)')),
                      DataColumn(label: Text('Day 30 (%)')),
                    ],
                    rows: _retentionData.entries.map((e) {
                      return DataRow(cells: [
                        DataCell(Text(e.key,
                            style: const TextStyle(fontSize: 12))),
                        DataCell(_retentionCell(e.value['day1']!)),
                        DataCell(_retentionCell(e.value['day7']!)),
                        DataCell(_retentionCell(e.value['day30']!)),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRateRow(String label, double rate, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _retentionCell(double value) {
    Color color = Colors.grey;
    if (value >= 40) {
      color = Colors.green[700]!;
    } else if (value >= 20) {
      color = Colors.orange[700]!;
    } else if (value > 0) {
      color = Colors.red[400]!;
    }
    return Text(
      '${value.toStringAsFixed(1)}%',
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color),
    );
  }

  // ─────────────────────────────────────────────────────
  // ④ 관리자 운영 지표
  // ─────────────────────────────────────────────────────
  Widget _buildAdminOperationSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile(
                '평균 승인\n소요 시간',
                _avgApprovalHours > 0
                    ? '${_avgApprovalHours.toStringAsFixed(1)}h'
                    : '-',
                valueColor: Colors.orange[700],
                icon: Icons.timer_outlined,
              ),
              _verticalDivider(),
              _buildStatTile(
                '차단 유저 수',
                '$_blockedUserCount명',
                valueColor: Colors.red[600],
                icon: Icons.block,
              ),
              _verticalDivider(),
              _buildStatTile(
                '가입 거절\n유저 수',
                '$_rejectedUserCount명',
                valueColor: Colors.grey[700],
                icon: Icons.person_off,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '회원 승인은 수동으로 진행됩니다.\n관리자 승인 화면에서 개별 검토 후 승인/거절하세요.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
