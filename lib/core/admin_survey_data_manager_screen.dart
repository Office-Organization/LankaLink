import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSurveyDataManagerScreen extends StatefulWidget {
  const AdminSurveyDataManagerScreen({super.key});

  @override
  State<AdminSurveyDataManagerScreen> createState() =>
      _AdminSurveyDataManagerScreenState();
}

class _AdminSurveyDataManagerScreenState
    extends State<AdminSurveyDataManagerScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;

  // Selected Survey Category
  String _selectedCollection = 'infrastructure_data';

  // Hierarchical Filter State (District -> Local Authority -> GN Division)
  String _selectedDistrict = 'All';
  String _selectedLocalAuthority = 'All';
  String _selectedGNDivision = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _categories = {
    'infrastructure_data': '🏗️ Infrastructure',
    'agriculture_data': '🌾 Agriculture',
    'daily_facilities_data': '🏢 Daily Facilities',
    'drainage_data': '💧 Drainage Systems',
    'tourist_attractions_data': '🏖️ Tourist Attractions',
    'proposals_data': '💡 Proposals',
    'disasters_data': '⚠️ Disasters & Risks',
  };

  final List<String> _districts = ['All', 'Matara', 'Galle', 'Hambantota'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Survey Data & Analytics Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.folder_shared_rounded, size: 20), text: 'Data Explorer'),
            Tab(icon: Icon(Icons.insights_rounded, size: 20), text: 'Analytics & Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordsExplorerTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: HIERARCHICAL RECORDS EXPLORER (District -> LA -> GN Division)
  // ===========================================================================

  Widget _buildRecordsExplorerTab() {
    return Column(
      children: [
        // Filter & Hierarchy Selection Panel
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selector Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.entries.map((entry) {
                    final isSelected = _selectedCollection == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCollection = entry.key);
                          }
                        },
                        selectedColor: const Color(0xFF1E88E5).withOpacity(0.15),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF475569),
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Hierarchical Filter Row (District -> Local Authority -> GN Division)
              Row(
                children: [
                  // 1. District Dropdown
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'District',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      items: _districts
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, style: const TextStyle(fontSize: 12.5))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDistrict = val;
                            _selectedLocalAuthority = 'All';
                            _selectedGNDivision = 'All';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Search Text input
                  Expanded(
                    flex: 6,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search GN, NIC, name...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E88E5), size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Live Grouped Stream List
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection(_selectedCollection)
                .orderBy('updated_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error loading data: ${snapshot.error}'));
              }

              final allDocs = snapshot.data?.docs ?? [];
              if (allDocs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No records found for ${_categories[_selectedCollection]}.',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filter by District & Search Query
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data();
                final docDistrict = (data['district'] ?? '').toString();
                final collectorNic = (data['collector_nic'] ?? '').toString().toLowerCase();
                final collectorName = (data['collector_name'] ?? '').toString().toLowerCase();
                final gn = (data['gn_division'] ?? '').toString().toLowerCase();
                final la = (data['local_authority'] ?? '').toString().toLowerCase();
                final fullDoc = '${data}'.toLowerCase();

                if (_selectedDistrict != 'All' &&
                    !docDistrict.toLowerCase().contains(_selectedDistrict.toLowerCase())) {
                  return false;
                }

                if (_searchQuery.isNotEmpty) {
                  return collectorNic.contains(_searchQuery) ||
                      collectorName.contains(_searchQuery) ||
                      gn.contains(_searchQuery) ||
                      la.contains(_searchQuery) ||
                      fullDoc.contains(_searchQuery);
                }

                return true;
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text('No records match your filters.',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                );
              }

              // Group Records Hierarchically: District -> Local Authority -> GN Division
              final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> groupedMap = {};
              for (final doc in filteredDocs) {
                final data = doc.data();
                final d = (data['district'] ?? 'Other District').toString();
                final la = (data['local_authority'] ?? 'Unspecified Authority').toString();
                final gn = (data['gn_division'] ?? 'Unspecified GN').toString();
                final groupKey = '$d > $la > $gn';

                if (!groupedMap.containsKey(groupKey)) {
                  groupedMap[groupKey] = [];
                }
                groupedMap[groupKey]!.add(doc);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedMap.length,
                itemBuilder: (context, index) {
                  final key = groupedMap.keys.elementAt(index);
                  final groupDocs = groupedMap[key]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      shape: const Border(),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      title: Text(
                        key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          '${groupDocs.length} Records',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      children: groupDocs
                          .map((doc) => _buildDetailReviewCard(doc.data(), doc.id))
                          .toList(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Displays an in-depth read-only review card for an entry
  Widget _buildDetailReviewCard(Map<String, dynamic> data, String docId) {
    final collectorName = (data['collector_name'] ?? 'Unknown Collector').toString();
    final collectorNic = (data['collector_nic'] ?? '').toString();
    final collectorPhone = (data['collector_phone'] ?? '').toString();
    final timeStr = (data['created_at_timestamp'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collector Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    '$collectorName (NIC: $collectorNic)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (collectorPhone.isNotEmpty)
                Text(
                  '📞 $collectorPhone',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Structured Module Content
          _buildStructuredContent(data),

          if (timeStr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Recorded: ${timeStr.split('T').first}',
                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStructuredContent(Map<String, dynamic> data) {
    switch (_selectedCollection) {
      case 'infrastructure_data':
        final road = (data['roads_infrastructure'] as Map?) ?? {};
        final bridge = (data['bridges_infrastructure'] as Map?) ?? {};
        final roadName = (road['road_name'] ?? '').toString();
        final bridgeName = (bridge['bridge_name'] ?? '').toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (roadName.isNotEmpty) ...[
              _buildRow('🛣️ Road Name', roadName),
              _buildRow('Type', '${road['road_type'] ?? '-'} • Distance: ${road['development_distance'] ?? '-'} km'),
              _buildRow('Beneficiaries', '${road['beneficiaries_count'] ?? '-'}'),
              const SizedBox(height: 4),
            ],
            if (bridgeName.isNotEmpty) ...[
              _buildRow('🌉 Bridge/Culvert', bridgeName),
              _buildRow('Type', '${bridge['bridge_type'] ?? '-'} • Condition: ${bridge['current_condition'] ?? '-'}'),
              _buildRow('Beneficiaries', '${bridge['beneficiaries_count'] ?? '-'}'),
            ],
          ],
        );

      case 'agriculture_data':
        final agri = (data['agriculture_infrastructure'] as Map?) ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Location', '${agri['location_name'] ?? '-'}'),
            _buildRow('Category & Type', '${agri['development_category'] ?? '-'} (${agri['development_type'] ?? '-'})'),
            _buildRow('Beneficiaries', '${agri['beneficiaries_count'] ?? '-'}'),
            if ((agri['map_coordinates'] ?? '').toString().isNotEmpty)
              _buildRow('📍 Coordinates', '${agri['map_coordinates']}'),
          ],
        );

      case 'daily_facilities_data':
        final fac = (data['daily_facilities'] as Map?) ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Facility', '${fac['facility_type'] ?? '-'}'),
            _buildRow('Govt Land Available', '${fac['has_government_land'] ?? '-'}'),
            _buildRow('Beneficiaries', '${fac['beneficiaries_count'] ?? '-'}'),
            if ((fac['map_coordinates'] ?? '').toString().isNotEmpty)
              _buildRow('📍 Coordinates', '${fac['map_coordinates']}'),
          ],
        );

      case 'drainage_data':
        final dr = (data['drainage_system'] as Map?) ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Location', '${dr['location_name'] ?? '-'}'),
            _buildRow('Amount / Extent', '${dr['development_amount'] ?? '-'}'),
            _buildRow('Current Condition', '${dr['current_condition'] ?? '-'}'),
            _buildRow('Beneficiaries', '${dr['beneficiaries_count'] ?? '-'}'),
          ],
        );

      case 'tourist_attractions_data':
        final tour = (data['tourist_attraction'] as Map?) ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Location', '${tour['location_name'] ?? '-'}'),
            _buildRow('Development Needs', '${tour['development_needs'] ?? '-'}'),
            if ((tour['map_coordinates'] ?? '').toString().isNotEmpty)
              _buildRow('📍 Coordinates', '${tour['map_coordinates']}'),
          ],
        );

      case 'proposals_data':
        final prop = (data['proposal'] as Map?) ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Proposed Project', '${prop['proposed_project'] ?? '-'}'),
            _buildRow('Beneficiaries', '${prop['beneficiaries_count'] ?? '-'}'),
          ],
        );

      case 'disasters_data':
        final dis = (data['disaster_information'] as Map?) ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Disaster Type', '${dis['disaster_type'] ?? '-'}'),
            _buildRow('Affected Area', '${dis['affected_area_name'] ?? '-'}'),
            _buildRow('Risk & Frequency', '${dis['risk_level'] ?? '-'} • ${dis['frequency'] ?? '-'}'),
            _buildRow('Impact', 'Families: ${dis['affected_families_count'] ?? '-'} • Houses: ${dis['affected_houses_count'] ?? '-'}'),
            if ((dis['mitigation_needs'] ?? '').toString().isNotEmpty)
              _buildRow('Mitigation Proposals', '${dis['mitigation_needs']}'),
            if ((dis['safe_evacuation_location'] ?? '').toString().isNotEmpty)
              _buildRow('Safe Evacuation Center', '${dis['safe_evacuation_location']}'),
            if ((dis['map_coordinates'] ?? '').toString().isNotEmpty)
              _buildRow('📍 Coordinates', '${dis['map_coordinates']}'),
          ],
        );

      default:
        return Text('$data', style: const TextStyle(fontSize: 12));
    }
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: ANALYTICS & REGIONAL INSIGHTS SECTION
  // ===========================================================================

  Widget _buildAnalyticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchSurveyAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Unable to calculate analytics.'));
        }

        final data = snapshot.data!;
        final int totalSubmissions = data['total_submissions'] ?? 0;
        final int totalBeneficiaries = data['total_beneficiaries'] ?? 0;
        final int highRiskDisasters = data['high_risk_disasters'] ?? 0;
        final int proposalsCount = data['proposals_count'] ?? 0;
        final Map<String, int> districtMap = data['district_counts'] ?? {};
        final Map<String, int> categoryMap = data['category_counts'] ?? {};
        final Map<String, int> riskMap = data['risk_counts'] ?? {};
        final List<MapEntry<String, int>> topGNs = data['top_gns'] ?? [];

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // KPI Summary Grid
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    title: 'Total Submissions',
                    value: '$totalSubmissions',
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    title: 'Beneficiaries Impact',
                    value: '$totalBeneficiaries',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    title: 'High-Risk Zones',
                    value: '$highRiskDisasters',
                    icon: Icons.warning_rounded,
                    color: const Color(0xFFF43F5E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    title: 'Dev Proposals',
                    value: '$proposalsCount',
                    icon: Icons.lightbulb_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // District Distribution Card
            _buildCardWrapper(
              title: 'District Coverage & Submissions',
              icon: Icons.map_rounded,
              child: Column(
                children: districtMap.entries.map((entry) {
                  final percentage = totalSubmissions > 0
                      ? (entry.value / totalSubmissions)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('${entry.value} submissions (${(percentage * 100).toStringAsFixed(1)}%)',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Module Submissions Distribution
            _buildCardWrapper(
              title: 'Surveys Collected by Module',
              icon: Icons.pie_chart_rounded,
              child: Column(
                children: categoryMap.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.value} records',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Disaster Risk Severity Breakdown
            _buildCardWrapper(
              title: 'Disaster Risk Severity Breakdown',
              icon: Icons.crisis_alert_rounded,
              child: Row(
                children: [
                  _buildRiskBadge('High Risk', riskMap['high'] ?? 0, const Color(0xFFF43F5E)),
                  const SizedBox(width: 8),
                  _buildRiskBadge('Moderate', riskMap['medium'] ?? 0, const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildRiskBadge('Low Risk', riskMap['low'] ?? 0, const Color(0xFF10B981)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Top GN Divisions Table
            _buildCardWrapper(
              title: 'Top Contributing GN Divisions',
              icon: Icons.leaderboard_rounded,
              child: Column(
                children: topGNs.map((e) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(Icons.location_city, size: 14, color: Color(0xFF0284C7)),
                    ),
                    title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    trailing: Text('${e.value} Submissions',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1E88E5), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  /// Aggregates cross-collection analytics
  Future<Map<String, dynamic>> _fetchSurveyAnalytics() async {
    int totalSubs = 0;
    int totalBeneficiaries = 0;
    int highRisk = 0;
    int proposals = 0;
    final Map<String, int> districtMap = {'Matara': 0, 'Galle': 0, 'Hambantota': 0};
    final Map<String, int> categoryMap = {};
    final Map<String, int> gnMap = {};
    int riskHigh = 0, riskMed = 0, riskLow = 0;

    for (final colKey in _categories.keys) {
      final snap = await _firestore.collection(colKey).get();
      categoryMap[_categories[colKey]!] = snap.size;
      totalSubs += snap.size;

      if (colKey == 'proposals_data') {
        proposals = snap.size;
      }

      for (final doc in snap.docs) {
        final d = doc.data();
        final district = (d['district'] ?? '').toString();
        if (district.toLowerCase().contains('matara')) {
          districtMap['Matara'] = (districtMap['Matara'] ?? 0) + 1;
        } else if (district.toLowerCase().contains('galle')) {
          districtMap['Galle'] = (districtMap['Galle'] ?? 0) + 1;
        } else if (district.toLowerCase().contains('hambantota')) {
          districtMap['Hambantota'] = (districtMap['Hambantota'] ?? 0) + 1;
        }

        final gn = (d['gn_division'] ?? '').toString();
        if (gn.isNotEmpty) {
          gnMap[gn] = (gnMap[gn] ?? 0) + 1;
        }

        // Beneficiaries parsing
        final fullStr = '$d';
        final reg = RegExp(r'beneficiaries_count:\s*(\d+)');
        final match = reg.firstMatch(fullStr);
        if (match != null) {
          totalBeneficiaries += int.tryParse(match.group(1)!) ?? 0;
        }

        // Disaster risk parsing
        if (colKey == 'disasters_data') {
          final dis = (d['disaster_information'] as Map?) ?? {};
          final risk = (dis['risk_level'] ?? '').toString().toLowerCase();
          if (risk.contains('high') || risk.contains('අධික')) {
            riskHigh++;
            highRisk++;
          } else if (risk.contains('medium') || risk.contains('moderate') || risk.contains('මධ්‍යම')) {
            riskMed++;
          } else {
            riskLow++;
          }
        }
      }
    }

    final sortedGNs = gnMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_submissions': totalSubs,
      'total_beneficiaries': totalBeneficiaries,
      'high_risk_disasters': highRisk,
      'proposals_count': proposals,
      'district_counts': districtMap,
      'category_counts': categoryMap,
      'risk_counts': {'high': riskHigh, 'medium': riskMed, 'low': riskLow},
      'top_gns': sortedGNs.take(5).toList(),
    };
  }
}