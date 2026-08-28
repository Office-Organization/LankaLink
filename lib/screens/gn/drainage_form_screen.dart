import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'drainage_view_model.dart';
import 'tourist_attractions_form_screen.dart';

class DrainageFormScreen extends StatelessWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const DrainageFormScreen({super.key, this.editDocId, this.editData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DrainageViewModel(),
      child: _DrainageFormView(editDocId: editDocId, editData: editData),
    );
  }
}

class _DrainageFormView extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const _DrainageFormView({this.editDocId, this.editData});

  @override
  State<_DrainageFormView> createState() => _DrainageFormViewState();
}

class _DrainageFormViewState extends State<_DrainageFormView> {
  final _locationNameCtrl = TextEditingController();
  final _developmentAmountCtrl = TextEditingController();
  final _currentConditionCtrl = TextEditingController();
  final _beneficiariesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _locationNameCtrl.addListener(_onFormFieldChanged);
    _developmentAmountCtrl.addListener(_onFormFieldChanged);
    _currentConditionCtrl.addListener(_onFormFieldChanged);
    _beneficiariesCtrl.addListener(_onFormFieldChanged);

    // --- NEW: Auto-populate form if data was passed from the Dashboard ---
    if (widget.editDocId != null && widget.editData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<DrainageViewModel>();
        _populateFormFromDoc(widget.editDocId!, widget.editData!, vm);
      });
    }
  }

  void _onFormFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _locationNameCtrl.removeListener(_onFormFieldChanged);
    _developmentAmountCtrl.removeListener(_onFormFieldChanged);
    _currentConditionCtrl.removeListener(_onFormFieldChanged);
    _beneficiariesCtrl.removeListener(_onFormFieldChanged);

    _locationNameCtrl.dispose();
    _developmentAmountCtrl.dispose();
    _currentConditionCtrl.dispose();
    _beneficiariesCtrl.dispose();
    super.dispose();
  }

  bool _isFormEmpty() {
    return _locationNameCtrl.text.trim().isEmpty &&
        _developmentAmountCtrl.text.trim().isEmpty &&
        _currentConditionCtrl.text.trim().isEmpty &&
        _beneficiariesCtrl.text.trim().isEmpty;
  }

  void _populateFormFromDoc(
      String docId, Map<String, dynamic> data, DrainageViewModel vm) {
    final drainageData = (data['drainage_system'] as Map?) ?? {};

    setState(() {
      _locationNameCtrl.text = (drainageData['location_name'] ?? '').toString();
      _developmentAmountCtrl.text =
          (drainageData['development_amount'] ?? '').toString();
      _currentConditionCtrl.text =
          (drainageData['current_condition'] ?? '').toString();
      _beneficiariesCtrl.text =
          (drainageData['beneficiaries_count'] ?? '').toString();
    });

    vm.setEditingDocId(docId);
  }

  void _clearForm(DrainageViewModel vm) {
    setState(() {
      _locationNameCtrl.clear();
      _developmentAmountCtrl.clear();
      _currentConditionCtrl.clear();
      _beneficiariesCtrl.clear();
    });
    vm.clearEditing();
  }

  void _handleButtonAction(
      BuildContext context, DrainageViewModel viewModel) async {
    if (_isFormEmpty()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TouristAttractionsFormScreen(),
        ),
      );
      return;
    }

    final bool success = await viewModel.saveDataAndProceed(
      locationName: _locationNameCtrl.text.trim(),
      developmentAmount: _developmentAmountCtrl.text.trim(),
      currentCondition: _currentConditionCtrl.text.trim(),
      beneficiariesCount: _beneficiariesCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.editingDocId != null
              ? 'තොරතුරු සාර්ථකව යාවත්කාලීන කරන ලදී.'
              : 'ජලාපවහන පද්ධති තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _clearForm(viewModel);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TouristAttractionsFormScreen(),
        ),
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
    final viewModel = context.watch<DrainageViewModel>();
    final bool isEmpty = _isFormEmpty();

    return AppScreen(
      title: 'ජලාපවහන පද්ධති',
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
                    '05. ජලාපවහන පද්ධති',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'සංවර්ධනය කළ යුතු ස්ථානය පිළිබඳ විස්තර ඇතුළත් කරන්න.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: 'ස්ථානයෙහි නම:',
                    hint: 'ස්ථානයේ නම',
                    controller: _locationNameCtrl,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'සංවර්ධනය කළයුතු ප්‍රමාණය ආසන්න වශයෙන්:',
                    hint: '00000 000',
                    controller: _developmentAmountCtrl,
                    isNumber: true,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'දැනට පවතින තත්වය:',
                    hint: 'දැනට පවතින තත්වය',
                    controller: _currentConditionCtrl,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'ප්‍රතිලාභීන් ගණන ආසන්නව:',
                    hint: '0000 0000',
                    controller: _beneficiariesCtrl,
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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

            _buildEnteredRecordsSection(viewModel),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEnteredRecordsSection(DrainageViewModel viewModel) {
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
                Icon(Icons.water_drop_outlined,
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
                child:
                    const Text('+ නව වාර්තාවක්', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: viewModel.gnDrainageStream,
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
                    'මෙම වසම සඳහා තවමත් කිසිදු ජලාපවහන දත්තයක් ඇතුළත් කර නොමැත.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final isCurrentEditing = viewModel.editingDocId == doc.id;
                final drainage = (data['drainage_system'] as Map?) ?? {};

                final locName = (drainage['location_name'] ?? '').toString();
                final amount = (drainage['development_amount'] ?? '').toString();
                final condition =
                    (drainage['current_condition'] ?? '').toString();
                final beneficiaries =
                    (drainage['beneficiaries_count'] ?? '').toString();

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
                            const Icon(Icons.water_rounded,
                                size: 18, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locName,
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
                                'ප්‍රමාණය: ${amount.isNotEmpty ? amount : "-"} • තත්ත්වය: ${condition.isNotEmpty ? condition : "-"}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              Text(
                                'ප්‍රතිලාභීන්: ${beneficiaries.isNotEmpty ? beneficiaries : "-"}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
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
                                        'මෙම ජලාපවහන වාර්තාව ස්ථිරවම මකා දැමීමට ඔබට අවශ්‍යද?'),
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

  Widget _buildCollectorLocationCard(DrainageViewModel viewModel) {
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
}