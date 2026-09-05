import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoWaterElectricitySummaryScreen extends StatefulWidget {
  const NoWaterElectricitySummaryScreen({super.key});

  @override
  State<NoWaterElectricitySummaryScreen> createState() => _NoWaterElectricitySummaryScreenState();
}

class _NoWaterElectricitySummaryScreenState extends State<NoWaterElectricitySummaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedGN = "සියලුම GN වසම්"; // Default: 'All GN Divisions'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'විදුලිය හා ජලය නොමැති පවුල්',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetching all to do an OR filter on client side (Electricity == No OR Water == No)
        stream: FirebaseFirestore.instance.collection('survey_responses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // 1. Dynamically collect unique GN Divisions from the fetched data
          final Set<String> gnDivisionsSet = {"සියලුම GN වසම්"};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final gn = data['gnDivision'] as String?;
            if (gn != null && gn.isNotEmpty) {
              gnDivisionsSet.add(gn);
            }
          }
          final gnList = gnDivisionsSet.toList();

          // Ensure the selected GN still exists in the list to avoid dropdown errors
          if (!gnList.contains(_selectedGN)) {
            _selectedGN = "සියලුම GN වසම්";
          }

          // 2. Filter the documents based on facilities, GN division, and text search
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final housingDetails = data['housingDetails'] as Map<String, dynamic>? ?? {};
            
            final electricity = housingDetails['electricity'] ?? '';
            final water = housingDetails['water'] ?? '';

            // Filter condition: No electricity OR No water
            bool lacksFacilities = electricity == 'නැත' || water == 'නැත';
            if (!lacksFacilities) return false;

            final gnDivision = data['gnDivision'] ?? '';
            
            // GN Filter check
            if (_selectedGN != "සියලුම GN වසම්" && gnDivision != _selectedGN) {
              return false;
            }

            final houseNumber = (data['houseNumber'] ?? '').toString().toLowerCase();
            final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};
            final nic = (basicDetails['nic'] ?? '').toString().toLowerCase();
            final headName = (basicDetails['headName'] ?? '').toString().toLowerCase();

            if (_searchQuery.isEmpty) return true;

            return houseNumber.contains(_searchQuery) ||
                   nic.contains(_searchQuery) ||
                   headName.contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              // Search & Filter Header Area
              Container(
                color: const Color(0xFF7C3AED),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Dynamic GN Division Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedGN,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                          items: gnList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: value == "සියලුම GN වසම්" ? Colors.grey.shade700 : Colors.black87,
                                  fontWeight: value == "සියලුම GN වසම්" ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedGN = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Text Search Input
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase().trim();
                        });
                      },
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search by Name, NIC or Home ID...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filtered List View
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(
                        child: Text(
                          'දත්ත කිසිවක් හමු නොවීය', 
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data() as Map<String, dynamic>;
                          
                          // Basic Details
                          final houseNumber = data['houseNumber'] ?? 'N/A';
                          final gnDiv = data['gnDivision'] ?? 'N/A';
                          final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};
                          final headName = basicDetails['headName'] ?? 'නම සඳහන් කර නැත';
                          final phone = basicDetails['phone']?.toString().isEmpty ?? true ? 'N/A' : basicDetails['phone'];
                          
                          // Housing Details
                          final housingDetails = data['housingDetails'] as Map<String, dynamic>? ?? {};
                          final electricity = housingDetails['electricity'] ?? 'N/A';
                          final water = housingDetails['water'] ?? 'N/A';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.flash_off_rounded, color: Colors.orange, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              headName, 
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'නිවාස අංකය: $houseNumber',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1, thickness: 1),
                                  ),
                                  _buildDetailRow(Icons.location_on_outlined, 'GN Division', gnDiv),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(Icons.phone_outlined, 'දුරකථන අංකය', phone),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(Icons.electrical_services_outlined, 'විදුලිය', electricity),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(Icons.water_drop_outlined, 'ජල පහසුකම් මාධ්‍ය', water),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}