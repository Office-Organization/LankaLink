import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'infrastructure_view_model.dart';
import 'agriculture_form_screen.dart';

class InfrastructureFormScreen extends StatelessWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  // Added parameters to receive data from the dashboard
  const InfrastructureFormScreen({super.key, this.editDocId, this.editData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InfrastructureViewModel(),
      child: _InfrastructureFormView(
        editDocId: editDocId,
        editData: editData,
      ),
    );
  }
}

class _InfrastructureFormView extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const _InfrastructureFormView({this.editDocId, this.editData});

  @override
  State<_InfrastructureFormView> createState() =>
      _InfrastructureFormViewState();
}

class _InfrastructureFormViewState extends State<_InfrastructureFormView> {
  // Controllers for road details
  final _roadNameCtrl = TextEditingController();
  final _roadDistanceCtrl = TextEditingController();
  final _roadBeneficiariesCtrl = TextEditingController();

  // Controllers for bridge details
  final _bridgeNameCtrl = TextEditingController();
  final _bridgeConditionCtrl = TextEditingController();
  final _bridgeBeneficiariesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners so the button dynamically changes between "Save" and "Next" as user types
    _roadNameCtrl.addListener(_onFormFieldChanged);
    _roadDistanceCtrl.addListener(_onFormFieldChanged);
    _roadBeneficiariesCtrl.addListener(_onFormFieldChanged);
    _bridgeNameCtrl.addListener(_onFormFieldChanged);
    _bridgeConditionCtrl.addListener(_onFormFieldChanged);
    _bridgeBeneficiariesCtrl.addListener(_onFormFieldChanged);

