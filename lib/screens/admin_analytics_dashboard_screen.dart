import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// MVP 핵심 성장 지표 대시보드 — Firestore 실시간 데이터 기반
class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() =>
      _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState
    extends State<AdminAnalyticsDashboardScreen> {
  final _db = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _error = '';

  // ── 1. 사용자 지표 ──────────────────────────────────
  int _totalUsers = 0;
  int _approvedUsers = 0;
  int _pendingUsers = 0;
  int _blockedUsers = 0;
  int _rejectedUsers = 0;
  Map<String, int> _usersByNationality = {};

  // ── 2. 콘텐츠 지표 ────────────────────────────────────
  int _totalPosts = 0;
  int _infoPosts = 0;
  int _freePosts = 0;
  int _totalComments = 0;
  int _totalViews = 0;
  int _totalScraps = 0;
  List<Map<String, dynamic>> _topViewedPosts = [];

  // ── 3. 최근 가입자 ────────────────────────────────────
  List<Map<String, dynamic>> _recentUsers = [];

  // ── 4. 운영 지표 ──────────────────────────────────────
  int _totalChats = 0;
  int _pendingRecovery = 0;

  // ── 5. DAU / MAU / 리텐션 지표 ────────────────────────
  int _dau = 0;     // 오늘 로그인한 고유 사용자 수
  int _mau = 0;     // 이번 달 로그인한 고유 사용자 수
  double _retention3d = 0.0; // 3일 후 재방문율 (%)
  List<Map<String, dynamic>> _dauTrend = []; // 최근 7일 DAU 추이

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _loadUserMetrics(),
        _loadContentMetrics(),
        _loadRecentUsers(),
        _loadOperationMetrics(),
        _loadEngagementMetrics(),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics error: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── 1. 사용자 지표 ──────────────────────────────────
  Future<void> _loadUserMetrics() async {
    final snap = await _db.collection('users').get();
    final docs = snap.docs.map((d) => d.data()).toList();

    int approved = 0, pending = 0, blocked = 0, rejected = 0;
    final natCount = <String, int>{};

    for (final u in docs) {
      final status = u['status'] as String? ?? '';
      if (status == 'Approved') approved++;
      else if (status == 'Pending') pending++;
      else if (status == 'Blocked') blocked++;
      else if (status == 'Rejected') rejected++;

      // 국적별 집계
      final nat = u['nationality'] as String? ?? 'Unknown';
      natCount[nat] = (natCount[nat] ?? 0) + 1;
    }

    // 상위 5개 국적만
    final sortedNat = Map.fromEntries(
      natCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
    final topNat = Map.fromEntries(sortedNat.entries.take(6));

    if (mounted) {
      setState(() {
        _totalUsers = docs.length;
        _approvedUsers = approved;
        _pendingUsers = pending;
        _blockedUsers = blocked;
        _rejectedUsers = rejected;
        _usersByNationality = topNat;
      });
    }
  }

  // ── 2. 콘텐츠 지표 ────────────────────────────────────
  Future<void> _loadContentMetrics() async {
    final snap = await _db.collection('posts').get();
    final docs = snap.docs;

    int infoCount = 0, freeCount = 0;
    int totalViews = 0, totalComments = 0, totalScraps = 0;
    final allPosts = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data();
      final board = data['board_type'] as String? ?? '';
      if (board == 'info') infoCount++;
      else if (board == 'free') freeCount++;

      final views = data['view_count'] as int? ?? 0;
      final comments = data['comment_count'] as int? ?? 0;
      final scraps = data['save_count'] as int? ?? 0;
      totalViews += views;
      totalComments += comments;
      totalScraps += scraps;

      allPosts.add({
        'id': doc.id,
        'title': data['title'] ?? '',
        'board_type': board,
        'view_count': views,
        'comment_count': comments,
        'author_name': data['author_name'] ?? '',
      });
    }

    // 조회수 TOP 5
    allPosts.sort((a, b) =>
        (b['view_count'] as int).compareTo(a['view_count'] as int));
    final top5 = allPosts.take(5).toList();

    if (mounted) {
      setState(() {
        _totalPosts = docs.length;
        _infoPosts = infoCount;
        _freePosts = freeCount;
        _totalViews = totalViews;
        _totalComments = totalComments;
        _totalScraps = totalScraps;
        _topViewedPosts = top5;
      });
    }
  }

  // ── 3. 최근 가입자 ────────────────────────────────────
  Future<void> _loadRecentUsers() async {
    final snap = await _db
        .collection('users')
        .orderBy('created_at', descending: true)
        .limit(5)
        .get();

    final users = snap.docs.map((d) {
      final data = d.data();
      DateTime? createdAt;
      try {
        createdAt = (data['created_at'] as Timestamp?)?.toDate();
      } catch (_) {}
      return {
        'name': data['nickname'] ?? data['name'] ?? '(이름 없음)',
        'nationality': data['nationality'] ?? '-',
        'status': data['status'] ?? 'Pending',
        'created_at': createdAt,
      };
    }).toList();

    if (mounted) setState(() => _recentUsers = users);
  }

  // ── 4. 운영 지표 ──────────────────────────────────────
  Future<void> _loadOperationMetrics() async {
    // 채팅방 수
    final chatSnap = await _db.collection('chats').get();

    // 미처리 복구 요청
    final recoverySnap = await _db
        .collection('recovery_requests')
        .where('status', isEqualTo: 'Pending')
        .get();

    if (mounted) {
      setState(() {
        _totalChats = chatSnap.docs.length;
        _pendingRecovery = recoverySnap.docs.length;
      });
    }
  }

  // ── 5. DAU / MAU / 3일 리텐션 ──────────────────────────
  Future<void> _loadEngagementMetrics() async {
    // users 컬렉션에서 last_login_at 필드 기반으로 DAU/MAU 계산
    // 없는 경우 created_at 기반으로 fallback
    final snap = await _db.collection('users').get();
    final docs = snap.docs.map((d) => d.data()).toList();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    // DAU: 오늘 로그인 사용자
    int dau = 0;
    // MAU: 이번 달 로그인 사용자
    int mau = 0;

    // 3일 리텐션: 3-10일 전 가입자 중 이후에도 로그인한 비율
    int cohortSize = 0;
    int retained = 0;

    // 최근 7일 DAU 추이
    final dauByDay = <String, Set<String>>{};
    for (int i = 6; i >= 0; i--) {
      final d = todayStart.subtract(Duration(days: i));
      dauByDay['${d.month}/${d.day}'] = {};
    }

    for (final u in docs) {
      final uid = u['user_id'] as String? ?? u['email'] as String? ?? '';
      if (uid.isEmpty) continue;

      // last_login_at 또는 created_at 사용
      DateTime? lastLogin;
      final rawLogin = u['last_login_at'] ?? u['created_at'];
      if (rawLogin != null) {
        try {
          if (rawLogin.runtimeType.toString().contains('Timestamp')) {
            lastLogin = (rawLogin as Timestamp).toDate();
          } else if (rawLogin is String) {
            lastLogin = DateTime.tryParse(rawLogin);
          }
        } catch (_) {}
      }

      if (lastLogin == null) continue;

      // DAU 계산
      if (!lastLogin.isBefore(todayStart)) dau++;

      // MAU 계산
      if (!lastLogin.isBefore(monthStart)) mau++;

      // 최근 7일 DAU 추이
      for (int i = 6; i >= 0; i--) {
        final dayStart = todayStart.subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        if (!lastLogin.isBefore(dayStart) && lastLogin.isBefore(dayEnd)) {
          final key = '${dayStart.month}/${dayStart.day}';
          dauByDay[key]?.add(uid);
        }
      }

      // 3일 리텐션: 가입일로부터 3-10일 전 코호트
      DateTime? createdAt;
      final rawCreated = u['created_at'];
      if (rawCreated != null) {
        try {
          if (rawCreated.runtimeType.toString().contains('Timestamp')) {
            createdAt = (rawCreated as Timestamp).toDate();
          } else if (rawCreated is String) {
            createdAt = DateTime.tryParse(rawCreated);
          }
        } catch (_) {}
      }

      if (createdAt != null) {
        final daysSinceSignup = now.difference(createdAt).inDays;
        if (daysSinceSignup >= 3 && daysSinceSignup <= 30) {
          cohortSize++;
          // 가입 후 3일 이후에도 로그인했다면 retention으로 카운트
          final signupDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
          final returnDate = signupDate.add(const Duration(days: 3));
          if (!lastLogin.isBefore(returnDate)) {
            retained++;
          }
        }
      }
    }

    final retention = cohortSize > 0 ? (retained / cohortSize * 100) : 0.0;

    final trendList = dauByDay.entries
        .map((e) => {'label': e.key, 'count': e.value.length})
        .toList();

    if (mounted) {
      setState(() {
        _dau = dau;
        _mau = mau;
        _retention3d = retention;
        _dauTrend = trendList;
      });
    }
  }

  // ─────────────────────────────────────────────────────
  // BUILD
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
          : _error.isNotEmpty
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ① 사용자 현황
                        _buildSectionHeader(
                            '① 사용자 현황', Icons.people_alt, const Color(0xFF0038A8)),
                        const SizedBox(height: 12),
                        _buildUserSection(),
                        const SizedBox(height: 24),

                        // ② 콘텐츠 현황
                        _buildSectionHeader(
                            '② 콘텐츠 현황', Icons.bar_chart, const Color(0xFF6B4EFF)),
                        const SizedBox(height: 12),
                        _buildContentSection(),
                        const SizedBox(height: 24),

                        // ③ 국적별 분포
                        _buildSectionHeader(
                            '③ 국적별 사용자 분포', Icons.public, const Color(0xFF00897B)),
                        const SizedBox(height: 12),
                        _buildNationalitySection(),
                        const SizedBox(height: 24),

                        // ④ 최근 가입자
                        _buildSectionHeader(
                            '④ 최근 가입자', Icons.person_add, Colors.orange[700]!),
                        const SizedBox(height: 12),
                        _buildRecentUsersSection(),
                        const SizedBox(height: 24),

                        // ⑤ 조회수 TOP 5
                        _buildSectionHeader(
                            '⑤ 조회수 TOP 5', Icons.trending_up, Colors.red[600]!),
                        const SizedBox(height: 12),
                        _buildTopPostsSection(),
                        const SizedBox(height: 24),

                        // ⑥ 운영 현황
                        _buildSectionHeader(
                            '⑥ 운영 현황', Icons.admin_panel_settings, Colors.purple[600]!),
                        const SizedBox(height: 12),
                        _buildOperationSection(),
                        const SizedBox(height: 24),

                        // ⑦ 참여 지표 (DAU / MAU / 리텐션)
                        _buildSectionHeader(
                            '⑦ 참여 지표 (DAU · MAU · 리텐션)',
                            Icons.show_chart,
                            Colors.teal[700]!),
                        const SizedBox(height: 12),
                        _buildEngagementSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 섹션 위젯들
  // ─────────────────────────────────────────────────────

  Widget _buildUserSection() {
    return Column(
      children: [
        // 전체 / 승인 / 대기 / 차단 / 거절
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile('전체\n가입자', '$_totalUsers명',
                  color: const Color(0xFF0038A8), icon: Icons.group),
              _vDivider(),
              _statTile('승인\n완료', '$_approvedUsers명',
                  color: Colors.green[600]!, icon: Icons.check_circle),
              _vDivider(),
              _statTile('승인\n대기', '$_pendingUsers명',
                  color: Colors.orange[600]!, icon: Icons.hourglass_top),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile('차단\n유저', '$_blockedUsers명',
                  color: Colors.red[600]!, icon: Icons.block),
              _vDivider(),
              _statTile('가입\n거절', '$_rejectedUsers명',
                  color: Colors.grey[600]!, icon: Icons.person_off),
              _vDivider(),
              _statTile('승인률',
                  _totalUsers > 0
                      ? '${(_approvedUsers / _totalUsers * 100).toStringAsFixed(1)}%'
                      : '-',
                  color: const Color(0xFF6B4EFF), icon: Icons.pie_chart),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      children: [
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile('전체\n게시글', '$_totalPosts건',
                  color: const Color(0xFF6B4EFF), icon: Icons.article),
              _vDivider(),
              _statTile('정보\n게시판', '$_infoPosts건',
                  color: const Color(0xFF0038A8), icon: Icons.info),
              _vDivider(),
              _statTile('자유\n게시판', '$_freePosts건',
                  color: Colors.green[600]!, icon: Icons.edit_note),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile('총 댓글 수', '$_totalComments건',
                  color: const Color(0xFF00897B), icon: Icons.comment),
              _vDivider(),
              _statTile('총 조회수', '$_totalViews회',
                  color: Colors.orange[700]!, icon: Icons.visibility),
              _vDivider(),
              _statTile('총 스크랩', '$_totalScraps건',
                  color: Colors.red[400]!, icon: Icons.bookmark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNationalitySection() {
    if (_usersByNationality.isEmpty) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('국적 데이터 없음', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    final total = _usersByNationality.values.fold(0, (a, b) => a + b);
    final colors = [
      const Color(0xFF0038A8),
      const Color(0xFF6B4EFF),
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.red[400]!,
      Colors.purple[400]!,
    ];

    return _buildCard(
      child: Column(
        children: _usersByNationality.entries.toList().asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = colors[idx % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                        '${entry.value}명 (${(pct * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color)),
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
        }).toList(),
      ),
    );
  }

  Widget _buildRecentUsersSection() {
    if (_recentUsers.isEmpty) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('가입자 없음', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return _buildCard(
      child: Column(
        children: _recentUsers.map((u) {
          final status = u['status'] as String;
          final statusColor = status == 'Approved'
              ? Colors.green[600]!
              : status == 'Pending'
                  ? Colors.orange[600]!
                  : Colors.red[400]!;
          final statusLabel = status == 'Approved'
              ? '승인'
              : status == 'Pending'
                  ? '대기'
                  : status == 'Blocked'
                      ? '차단'
                      : '거절';

          final dt = u['created_at'] as DateTime?;
          final dateStr = dt != null
              ? '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}'
              : '-';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0038A8).withValues(alpha: 0.1),
                  child: const Icon(Icons.person, size: 18,
                      color: Color(0xFF0038A8)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u['name'] as String,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${u['nationality']}  ·  $dateStr',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopPostsSection() {
    if (_topViewedPosts.isEmpty) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('게시글 없음', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return _buildCard(
      child: Column(
        children: _topViewedPosts.asMap().entries.map((e) {
          final rank = e.key + 1;
          final post = e.value;
          final rankColors = [
            const Color(0xFFFFD700),
            const Color(0xFFC0C0C0),
            const Color(0xFFCD7F32),
            Colors.grey[400]!,
            Colors.grey[400]!,
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: rankColors[e.key],
                  child: Text('$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['title'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                          post['board_type'] == 'info' ? '정보게시판' : '자유게시판',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text('${post['view_count']}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0038A8))),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.comment, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text('${post['comment_count']}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOperationSection() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile('활성\n채팅방', '$_totalChats개',
                  color: Colors.purple[600]!, icon: Icons.chat_bubble),
              _vDivider(),
              _statTile('미처리\n복구 요청', '$_pendingRecovery건',
                  color: _pendingRecovery > 0 ? Colors.red[600]! : Colors.grey[600]!,
                  icon: Icons.lock_reset),
              _vDivider(),
              _statTile('게시글당\n평균 댓글',
                  _totalPosts > 0
                      ? '${(_totalComments / _totalPosts).toStringAsFixed(1)}건'
                      : '-',
                  color: const Color(0xFF00897B), icon: Icons.forum),
            ],
          ),
          if (_pendingRecovery > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '미처리 계정 복구 요청이 $_pendingRecovery건 있습니다. 회원 승인 관리에서 확인하세요.',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('데이터를 불러오지 못했습니다',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0038A8),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // 공통 헬퍼
  // ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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

  Widget _statTile(String label, String value,
      {required Color color, IconData? icon}) {
    return Column(
      children: [
        if (icon != null) Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _vDivider() =>
      Container(height: 50, width: 1, color: Colors.grey[200]);

  // ── ⑦ 참여 지표 섹션 ────────────────────────────────────
  Widget _buildEngagementSection() {
    final maxDau = _dauTrend.isEmpty
        ? 1
        : _dauTrend
            .map((e) => e['count'] as int)
            .reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // DAU / MAU / 리텐션 핵심 수치
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile('DAU\n오늘 활성',
                  '$_dau명',
                  color: Colors.teal[700]!,
                  icon: Icons.today),
              _vDivider(),
              _statTile('MAU\n월간 활성',
                  '$_mau명',
                  color: Colors.blue[700]!,
                  icon: Icons.calendar_month),
              _vDivider(),
              _statTile('3일\n리텐션',
                  '${_retention3d.toStringAsFixed(1)}%',
                  color: _retention3d >= 30
                      ? Colors.green[600]!
                      : _retention3d >= 10
                          ? Colors.orange[600]!
                          : Colors.red[600]!,
                  icon: Icons.repeat),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 리텐션 설명 카드
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    '지표 설명',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _infoRow('DAU', '오늘 1회 이상 로그인한 고유 사용자 수'),
              _infoRow('MAU', '이번 달 1회 이상 로그인한 고유 사용자 수'),
              _infoRow('3일 리텐션',
                  '가입 후 3일 뒤에도 재방문한 사용자 비율 (가입 3~30일 코호트 기준)'),
              _infoRow('DAU/MAU 비율',
                  _mau > 0
                      ? '${(_dau / _mau * 100).toStringAsFixed(1)}% (앱 충성도 지표)'
                      : '-'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 최근 7일 DAU 막대그래프
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '최근 7일 DAU 추이',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              if (_dauTrend.isEmpty)
                Center(
                  child: Text('데이터 없음',
                      style: TextStyle(color: Colors.grey[400])),
                )
              else
                SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _dauTrend.map((entry) {
                      final count = entry['count'] as int;
                      final ratio =
                          maxDau > 0 ? count / maxDau : 0.0;
                      final barH = ratio * 60 + 4;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$count',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Container(
                            width: 28,
                            height: barH,
                            decoration: BoxDecoration(
                              color: Colors.teal[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry['label'] as String,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal[700]),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
