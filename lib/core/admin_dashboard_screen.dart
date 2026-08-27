import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_repository.dart';
import 'admin_location_manager_screen.dart';

/// Admin dashboard featuring analytics, member management,
/// user activation/deactivation, dropdown field data feeder, and database explorer.
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
  int _localAuthoritiesCount = 0;

  // ---------------------------------------------------------------------------
  // Database Explorer / Pagination State
  // ---------------------------------------------------------------------------
  static const _pageSize = 10;
  final Map<String, String> _collectionMap = {
    'survey_responses': 'Collected Data',
    'users': 'Our Members (Users)',
    'voters_2024': 'Members in Our System',
    'local_authorities': 'Administrative Locations (Dropdown Data)',
  };

  String _currentCollectionId = 'users';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchField = 'name';
  String _userStatusFilter = 'all'; // 'all', 'active', 'deactivated'

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
  // Data Loading & Status Toggle Methods
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
          sGalle++;
        } else if (district.contains('hambantota')) {
          vHambantota++;
        }
      }

      // 3. User Members stats
      final usersSnap = await firestore.collection('users').get();
      int active = 0, inactive = 0;
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final isActive = data['isActive'] == true || data['status'] == 'active' || data['active'] == true;
        if (isActive) {
          active++;
        } else {
          inactive++;
        }
      }

      // 4. Local Authorities stats
      final laSnap = await firestore.collection('local_authorities').get();

      if (mounted) {
        setState(() {
          _surveyCount = surveySnap.size;
          _surveyDistricts = {'Matara': sMatara, 'Galle': sGalle, 'Hambantota': sHambantota};
          _votersCount = votersSnap.size;
          _votersDistricts = {'Matara': vMatara, 'Galle': vGalle, 'Hambantota': vHambantota};
          _membersActive = active;
          _membersDeactivated = inactive;
          _localAuthoritiesCount = laSnap.size;
        });
      }
    } catch (_) {
      // Fallback/graceful defaults
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  /// Toggles isActive status for a user directly in Firestore
  Future<void> _toggleUserActiveStatus(String docId, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': newStatus,
        'status': newStatus ? 'active' : 'deactivated',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newStatus ? const Color(0xFF10B981) : const Color(0xFFE11D48),
            content: Text(
              newStatus ? 'User activated successfully' : 'User deactivated successfully',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _fetchDashboardStatistics();
      _loadExplorerPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to update status: $e'),
          ),
        );
      }
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

      // Apply User Status filter if in users collection
      if (_currentCollectionId == 'users' && _userStatusFilter != 'all') {
        final bool requiredActive = _userStatusFilter == 'active';
        query = query.where('isActive', isEqualTo: requiredActive);
      }

      // Apply Search Filter
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
      } else if (_currentCollectionId != 'users' || _userStatusFilter == 'all') {
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
      _searchField = newCollectionId == 'users' ? 'name' : 'documentId';
      _userStatusFilter = 'all';
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
        return ['name', 'email', 'phone', 'nic', 'town', 'district', 'documentId'];
      case 'voters_2024':
        return ['documentId', 'name', 'nic', 'houseNumber'];
      case 'local_authorities':
        return ['documentId', 'name_en', 'name_si', 'district_en'];
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
            child: _currentNavIndex == 0
                ? _buildDashboardOverview()
                : (_currentNavIndex == 1
                    ? _buildDatabaseExplorer()
                    : _buildSettingsView()),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Modern header with greeting and sign-out
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
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 28, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                      'System Administration',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
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
  // Tab 1: Dashboard Overview
  // ---------------------------------------------------------------------------

  Widget _buildDashboardOverview() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchDashboardStatistics();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),

          // Action Card: Feed / Manage Signup Dropdown Field Data
          _buildDropdownDataManagementCard(),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_rounded, size: 22, color: Color(0xFF2C3E50)),
                  SizedBox(width: 8),
                  Text(
                    'Registered Members & Users',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentCollectionId = 'users';
                    _currentNavIndex = 1;
                  });
                  _loadExplorerPage();
                },
                icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                label: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRecentUsersFeed(),
        ],
      ),
    );
  }

  /// Banner Card to navigate to Location Manager & DB Feeder
  Widget _buildDropdownDataManagementCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.4)),
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              color: Color(0xFF60A5FA),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Signup Dropdown Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Feed and manage Local Authorities & GN Divisions in Firestore (${_localAuthoritiesCount} loaded)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminLocationManagerScreen(),
                ),
              );
              _fetchDashboardStatistics();
            },
            child: const Text(
              'Feed / Manage',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDistrictStatCard(
                title: 'Collected Data',
                totalCount: _surveyCount,
                districts: _surveyDistricts,
                cardColor: Colors.white,
                accentColor: const Color(0xFF2187EA),
                icon: Icons.assignment_outlined,
              ),
            ),
            const SizedBox(width: 12),
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
        _buildDistrictStatCard(
          title: 'Members in Our system',
          totalCount: _votersCount,
          districts: _votersDistricts,
          cardColor: Colors.white,
          accentColor: const Color(0xFF8B5CF6),
          icon: Icons.how_to_vote_outlined,
        ),
      ],
    );
  }

  Widget _buildDistrictStatCard({
    required String title,
    required int totalCount,
    required Map<String, int> districts,
    required Color cardColor,
    required Color accentColor,
    required IconData icon,
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
          }),
        ],
      ),
    );
  }

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

  Widget _buildRecentUsersFeed() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').limit(6).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF2187EA)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No registered users found.',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) => _buildUserListCard(doc)).toList(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Database Explorer & User Management
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

        // Status Filter Chips (For Users Collection)
        if (_currentCollectionId == 'users')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
            child: Row(
              children: [
                _buildFilterChip(label: 'All Users', value: 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Active', value: 'active', color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Deactivated', value: 'deactivated', color: const Color(0xFFF43F5E)),
              ],
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

        // Records List
        Expanded(child: _buildExplorerRecordsList()),

        // Pagination Bar
        _buildPagination(),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required String value, Color? color}) {
    final isSelected = _userStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _userStatusFilter = value;
            _pageStarts.clear();
          });
          _loadExplorerPage();
        }
      },
      selectedColor: (color ?? const Color(0xFF2187EA)).withOpacity(0.18),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? (color ?? const Color(0xFF2187EA)) : const Color(0xFF64748B),
      ),
      side: BorderSide(
        color: isSelected ? (color ?? const Color(0xFF2187EA)) : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildExplorerRecordsList() {
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

    if (_currentCollectionId == 'users') {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        itemCount: _documents.length,
        itemBuilder: (context, index) => _buildUserListCard(_documents[index]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      itemCount: _documents.length,
      itemBuilder: (context, index) => _buildGenericDocumentCard(_documents[index]),
    );
  }

  Widget _buildUserListCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final name = (data['name'] ?? data['fullName'] ?? 'Unnamed User').toString();
    final email = (data['email'] ?? 'No email').toString();
    final phone = (data['phone'] ?? '').toString();
    final district = (data['district'] ?? '').toString();
    final town = (data['town'] ?? '').toString();
    final role = (data['role'] ?? 'Member').toString();
    final isActive = data['isActive'] == true || data['status'] == 'active' || data['active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? Colors.transparent : const Color(0xFFFECDD3),
          width: isActive ? 0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: isActive ? const Color(0xFFE0F2FE) : const Color(0xFFFFE4E6),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: isActive ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
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
                              name,
                              style: const TextStyle(
                                fontSize: 16,
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
                              color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                              ),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'DEACTIVATED',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isActive ? const Color(0xFF065F46) : const Color(0xFF9F1239),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          'Phone: $phone',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (role.isNotEmpty)
                            _buildInfoPill(role.toUpperCase(), const Color(0xFF8B5CF6)),
                          if (district.isNotEmpty || town.isNotEmpty)
                            _buildInfoPill(
                              '${town.isNotEmpty ? '$town, ' : ''}$district',
                              const Color(0xFF0284C7),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: [
                    Switch.adaptive(
                      value: isActive,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => _toggleUserActiveStatus(document.id, isActive),
                    ),
                    Text(
                      isActive ? 'Active' : 'Disabled',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF065F46) : const Color(0xFF9F1239),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2187EA)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminDocumentScreen(
                          collection: 'users',
                          documentId: document.id,
                        ),
                      ),
                    );
                    _fetchDashboardStatistics();
                    _loadExplorerPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF2187EA)),
                  label: const Text(
                    'Edit Details',
                    style: TextStyle(color: Color(0xFF2187EA), fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildGenericDocumentCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final title = (data['fullName'] ?? data['name'] ?? data['name_en'] ?? data['houseNumber'] ?? document.id).toString();
    final sub = (data['nic'] ?? data['district'] ?? data['district_en'] ?? document.id).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description_outlined, color: Color(0xFF0284C7)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF1E293B)),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE3F2FD),
            foregroundColor: const Color(0xFF1E88E5),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminDocumentScreen(
                  collection: _currentCollectionId,
                  documentId: document.id,
                ),
              ),
            );
            _fetchDashboardStatistics();
            _loadExplorerPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
          },
          child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ---------------------------------------------------------------------------
  // Tab 3: Settings & Tools
  // ---------------------------------------------------------------------------

  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Administrative Data Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alt_route_rounded, color: Color(0xFF0284C7)),
                ),
                title: const Text(
                  'Manage Dropdown Field Data',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Feed and configure Local Authorities & GN Divisions for signup',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminLocationManagerScreen(),
                    ),
                  );
                  _fetchDashboardStatistics();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account & Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFE11D48)),
                ),
                subtitle: const Text(
                  'End admin session securely',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => context.read<AuthRepository>().signOut(),
              ),
            ],
          ),
        ),
      ],
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
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Members / Explorer'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings & Tools'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Document & User Profile Editor Screen
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  String _selectedDistrict = 'Galle';
  String _selectedRole = 'data collector';
  bool _isActive = true;

  final List<String> _districtsList = ['Galle', 'Matara', 'Hambantota', 'Colombo', 'Kalutara', 'Other'];
  final List<String> _rolesList = ['data collector', 'admin', 'supervisor', 'surveyor', 'member'];

  @override
  void initState() {
    super.initState();
    _reference = FirebaseFirestore.instance.collection(widget.collection).doc(widget.documentId);
    _loadDocument();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _townController.dispose();
    super.dispose();
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
      final data = snapshot.data()!;
      if (mounted) {
        setState(() {
          _draft = _copyMap(data);

          if (widget.collection == 'users') {
            _nameController.text = (data['name'] ?? data['fullName'] ?? '').toString();
            _emailController.text = (data['email'] ?? '').toString();
            _phoneController.text = (data['phone'] ?? '').toString();
            _nicController.text = (data['nic'] ?? '').toString();
            _townController.text = (data['town'] ?? '').toString();

            final dist = (data['district'] ?? '').toString();
            if (_districtsList.contains(dist)) {
              _selectedDistrict = dist;
            }

            final role = (data['role'] ?? '').toString();
            if (_rolesList.contains(role)) {
              _selectedRole = role;
            }

            _isActive = data['isActive'] == true || data['status'] == 'active' || data['active'] == true;
          }
        });
      }
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
      if (widget.collection == 'users') {
        _draft!['name'] = _nameController.text.trim();
        _draft!['email'] = _emailController.text.trim();
        _draft!['phone'] = _phoneController.text.trim();
        _draft!['nic'] = _nicController.text.trim();
        _draft!['town'] = _townController.text.trim();
        _draft!['district'] = _selectedDistrict;
        _draft!['role'] = _selectedRole;
        _draft!['isActive'] = _isActive;
        _draft!['status'] = _isActive ? 'active' : 'deactivated';
      }

      await _reference.set(_draft!, SetOptions(merge: true));
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
        content: const Text('This permanently removes this record from Firestore.'),
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
          const SnackBar(content: Text('Record deleted successfully.')),
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
          title: Text(
            widget.collection == 'users' ? 'Edit User Profile' : 'Edit Record',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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

    if (widget.collection == 'users') {
      return _buildDedicatedUserEditor();
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

  Widget _buildDedicatedUserEditor() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isActive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isActive ? 'User is Active' : 'User is Deactivated',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _isActive ? const Color(0xFF065F46) : const Color(0xFF9F1239),
                        ),
                      ),
                      Text(
                        _isActive ? 'User can log in and perform surveys' : 'User account is disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isActive ? const Color(0xFF047857) : const Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isActive,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal & Contact Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              _buildTextInput(controller: _nameController, label: 'Full Name', icon: Icons.person_outline),
              const SizedBox(height: 14),
              _buildTextInput(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildTextInput(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _buildTextInput(controller: _nicController, label: 'NIC Number', icon: Icons.badge_outlined),
              const SizedBox(height: 14),
              _buildTextInput(controller: _townController, label: 'Town / City', icon: Icons.location_city_outlined),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _districtsList.contains(_selectedDistrict) ? _selectedDistrict : _districtsList.first,
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF1E88E5)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                items: _districtsList.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() => _selectedDistrict = val ?? 'Galle'),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _rolesList.contains(_selectedRole) ? _selectedRole : _rolesList.first,
                decoration: InputDecoration(
                  labelText: 'Assigned Role',
                  prefixIcon: const Icon(Icons.security_outlined, color: Color(0xFF1E88E5)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                items: _rolesList.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => _selectedRole = val ?? 'data collector'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        SelectableText(
          'Document UID: ${widget.documentId}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.8),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Generic Dynamic Field Value Editor
// -----------------------------------------------------------------------------

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