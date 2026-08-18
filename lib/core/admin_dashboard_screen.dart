import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_repository.dart';
import 'app_theme.dart';

/// Admin dashboard featuring an analytics summary, regional breakdown, 
/// recent activity feed, and a complete database record explorer.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentNavIndex = 0;

  // ---------------------------------------------------------------------------
  // Statistics State
  // ---------------------------------------------------------------------------
  bool _isLoadingStats = true;
  int _surveyCount = 0;
  Map<String, int> _surveyDistricts = {'Matara': 0, 'Galle': 0, 'Hambantota': 0};

  int _votersCount = 0;
  Map<String, int> _votersDistricts = {'Matara': 0, 'Galle': 0, 'Hambantota': 0};

  int _membersActive = 0;
  int _membersDeactivated = 0;

  // ---------------------------------------------------------------------------
  // Database Explorer / Pagination State
  // ---------------------------------------------------------------------------
  static const _pageSize = 10;
  final Map<String, String> _collectionMap = {
    'survey_responses': 'Collected Data',
    'users': 'Our Members',
    'voters_2024': 'Members in Our System',
  };

  String _currentCollectionId = 'survey_responses';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchField = 'documentId';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _documents = [];
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pageStarts = [];

  bool _isLoadingRecords = true;
  bool _hasNextPage = false;
  String? _recordsError;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStatistics();
    _loadExplorerPage();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data Loading Methods
  // ---------------------------------------------------------------------------

  /// Aggregates counts and regional statistics from Firestore collections
  Future<void> _fetchDashboardStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Survey Responses stats
      final surveySnap = await firestore.collection('survey_responses').get();
      int sMatara = 0, sGalle = 0, sHambantota = 0;
      for (final doc in surveySnap.docs) {
        final data = doc.data();
        final district = (data['district'] ?? data['city'] ?? '').toString().toLowerCase();
        if (district.contains('matara')) {
          sMatara++;
        } else if (district.contains('galle')) {
          sGalle++;
        } else if (district.contains('hambantota')) {
          sHambantota++;
        }
      }

      // 2. Voters 2024 stats
      final votersSnap = await firestore.collection('voters_2024').get();
      int vMatara = 0, vGalle = 0, vHambantota = 0;
      for (final doc in votersSnap.docs) {
        final data = doc.data();
        final district = (data['district'] ?? data['city'] ?? '').toString().toLowerCase();
        if (district.contains('matara')) {
          vMatara++;
        } else if (district.contains('galle')) {
          vGalle++;
        } else if (district.contains('hambantota')) {
          vHambantota++;
        }
      }

      // 3. User Members stats
      final usersSnap = await firestore.collection('users').get();
      int active = 0, inactive = 0;
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? (data['status'] == 'active' || data['active'] == true);
        if (isActive == true) {
          active++;
        } else {
          inactive++;
        }
      }

      if (mounted) {
        setState(() {
          _surveyCount = surveySnap.size;
          _surveyDistricts = {
            'Matara': sMatara,
            'Galle': sGalle,
            'Hambantota': sHambantota,
          };

          _votersCount = votersSnap.size;
          _votersDistricts = {
            'Matara': vMatara,
            'Galle': vGalle,
            'Hambantota': vHambantota,
          };

          _membersActive = active;
          _membersDeactivated = inactive;
        });
      }
    } catch (_) {
      // Fallback/graceful defaults if some collections are empty or missing fields
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  /// Fetches paginated records for the Explorer view
  Future<void> _loadExplorerPage({QueryDocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    setState(() {
      _isLoadingRecords = true;
      _recordsError = null;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(_currentCollectionId);

      if (_searchQuery.isNotEmpty) {
        if (_searchField == 'documentId') {
          query = query
              .where(FieldPath.documentId, isGreaterThanOrEqualTo: _searchQuery)
              .where(FieldPath.documentId, isLessThanOrEqualTo: '$_searchQuery\uf8ff');
        } else {
          query = query
              .where(_searchField, isGreaterThanOrEqualTo: _searchQuery)
              .where(_searchField, isLessThanOrEqualTo: '$_searchQuery\uf8ff');
        }
      } else {
        query = query.orderBy(FieldPath.documentId);
      }

      query = query.limit(_pageSize + 1);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      if (!mounted) return;

      setState(() {
        _hasNextPage = snapshot.docs.length > _pageSize;
        _documents = snapshot.docs.take(_pageSize).toList();
      });
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _recordsError = e.message ?? e.code);
    } catch (e) {
      if (mounted) setState(() => _recordsError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingRecords = false);
    }
  }

  void _executeSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _pageStarts.clear();
    });
    _loadExplorerPage();
  }

  void _changeCollection(String newCollectionId) {
    if (newCollectionId == _currentCollectionId) return;
    setState(() {
      _currentCollectionId = newCollectionId;
      _pageStarts.clear();
      _searchController.clear();
      _searchQuery = '';
      _searchField = 'documentId';
    });
    _loadExplorerPage();
  }

  Future<void> _nextPage() async {
    if (!_hasNextPage || _documents.isEmpty) return;
    final start = _documents.last;
    _pageStarts.add(start);
    await _loadExplorerPage(startAfter: start);
  }

  Future<void> _previousPage() async {
    if (_pageStarts.isEmpty) return;
    _pageStarts.removeLast();
    await _loadExplorerPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
  }

  List<String> _getSearchFields() {
    switch (_currentCollectionId) {
      case 'survey_responses':
        return ['documentId', 'houseNumber', 'nic', 'fullName'];
      case 'users':
        return ['documentId', 'name', 'email', 'nic'];
      case 'voters_2024':
        return ['documentId', 'name', 'nic', 'houseNumber'];
      default:
        return ['documentId'];
    }
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _currentNavIndex == 0 ? _buildDashboardOverview() : _buildDatabaseExplorer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Modern header with greeting, role, and sign-out
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x331565C0),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, Vihanga Manodhya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded, size: 14, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      'System Administrator',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.18),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => context.read<AuthRepository>().signOut(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Dashboard Overview (As in the Sketch)
  // ---------------------------------------------------------------------------

  Widget _buildDashboardOverview() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchDashboardStatistics();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          // Section 1: Summary Cards Grid
          _buildSummaryCards(),

          const SizedBox(height: 24),

          // Section 2: "Recently added or edited" Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 22, color: Color(0xFF2C3E50)),
                  SizedBox(width: 8),
                  Text(
                    'Recently added or edited',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => setState(() => _currentNavIndex = 1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Section 3: Recent Records / Home Details Feed
          _buildRecentRecordsFeed(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card 1: Collected Data
                Expanded(
                  child: _buildDistrictStatCard(
                    title: 'Collected Data',
                    totalCount: _surveyCount,
                    districts: _surveyDistricts,
                    cardColor: const Color(0xFFFFFFFF),
                    accentColor: const Color(0xFF2187EA),
                    icon: Icons.assignment_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                // Card 2: Our Members
                Expanded(
                  child: _buildMembersStatCard(
                    title: 'Our Members',
                    active: _membersActive,
                    deactivated: _membersDeactivated,
                    accentColor: const Color(0xFF10B981),
                    icon: Icons.people_alt_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Card 3: Members in Our system
            _buildDistrictStatCard(
              title: 'Members in Our system',
              totalCount: _votersCount,
              districts: _votersDistricts,
              cardColor: const Color(0xFFFFFFFF),
              accentColor: const Color(0xFF8B5CF6),
              icon: Icons.how_to_vote_outlined,
              isFullWidth: true,
            ),
          ],
        );
      },
    );
  }

  /// Metric Card for Collected Data & Voters with district counts
  Widget _buildDistrictStatCard({
    required String title,
    required int totalCount,
    required Map<String, int> districts,
    required Color cardColor,
    required Color accentColor,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'count : $totalCount records',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),
          ...districts.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Metric Card for Our Members (Active vs Deactivate)
  Widget _buildMembersStatCard({
    required String title,
    required int active,
    required int deactivated,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Active Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text(
                      'active',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
                Text(
                  ': $active',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Deactivate Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFFF43F5E)),
                    SizedBox(width: 6),
                    Text(
                      'deactivate',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                  ],
                ),
                Text(
                  ': $deactivated',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9F1239),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Recent activity list displaying home and record details
  Widget _buildRecentRecordsFeed() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('survey_responses')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF2187EA)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              children: [
                Icon(Icons.home_work_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No recent home details yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Newly added or modified survey responses will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) => _buildRecentHomeItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildRecentHomeItem(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final houseNumber = data['houseNumber']?.toString() ?? 'No House #';
    final name = data['fullName'] ?? data['name'] ?? data['ownerName'] ?? 'Unnamed Resident';
    final nic = data['nic']?.toString() ?? 'No NIC';
    final district = data['district'] ?? data['city'] ?? 'Southern Province';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminDocumentScreen(
                  collection: 'survey_responses',
                  documentId: document.id,
                ),
              ),
            );
            _fetchDashboardStatistics();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.home_rounded, color: Color(0xFF0284C7), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'House: $houseNumber',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              district.toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$name • NIC: $nic',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${document.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Database Explorer (Search, Collection Dropdown & Full Pagination)
  // ---------------------------------------------------------------------------

  Widget _buildDatabaseExplorer() {
    return Column(
      children: [
        // Dropdown Selector for Collections
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentCollectionId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2C3E50)),
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                items: _collectionMap.entries
                    .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                    .toList(),
                onChanged: _isLoadingRecords ? null : (newId) => newId != null ? _changeCollection(newId) : null,
              ),
            ),
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _searchField,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2187EA), size: 18),
                      style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 12),
                      items: _getSearchFields().map((field) {
                        String displayName = field == 'documentId' ? 'ID' : field.toUpperCase();
                        return DropdownMenuItem(value: field, child: Text(displayName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _searchField = val);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search ${_collectionMap[_currentCollectionId]}...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (_) => _executeSearch(),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                      _executeSearch();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Color(0xFF2187EA)),
                  onPressed: _executeSearch,
                ),
              ],
            ),
          ),
        ),

        // Grid View of Records
        Expanded(child: _buildExplorerGrid()),

        // Pagination Bar
        _buildPagination(),
      ],
    );
  }

  Widget _buildExplorerGrid() {
    if (_isLoadingRecords) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2187EA)));
    }

    if (_recordsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: Colors.redAccent),
              const SizedBox(height: 8),
              Text(_recordsError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadExplorerPage, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    if (_documents.isEmpty) {
      return const Center(
        child: Text('No records found.', style: TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: _documents.length,
          itemBuilder: (context, index) {
            final document = _documents[index];
            return _buildDocumentCard(document);
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final title = (data['fullName'] ?? data['name'] ?? data['houseNumber'] ?? document.id).toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminDocumentScreen(
                  collection: _currentCollectionId,
                  documentId: document.id,
                ),
              ),
            );
            if (mounted) _loadExplorerPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insert_drive_file_outlined, size: 34, color: Color(0xFF2187EA)),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  document.id,
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'View & Edit',
                    style: TextStyle(color: Color(0xFF2187EA), fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _isLoadingRecords || _pageStarts.isEmpty ? null : _previousPage,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                'Page ${_pageStarts.length + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
            ),
            IconButton(
              onPressed: _isLoadingRecords || !_hasNextPage ? null : _nextPage,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        selectedItemColor: const Color(0xFF2187EA),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.storage_rounded), label: 'Explorer'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Document Editor Screen
// -----------------------------------------------------------------------------

class AdminDocumentScreen extends StatefulWidget {
  const AdminDocumentScreen({
    required this.collection,
    required this.documentId,
    super.key,
  });

  final String collection;
  final String documentId;

  @override
  State<AdminDocumentScreen> createState() => _AdminDocumentScreenState();
}

class _AdminDocumentScreenState extends State<AdminDocumentScreen> {
  late final DocumentReference<Map<String, dynamic>> _reference;
  Map<String, dynamic>? _draft;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reference = FirebaseFirestore.instance.collection(widget.collection).doc(widget.documentId);
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('This document no longer exists.');
      }
      if (mounted) setState(() => _draft = _copyMap(snapshot.data()!));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_draft == null) return;
    setState(() => _isSaving = true);

    try {
      await _reference.set(_draft!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to save record.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text('This permanently removes the Firestore document.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isSaving = true);

    try {
      await _reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to delete record.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF3F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Edit Record', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: 'Delete record',
              onPressed: _isSaving || _isLoading ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _draft == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                  ),
                ),
              ),
      );

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2C3E50))),
        ),
      );
    }

    final draft = _draft!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Collection: ${widget.collection}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SelectableText('Document ID: ${widget.documentId}', style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 16)),
        const SizedBox(height: 20),
        ...draft.entries.map(
          (entry) => _ValueEditor(
            label: entry.key,
            value: entry.value,
            onChanged: (value) => draft[entry.key] = value,
          ),
        ),
      ],
    );
  }
}