    // --- NEW: Auto-populate form if data was passed from the Dashboard ---
    if (widget.editDocId != null && widget.editData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<InfrastructureViewModel>();
        _populateFormFromDoc(widget.editDocId!, widget.editData!, vm);
      });
    }
  }

  void _onFormFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _roadNameCtrl.removeListener(_onFormFieldChanged);
    _roadDistanceCtrl.removeListener(_onFormFieldChanged);
    _roadBeneficiariesCtrl.removeListener(_onFormFieldChanged);
    _bridgeNameCtrl.removeListener(_onFormFieldChanged);
    _bridgeConditionCtrl.removeListener(_onFormFieldChanged);
    _bridgeBeneficiariesCtrl.removeListener(_onFormFieldChanged);

    _roadNameCtrl.dispose();
    _roadDistanceCtrl.dispose();
    _roadBeneficiariesCtrl.dispose();
    _bridgeNameCtrl.dispose();
    _bridgeConditionCtrl.dispose();
    _bridgeBeneficiariesCtrl.dispose();
    super.dispose();
  }

  /// Checks if all form input fields and dropdowns are empty / null
  bool _isFormEmpty(InfrastructureViewModel vm) {
    return _roadNameCtrl.text.trim().isEmpty &&
        _roadDistanceCtrl.text.trim().isEmpty &&
        _roadBeneficiariesCtrl.text.trim().isEmpty &&
        _bridgeNameCtrl.text.trim().isEmpty &&
        _bridgeConditionCtrl.text.trim().isEmpty &&
        _bridgeBeneficiariesCtrl.text.trim().isEmpty &&
        vm.selectedRoadType == null &&
        vm.selectedBridgeType == null;
  }

  void _populateFormFromDoc(
      String docId, Map<String, dynamic> data, InfrastructureViewModel vm) {
    final roadData = (data['roads_infrastructure'] as Map?) ?? {};
    final bridgeData = (data['bridges_infrastructure'] as Map?) ?? {};

    setState(() {
      _roadNameCtrl.text = (roadData['road_name'] ?? '').toString();
      _roadDistanceCtrl.text =
          (roadData['development_distance'] ?? '').toString();
      _roadBeneficiariesCtrl.text =
          (roadData['beneficiaries_count'] ?? '').toString();

      _bridgeNameCtrl.text = (bridgeData['bridge_name'] ?? '').toString();
      _bridgeConditionCtrl.text =
          (bridgeData['current_condition'] ?? '').toString();
      _bridgeBeneficiariesCtrl.text =
          (bridgeData['beneficiaries_count'] ?? '').toString();
    });

    vm.setEditingDocId(docId);
    vm.updateRoadType((roadData['road_type'] ?? '').toString().isNotEmpty
        ? roadData['road_type']
        : null);
    vm.updateBridgeType((bridgeData['bridge_type'] ?? '').toString().isNotEmpty
        ? bridgeData['bridge_type']
        : null);
  }

  void _clearForm(InfrastructureViewModel vm) {
    setState(() {
      _roadNameCtrl.clear();
      _roadDistanceCtrl.clear();
      _roadBeneficiariesCtrl.clear();
      _bridgeNameCtrl.clear();
      _bridgeConditionCtrl.clear();
      _bridgeBeneficiariesCtrl.clear();
    });
    vm.clearEditing();
  }

  void _handleButtonAction(
      BuildContext context, InfrastructureViewModel viewModel) async {
    // 1. IF FORM IS NULL / EMPTY: Simply proceed to the next form
    if (_isFormEmpty(viewModel)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AgricultureFormScreen()),
      );
      return;
    }

    // 2. IF USER FEED DATA: Save / Update in Firestore and proceed
    final bool success = await viewModel.saveDataAndProceed(
      roadName: _roadNameCtrl.text.trim(),
      roadDistance: _roadDistanceCtrl.text.trim(),
      roadBeneficiaries: _roadBeneficiariesCtrl.text.trim(),
      bridgeName: _bridgeNameCtrl.text.trim(),
      bridgeCondition: _bridgeConditionCtrl.text.trim(),
      bridgeBeneficiaries: _bridgeBeneficiariesCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.editingDocId != null
              ? 'තොරතුරු සාර්ථකව යාවත්කාලීන කරන ලදී.'
              : 'යටිතල පහසුකම් තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _clearForm(viewModel);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AgricultureFormScreen()),
      );
    } else if (!success && mounted && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InfrastructureViewModel>();
    final bool isEmpty = _isFormEmpty(viewModel);

    return AppScreen(
      title: 'යටිතල පහසුකම්',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Collector Location Card
            _buildCollectorLocationCard(viewModel),
            const SizedBox(height: 16),

            // Active Edit Mode Banner
            if (viewModel.editingDocId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'දැනටමත් ඇතුළත් කළ දත්ත සංස්කරණය කරමින් පවතී.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _clearForm(viewModel),
                      child: const Text('අලුත් එකක් (New)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Roads Section
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '01. මාර්ග සංවර්ධනය',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'මාර්ග සංවර්ධන කටයුතු පිළිබඳ විස්තර මෙහි ඇතුළත් කරන්න.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    label: 'මාර්ගයේ නම:',
                    hint: 'මාර්ගයේ නම ඇතුළත් කරන්න',
                    controller: _roadNameCtrl,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    label: 'මාර්ග වර්ගය:',
                    hint: 'තෝරන්න',
                    value: viewModel.selectedRoadType,
                    items: viewModel.roadTypes,
                    onChanged: (val) => viewModel.updateRoadType(val),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'සංවර්ධනය කළ යුතු දුර (km):',
                    hint: '0.0',
                    controller: _roadDistanceCtrl,
                    isNumber: true,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'ප්‍රතිලාභීන් ගණන:',
                    hint: '0000',
                    controller: _roadBeneficiariesCtrl,
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bridges Section
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '02. පාලම් හා බෝක්කු',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'පාලම් හා බෝක්කු සංවර්ධනය පිළිබඳ විස්තර මෙහි ඇතුළත් කරන්න.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    label: 'පාලම/බෝක්කුවේ නම:',
                    hint: 'නම ඇතුළත් කරන්න',
                    controller: _bridgeNameCtrl,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    label: 'වර්ගය:',
                    hint: 'තෝරන්න',
                    value: viewModel.selectedBridgeType,
                    items: viewModel.bridgeTypes,
                    onChanged: (val) => viewModel.updateBridgeType(val),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'වර්තමාන තත්ත්වය:',
                    hint: 'තත්ත්වය පිළිබඳ විස්තරයක්',
                    controller: _bridgeConditionCtrl,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'ප්‍රතිලාභීන් ගණන:',
                    hint: '0000',
                    controller: _bridgeBeneficiariesCtrl,
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Action Button: Save (if filled) OR Next (if null/empty)
            ElevatedButton.icon(
              onPressed: (viewModel.isSaving || viewModel.isLoadingUser)
                  ? null
                  : () => _handleButtonAction(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmpty
                    ? const Color(0xFF2563EB)
                    : (viewModel.editingDocId != null
                        ? const Color(0xFFD97706)
                        : Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: viewModel.isSaving
                  ? const SizedBox.shrink()
                  : Icon(
                      isEmpty
                          ? Icons.arrow_forward_rounded
                          : (viewModel.editingDocId != null
                              ? Icons.sync_rounded
                              : Icons.check_circle_outline_rounded),
                      color: Colors.white,
                      size: 20,
                    ),
              label: viewModel.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEmpty
                          ? 'ඊළඟට (Next)'
                          : (viewModel.editingDocId != null
                              ? 'යාවත්කාලීන කරන්න (Update)'
                              : 'තොරතුරු සුරකින්න (Save)'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 32),

            // Entered Data Section
            _buildEnteredRecordsSection(viewModel),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEnteredRecordsSection(InfrastructureViewModel viewModel) {
    if (viewModel.gnDivision == null || viewModel.gnDivision!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF1E88E5), size: 20),
                SizedBox(width: 8),
                Text(
                  'දැනට ඇතුළත් කළ දත්ත (Entered Data)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            if (viewModel.editingDocId != null)
              TextButton(
                onPressed: () => _clearForm(viewModel),
                child: const Text('+ නව වාර්තාවක්',
                    style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: viewModel.gnInfrastructureStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'මෙම වසම සඳහා තවමත් කිසිදු දත්තයක් ඇතුළත් කර නොමැත.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final isCurrentEditing = viewModel.editingDocId == doc.id;
                final road = (data['roads_infrastructure'] as Map?) ?? {};
                final bridge = (data['bridges_infrastructure'] as Map?) ?? {};

                final roadName = (road['road_name'] ?? '').toString();
                final roadType = (road['road_type'] ?? '').toString();
                final roadDist =
                    (road['development_distance'] ?? '').toString();
                final roadBen =
                    (road['beneficiaries_count'] ?? '').toString();

                final bridgeName = (bridge['bridge_name'] ?? '').toString();
                final bridgeType = (bridge['bridge_type'] ?? '').toString();
                final bridgeCond =
                    (bridge['current_condition'] ?? '').toString();
                final bridgeBen =
                    (bridge['beneficiaries_count'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCurrentEditing
                        ? const Color(0xFFFFFBEB)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrentEditing
                          ? const Color(0xFFF59E0B)
                          : Colors.grey.shade200,
                      width: isCurrentEditing ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (roadName.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.add_road_rounded,
                                  size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'මාර්ගය: $roadName ($roadType)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 4),
                            child: Text(
                              'දුර: ${roadDist.isNotEmpty ? "$roadDist km" : "-"} • ප්‍රතිලාභීන්: ${roadBen.isNotEmpty ? roadBen : "-"}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (bridgeName.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.architecture_rounded,
                                  size: 18, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'පාලම/බෝක්කුව: $bridgeName ($bridgeType)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 4),
                            child: Text(
                              'තත්ත්වය: ${bridgeCond.isNotEmpty ? bridgeCond : "-"} • ප්‍රතිලාභීන්: ${bridgeBen.isNotEmpty ? bridgeBen : "-"}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _populateFormFromDoc(doc.id, data, viewModel),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('සංස්කරණය / Load',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 18),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('දත්තය මකන්නද?'),
                                    content: const Text(
                                        'මෙම යටිතල පහසුකම් වාර්තාව ස්ථිරවම මකා දැමීමට ඔබට අවශ්‍යද?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('නැත')),
                                      FilledButton(
                                          style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.redAccent),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('ඔව්, මකන්න')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await viewModel.deleteRecord(doc.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCollectorLocationCard(InfrastructureViewModel viewModel) {
    if (viewModel.isLoadingUser) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'පරිශීලක තොරතුරු පූරණය වෙමින් පවතී...',
              style: TextStyle(fontSize: 12.5, color: Colors.blueGrey),
            ),
          ],
        ),
      );
    }

    final nic = viewModel.userNic ?? 'හඳුනාගෙන නැත';
    final name = viewModel.userName ?? '';
    final gn = viewModel.gnDivision ?? 'වසමක් තෝරා නැත';
    final la = viewModel.localAuthority ?? 'පළාත් පාලන ආයතනයක් නැත';
    final district = viewModel.district ?? 'Matara';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 20, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'දත්ත එකතු කරන්නා: $name (ජා.හැ: $nic)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF14532D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: Color(0xFF15803D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$district > $la > $gn',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}