import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'infrastructure_form_screen.dart'; 
import 'agriculture_form_screen.dart';
import 'daily_facilities_form_screen.dart';
import 'drainage_form_screen.dart';
import 'disasters_form_screen.dart';
import 'gn_details_view_model.dart';

class GnDetailsScreen extends StatelessWidget {
  const GnDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GnDetailsViewModel(),
      child: const _GnDetailsView(),
    );
  }
}

class _GnDetailsView extends StatelessWidget {
  const _GnDetailsView();

  void _showChangeLocationDialog(BuildContext context, GnDetailsViewModel viewModel) async {
    final authorities = await viewModel.fetchAvailableLocalAuthorities();
    
    if (!context.mounted) return;
    if (authorities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No local authorities found in database.')),
      );
      return;
    }

    String? selectedAuthorityId = authorities.first['id'];
    String? selectedAuthorityName = authorities.first['name_en'];
    String? selectedDistrict = authorities.first['district_en'];
    
    List<dynamic> currentGNDivisionsList = authorities.first['gn_divisions'];
    String? selectedGN;

    if (currentGNDivisionsList.isNotEmpty) {
      selectedGN = currentGNDivisionsList.first['en']; 
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_location_alt, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'ස්ථානය වෙනස් කරන්න (Change Location)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Local Authority Dropdown
                const Text('පළාත් පාලන ආයතනය (Local Authority)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedAuthorityId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: authorities.map((auth) {
                    final nameEn = auth['name_en'] ?? 'Unknown';
                    final nameSi = auth['name_si']?.toString() ?? '';
                    
                    final displayName = nameSi.isNotEmpty ? '$nameSi ($nameEn)' : nameEn;

                    return DropdownMenuItem<String>(
                      value: auth['id'],
                      child: Text(displayName, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedAuthorityId = val;
                        final auth = authorities.firstWhere((element) => element['id'] == val);
                        selectedAuthorityName = auth['name_en']; 
                        selectedDistrict = auth['district_en'];
                        currentGNDivisionsList = auth['gn_divisions'] ?? [];
                        selectedGN = currentGNDivisionsList.isNotEmpty ? currentGNDivisionsList.first['en'] : null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // GN Division Dropdown
                const Text('ග්‍රාම නිලධාරී වසම (GN Division)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedGN,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: currentGNDivisionsList.map((gn) {
                    final gnNameEn = gn['en']?.toString() ?? 'Unknown'; 
                    final gnNameSi = gn['si']?.toString() ?? '';
                    
                    final displayGnName = gnNameSi.isNotEmpty ? '$gnNameSi ($gnNameEn)' : gnNameEn;

                    return DropdownMenuItem<String>(
                      value: gnNameEn, 
                      child: Text(displayGnName, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedGN = val);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (selectedGN == null || selectedAuthorityName == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('කරුණාකර වලංගු ග්‍රාම නිලධාරී වසමක් තෝරන්න (Select valid GN division).')),
                        );
                        return;
                      }

                      Navigator.pop(context); // Close Modal

                      final success = await viewModel.updateUserLocation(
                        selectedDistrict ?? 'Matara', 
                        selectedAuthorityName!, 
                        selectedGN!
                      );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('ස්ථානය සාර්ථකව යාවත්කාලීන කරන ලදී (Location updated successfully)!'),
                          ),
                        );
                      }
                    },
                    child: viewModel.isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('වෙනස්කම් සුරකින්න (Save Changes)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Parses ISO string into "YYYY MM DD HH:mm" format safely
  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'Unknown Date';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final year = dt.year.toString();
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute';
    } catch (e) {
      return isoString; // fallback to raw string if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GnDetailsViewModel>();

    return AppScreen(
      title: 'ග්‍රාම නිලධාරී තොරතුරු',
      child: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // --- 1. CURRENT LOCATION CARD ---
                const Text(
                  'ඔබගේ වසම (Your Location):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewModel.currentGnDivision ?? 'Not Assigned',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${viewModel.currentLocalAuthority} • ${viewModel.currentDistrict}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showChangeLocationDialog(context, viewModel),
                        icon: const Icon(Icons.edit_location_alt_rounded, color: Colors.blue),
                        tooltip: 'Change Location',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- 2. SUMMARY STATISTICS ---
                Row(
                  children: [
                    _buildStatCard(
                      title: 'ව්‍යාපෘති\n(Projects)',
                      value: viewModel.totalProjects.toString(),
                      icon: Icons.assignment_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      title: 'ප්‍රතිලාභීන්\n(Beneficiaries)',
                      value: viewModel.totalBeneficiaries.toString(),
                      icon: Icons.groups_outlined,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      title: 'අවදානම්\n(Disasters)',
                      value: viewModel.disasterZones.toString(),
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- 3. DATA ENTRY MODULES GRID ---
                const Text(
                  'දත්ත ඇතුලත් කිරීම් (Data Entry)',
                  style: TextStyle(fontFamily: 'UNSamantha', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildGridMenuBtn(
                      context: context,
                      title: 'යටිතල පහසුකම්\n(Infrastructure)',
                      icon: Icons.apartment,
                      color: Colors.orange,
                      onTap: () => _navigateTo(context, const InfrastructureFormScreen()), 
                    ),
                    _buildGridMenuBtn(
                      context: context,
                      title: 'කෘෂිකර්මාන්තය\n(Agriculture)',
                      icon: Icons.eco_rounded,
                      color: Colors.green,
                      onTap: () => _navigateTo(context, const AgricultureFormScreen()),
                    ),
                    _buildGridMenuBtn(
                      context: context,
                      title: 'එදිනෙදා පහසුකම්\n(Daily Facilities)',
                      icon: Icons.local_convenience_store_rounded,
                      color: Colors.teal,
                      onTap: () => _navigateTo(context, const DailyFacilitiesFormScreen()),
                    ),
                    _buildGridMenuBtn(
                      context: context,
                      title: 'ජලාපවහන\n(Drainage)',
                      icon: Icons.water_drop_outlined,
                      color: Colors.blueAccent,
                      onTap: () => _navigateTo(context, const DrainageFormScreen()),
                    ),
                    _buildGridMenuBtn(
                      context: context,
                      title: 'සංචාරක ස්ථාන\n(Tourist Sites)',
                      icon: Icons.tour_outlined,
                      color: Colors.purple,
                      onTap: () {},
                    ),
                    _buildGridMenuBtn(
                      context: context,
                      title: 'ආපදා තොරතුරු\n(Disasters)',
                      icon: Icons.flood_outlined,
                      color: Colors.redAccent,
                      onTap: () => _navigateTo(context, const DisastersFormScreen()), 
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- 4. RECENT SUBMISSIONS FEED (FORMATTED) ---
                const Text(
                  'ඔබගේ වාර්තා කිරීම් (Your Submissions)',
                  style: TextStyle(fontFamily: 'UNSamantha', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                _buildRecentSubmissionsFeed(context, viewModel),
                
                const SizedBox(height: 32),

                // --- 5. START WIZARD BUTTON ---
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InfrastructureFormScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                  label: const Text(
                    'නව සමීක්ෂණයක් අරඹන්න',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // Updated submissions feed to strictly redirect to the 1st form
  Widget _buildRecentSubmissionsFeed(BuildContext context, GnDetailsViewModel viewModel) {
    if (viewModel.recentSubmissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'මෙම වසම සඳහා තවමත් කිසිදු දත්තයක් ඇතුළත් කර නොමැත.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.recentSubmissions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = viewModel.recentSubmissions[index];
        final formattedDate = _formatDateTime(item['timestamp']);
        final reportType = item['typeLabel']; // e.g. "Agriculture (කෘෂිකර්මාන්තය)"

        return InkWell(
          onTap: () {
            // ALWAYS redirect to the first form so the user can flow through one by one
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const InfrastructureFormScreen())
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.history_edu, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$formattedDate : Reported $reportType Report',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.edit_document, color: Colors.grey, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMenuBtn({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}