import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'disasters_view_model.dart';
import 'map_selection_screen.dart';

class DisastersFormScreen extends StatelessWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const DisastersFormScreen({super.key, this.editDocId, this.editData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DisastersViewModel(),
      child: _DisastersFormView(editDocId: editDocId, editData: editData),
    );
  }
}

class _DisastersFormView extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const _DisastersFormView({this.editDocId, this.editData});

  @override
  State<_DisastersFormView> createState() => _DisastersFormViewState();
}

class _DisastersFormViewState extends State<_DisastersFormView> {
  final _affectedAreaCtrl = TextEditingController();
  final _affectedFamiliesCtrl = TextEditingController();
  final _affectedHousesCtrl = TextEditingController();
  final _mitigationNeedsCtrl = TextEditingController();
  final _safeLocationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _affectedAreaCtrl.addListener(_onFormFieldChanged);
    _affectedFamiliesCtrl.addListener(_onFormFieldChanged);
    _affectedHousesCtrl.addListener(_onFormFieldChanged);
    _mitigationNeedsCtrl.addListener(_onFormFieldChanged);
    _safeLocationCtrl.addListener(_onFormFieldChanged);

    // --- NEW: Auto-populate form if data was passed from the Dashboard ---
    if (widget.editDocId != null && widget.editData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<DisastersViewModel>();
        _populateFormFromDoc(widget.editDocId!, widget.editData!, vm);
      });
    }
  }

  void _onFormFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _affectedAreaCtrl.removeListener(_onFormFieldChanged);
    _affectedFamiliesCtrl.removeListener(_onFormFieldChanged);
    _affectedHousesCtrl.removeListener(_onFormFieldChanged);
    _mitigationNeedsCtrl.removeListener(_onFormFieldChanged);
    _safeLocationCtrl.removeListener(_onFormFieldChanged);

    _affectedAreaCtrl.dispose();
    _affectedFamiliesCtrl.dispose();
    _affectedHousesCtrl.dispose();
    _mitigationNeedsCtrl.dispose();
    _safeLocationCtrl.dispose();
    super.dispose();
  }

  bool _isFormEmpty(DisastersViewModel vm) {
    return _affectedAreaCtrl.text.trim().isEmpty &&
        _affectedFamiliesCtrl.text.trim().isEmpty &&
        _affectedHousesCtrl.text.trim().isEmpty &&
        _mitigationNeedsCtrl.text.trim().isEmpty &&
        _safeLocationCtrl.text.trim().isEmpty &&
        vm.selectedDisasterType == null &&
        vm.selectedRiskLevel == null &&
        vm.selectedFrequency == null &&
        vm.selectedLocationCoordinates == null;
  }

  void _populateFormFromDoc(
      String docId, Map<String, dynamic> data, DisastersViewModel vm) {
    final disasterData = (data['disaster_information'] as Map?) ?? {};

    setState(() {
      _affectedAreaCtrl.text =
          (disasterData['affected_area_name'] ?? '').toString();
      _affectedFamiliesCtrl.text =
          (disasterData['affected_families_count'] ?? '').toString();
      _affectedHousesCtrl.text =
          (disasterData['affected_houses_count'] ?? '').toString();
      _mitigationNeedsCtrl.text =
          (disasterData['mitigation_needs'] ?? '').toString();
      _safeLocationCtrl.text =
          (disasterData['safe_evacuation_location'] ?? '').toString();
    });

    vm.setEditingDocId(docId);
    vm.updateDisasterType(
        (disasterData['disaster_type'] ?? '').toString().isNotEmpty
            ? disasterData['disaster_type']
            : null);
    vm.updateRiskLevel(
        (disasterData['risk_level'] ?? '').toString().isNotEmpty
            ? disasterData['risk_level']
            : null);
    vm.updateFrequency(
        (disasterData['frequency'] ?? '').toString().isNotEmpty
            ? disasterData['frequency']
            : null);
    vm.setLocationCoordinates(
        (disasterData['map_coordinates'] ?? '').toString().isNotEmpty
            ? disasterData['map_coordinates']
            : null);
  }

  void _clearForm(DisastersViewModel vm) {
    setState(() {
      _affectedAreaCtrl.clear();
      _affectedFamiliesCtrl.clear();
      _affectedHousesCtrl.clear();
      _mitigationNeedsCtrl.clear();
      _safeLocationCtrl.clear();
    });
    vm.clearEditing();
  }

  void _handleFinish(
      BuildContext context, DisastersViewModel viewModel) async {
    if (_isFormEmpty(viewModel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('සමීක්ෂණ දත්ත ලබා ගැනීම අවසන් විය.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final bool success = await viewModel.finishAndSave(
      affectedAreaName: _affectedAreaCtrl.text.trim(),
      affectedFamiliesCount: _affectedFamiliesCtrl.text.trim(),
      affectedHousesCount: _affectedHousesCtrl.text.trim(),
      mitigationNeeds: _mitigationNeedsCtrl.text.trim(),
      safeEvacuationLocation: _safeLocationCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.editingDocId != null
              ? 'ආපදා තොරතුරු සාර්ථකව යාවත්කාලීන කරන ලදී!'
              : 'සියලුම තොරතුරු සාර්ථකව සුරකින ලදී!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _clearForm(viewModel);

      Navigator.of(context).popUntil((route) => route.isFirst);
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

  void _pickMapLocation(BuildContext context) {
    final viewModel = context.read<DisastersViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'ස්ථානය ලකුණු කිරීම',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'GPS මගින් ඔබ සිටින ස්ථානය ලබා ගැනීම හෝ සිතියමෙන් ලකුණු කිරීම තෝරන්න.',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              viewModel.setLocationCoordinates('6.9271° N, 79.8612° E (GPS)');
              Navigator.pop(ctx);
            },
            child: const Text(
              'GPS මගින්',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final selectedCoordinates = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapSelectionScreen(),
                ),
              );

              if (selectedCoordinates != null && mounted) {
                viewModel.setLocationCoordinates(selectedCoordinates);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'සිතියමෙන් තෝරන්න',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DisastersViewModel>();
    final bool isEmpty = _isFormEmpty(viewModel);

    return AppScreen(
      title: 'ආපදා තොරතුරු',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCollectorLocationCard(viewModel),
            const SizedBox(height: 16),

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

            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '09. ආපදා සහ අවදානම් කළමනාකරණය',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'වසමේ සිදුවන ආපදා තත්ත්වයන් සහ අවදානම් පිළිබඳ විස්තර මෙහි ඇතුළත් කරන්න.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  _buildDropdownField(
                    label: 'ආපදා වර්ගය තෝරන්න:',
                    hint: 'තෝරන්න',
                    value: viewModel.selectedDisasterType,
                    items: viewModel.disasterTypes,
                    onChanged: (val) => viewModel.updateDisasterType(val),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'පීඩාවට පත්වන ප්‍රදේශය / ස්ථානය / ග්‍රාමය:',
                    hint: 'ප්‍රදේශයේ නම ඇතුළත් කරන්න',
                    controller: _affectedAreaCtrl,
                  ),
                  const SizedBox(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'පීඩාවට පත්වන ප්‍රදේශය සිතියමෙන් සලකුණු කරන්න:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _pickMapLocation(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: viewModel.selectedLocationCoordinates !=
                                      null
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: viewModel
                                            .selectedLocationCoordinates !=
                                        null
                                    ? Colors.blue
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                viewModel.selectedLocationCoordinates ??
                                    'Google Map Point',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: viewModel
                                              .selectedLocationCoordinates !=
                                          null
                                      ? Colors.blue
                                      : Colors.black87,
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

            const SizedBox(height: 20),

            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'අවදානම් මට්ටම සහ පීඩාවට පත්වන ප්‍රමාණය',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildDropdownField(
                    label: 'අවදානම් මට්ටම (Risk Level):',
                    hint: 'අවදානම් මට්ටම තෝරන්න',
                    value: viewModel.selectedRiskLevel,
                    items: viewModel.riskLevels,
                    onChanged: (val) => viewModel.updateRiskLevel(val),
                  ),
                  const SizedBox(height: 20),

                  _buildDropdownField(
                    label: 'සිදුවීමේ වාර ගණන (Frequency):',
                    hint: 'වාර ගණන තෝරන්න',
                    value: viewModel.selectedFrequency,
                    items: viewModel.frequencies,
                    onChanged: (val) => viewModel.updateFrequency(val),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'පීඩාවට පත්වන පවුල් ගණන (ආසන්නව):',
                    hint: '000',
                    controller: _affectedFamiliesCtrl,
                    isNumber: true,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'හානි විය හැකි නිවාස/ගොඩනැගිලි ගණන:',
                    hint: '000',
                    controller: _affectedHousesCtrl,
                    isNumber: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ආපදා අවම කිරීම සහ සහන සැලසුම්',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'ආපදා අවම කිරීමට අවශ්‍ය යෝජනා / පියවර:',
                    hint:
                        'උදා: ආරක්‍ෂිත බැමි ඉදිකිරීම, ඇළ මාර්ග පිරිසිදු කිරීම...',
                    controller: _mitigationNeedsCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'ආසන්නතම ආරක්‍ෂිත ස්ථානය / සහන කඳවුර:',
                    hint: 'උදා: ප්‍රදේශයේ පාසල / පන්සල / ප්‍රජා ශාලාව',
                    controller: _safeLocationCtrl,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: (viewModel.isSaving || viewModel.isLoadingUser)
                  ? null
                  : () => _handleFinish(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmpty
                    ? const Color(0xFF16A34A)
                    : (viewModel.editingDocId != null
                        ? const Color(0xFFD97706)
                        : Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: viewModel.isSaving
                  ? const SizedBox.shrink()
                  : Icon(
                      isEmpty
                          ? Icons.done_all_rounded
                          : (viewModel.editingDocId != null
                              ? Icons.sync_rounded
                              : Icons.check_circle_rounded),
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
                          ? 'අවසන් කරන්න (Finish)'
                          : (viewModel.editingDocId != null
                              ? 'යාවත්කාලීන කරන්න (Update)'
                              : 'සුරකින්න සහ අවසන් කරන්න (Save & Finish)'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 32),

            _buildEnteredRecordsSection(viewModel),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEnteredRecordsSection(DisastersViewModel viewModel) {
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
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE11D48), size: 20),
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
                child:
                    const Text('+ නව වාර්තාවක්', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: viewModel.gnDisastersStream,
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
                    'මෙම වසම සඳහා තවමත් කිසිදු ආපදා දත්තයක් ඇතුළත් කර නොමැත.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final isCurrentEditing = viewModel.editingDocId == doc.id;
                final disaster =
                    (data['disaster_information'] as Map?) ?? {};

                final disType =
                    (disaster['disaster_type'] ?? '').toString();
                final area =
                    (disaster['affected_area_name'] ?? '').toString();
                final risk = (disaster['risk_level'] ?? '').toString();
                final freq = (disaster['frequency'] ?? '').toString();
                final families =
                    (disaster['affected_families_count'] ?? '').toString();
                final houses =
                    (disaster['affected_houses_count'] ?? '').toString();
                final mitigation =
                    (disaster['mitigation_needs'] ?? '').toString();
                final safePlace =
                    (disaster['safe_evacuation_location'] ?? '').toString();
                final coordinates =
                    (disaster['map_coordinates'] ?? '').toString();

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
                        Row(
                          children: [
                            const Icon(Icons.crisis_alert_rounded,
                                size: 18, color: Color(0xFFE11D48)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$disType - $area',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'අවදානම: ${risk.isNotEmpty ? risk : "-"} • වාර ගණන: ${freq.isNotEmpty ? freq : "-"}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700),
                              ),
                              Text(
                                'පීඩාවට පත්වන පවුල්: ${families.isNotEmpty ? families : "-"} • නිවාස: ${houses.isNotEmpty ? houses : "-"}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700),
                              ),
                              if (mitigation.isNotEmpty)
                                Text(
                                  'යෝජනා: $mitigation',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade600),
                                ),
                              if (safePlace.isNotEmpty)
                                Text(
                                  'ආරක්‍ෂිත ස්ථානය: $safePlace',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF15803D),
                                      fontWeight: FontWeight.w600),
                                ),
                              if (coordinates.isNotEmpty)
                                Text(
                                  'ස්ථානය: $coordinates',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 16),
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
                                        'මෙම ආපදා වාර්තාව ස්ථිරවම මකා දැමීමට ඔබට අවශ්‍යද?'),
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

  Widget _buildCollectorLocationCard(DisastersViewModel viewModel) {
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
    int maxLines = 1,
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
          maxLines: maxLines,
          keyboardType: isNumber
              ? TextInputType.number
              : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
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
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}