import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoIncomeSummaryScreen extends StatefulWidget {
  const NoIncomeSummaryScreen({super.key});

  @override
  State<NoIncomeSummaryScreen> createState() => _NoIncomeSummaryScreenState();
}

class _NoIncomeSummaryScreenState extends State<NoIncomeSummaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedGN = "සියලුම GN වසම්";

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
          'ආදායම් මාර්ගයක් නොමැති පවුල්',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('survey_responses')
            .where('incomeDetails.mainIncome', isEqualTo: '')
            .where('incomeDetails.extraIncome', isEqualTo: 'නැත')
            .snapshots(),
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

          // 1. Dynamically collect unique GN Divisions
          final Set<String> gnDivisionsSet = {"සියලුම GN වසම්"};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final gn = data['gnDivision'] as String?;
            if (gn != null && gn.isNotEmpty) {
              gnDivisionsSet.add(gn);
            }
          }
          final gnList = gnDivisionsSet.toList();

          if (!gnList.contains(_selectedGN)) {
            _selectedGN = "සියලුම GN වසම්";
          }

          // 2. Filter the documents
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            final gnDivision = (data['gnDivision'] ?? '').toString();
            
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
                   gnDivision.toLowerCase().contains(_searchQuery) ||
                   headName.contains(_searchQuery) ||
                   nic.contains(_searchQuery);
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
                        hintText: 'Search by Name, NIC, or Home ID...',
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
                          
                          final houseNumber = data['houseNumber'] ?? 'N/A';
                          final gnDivision = data['gnDivision'] ?? 'N/A';
                          final basicDetails = data['basicDetails'] as Map<String, dynamic>? ?? {};
                          final headName = basicDetails['headName'] ?? 'නම සඳහන් කර නැත';
                          final nic = basicDetails['nic'] ?? 'N/A';
                          final phone = basicDetails['phone']?.toString().isEmpty ?? true 
                              ? 'N/A' 
                              : basicDetails['phone'];

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
                                          color: const Color(0xFFF3E8FF),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.home_work_outlined, color: Color(0xFF7C3AED), size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'නිවාස අංකය: $houseNumber',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              headName,
                                              style: const TextStyle(
                                                fontSize: 15,
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
                                  _buildDetailRow(Icons.location_on_outlined, 'GN Division', gnDivision),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(Icons.badge_outlined, 'NIC', nic),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'ප්‍රධාන හෝ අමතර ආදායමක් නොමැත',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}