class _ValueEditor extends StatelessWidget {
  const _ValueEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value as Map);
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ExpansionTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: map.entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ValueEditor(
                    label: entry.key,
                    value: entry.value,
                    onChanged: (newValue) {
                      map[entry.key] = newValue;
                      onChanged(map);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    if (value is List) {
      final list = List<dynamic>.from(value as List);
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ExpansionTile(
          title: Text('$label (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          children: List.generate(
            list.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _ValueEditor(
                label: '#${index + 1}',
                value: list[index],
                onChanged: (newValue) {
                  list[index] = newValue;
                  onChanged(list);
                },
              ),
            ),
          ),
        ),
      );
    }

    if (value is bool) {
      return SwitchListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: value as bool,
        activeColor: const Color(0xFF1E88E5),
        onChanged: onChanged,
      );
    }

    if (value is Timestamp) {
      return _textField(
        initialValue: (value as Timestamp).toDate().toIso8601String(),
        helper: 'Date/time (ISO 8601)',
        onChanged: (text) {
          final date = DateTime.tryParse(text);
          if (date != null) onChanged(Timestamp.fromDate(date));
        },
      );
    }

    if (value is DocumentReference || value is GeoPoint) {
      return ListTile(title: Text(label), subtitle: SelectableText('$value'));
    }

    return _textField(
      initialValue: value?.toString() ?? '',
      helper: value == null ? 'Empty value saves as null' : null,
      onChanged: (text) => onChanged(_parseValue(text, value)),
    );
  }

  Widget _textField({
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? helper,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          initialValue: initialValue,
          minLines: 1,
          maxLines: initialValue.length > 60 ? 4 : 1,
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E88E5)),
            ),
          ),
          onChanged: onChanged,
        ),
      );

  dynamic _parseValue(String text, dynamic originalValue) {
    if (text.isEmpty && originalValue == null) return null;
    if (originalValue is int) return int.tryParse(text) ?? originalValue;
    if (originalValue is double) return double.tryParse(text) ?? originalValue;
    return text;
  }
}

Map<String, dynamic> _copyMap(Map<String, dynamic> source) =>
    source.map((key, value) => MapEntry(key, _copyValue(value)));

dynamic _copyValue(dynamic value) {
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), _copyValue(item)));
  if (value is List) return value.map(_copyValue).toList();
  return value;
}