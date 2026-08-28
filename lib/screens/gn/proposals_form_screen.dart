import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import 'proposals_view_model.dart';
import 'disasters_form_screen.dart';

class ProposalsFormScreen extends StatelessWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const ProposalsFormScreen({super.key, this.editDocId, this.editData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProposalsViewModel(),
      child: _ProposalsFormView(editDocId: editDocId, editData: editData),
    );
  }
}

class _ProposalsFormView extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const _ProposalsFormView({this.editDocId, this.editData});

  @override
  State<_ProposalsFormView> createState() => _ProposalsFormViewState();
}

class _ProposalsFormViewState extends State<_ProposalsFormView> {
  final _projectCtrl = TextEditingController();
  final _beneficiariesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _projectCtrl.addListener(_onFormFieldChanged);
    _beneficiariesCtrl.addListener(_onFormFieldChanged);

    // --- NEW: Auto-populate form if data was passed from the Dashboard ---
    if (widget.editDocId != null && widget.editData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<ProposalsViewModel>();
        _populateFormFromDoc(widget.editDocId!, widget.editData!, vm);
      });
    }
  }

  void _onFormFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _projectCtrl.removeListener(_onFormFieldChanged);
    _beneficiariesCtrl.removeListener(_onFormFieldChanged);
    _projectCtrl.dispose();
    _beneficiariesCtrl.dispose();
    super.dispose();
  }

  /// Checks if all form input fields are empty / null
  bool _isFormEmpty() {
    return _projectCtrl.text.trim().isEmpty &&
        _beneficiariesCtrl.text.trim().isEmpty;
  }

  void _populateFormFromDoc(
      String docId, Map<String, dynamic> data, ProposalsViewModel vm) {
    final proposalData = (data['proposal'] as Map?) ?? {};

    setState(() {
      _projectCtrl.text =
          (proposalData['proposed_project'] ?? '').toString();
      _beneficiariesCtrl.text =
          (proposalData['beneficiaries_count'] ?? '').toString();
    });

    vm.setEditingDocId(docId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('තෝරාගත් දත්ත පෝරමයට ඇතුළත් කරන ලදී.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearForm(ProposalsViewModel vm) {
    setState(() {
      _projectCtrl.clear();
      _beneficiariesCtrl.clear();
    });
    vm.clearEditing();
  }

  void _handleButtonAction(
      BuildContext context, ProposalsViewModel viewModel) async {
    // 1. IF FORM IS EMPTY / NULL: Directly proceed to next form
    if (_isFormEmpty()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DisastersFormScreen()),
      );
      return;
    }

    // 2. IF FILLED: Save / Update in Firestore and proceed
    final bool success = await viewModel.saveDataAndProceed(
      proposedProject: _projectCtrl.text.trim(),
      beneficiariesCount: _beneficiariesCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.editingDocId != null
              ? 'තොරතුරු සාර්ථකව යාවත්කාලීන කරන ලදී.'
              : 'යෝජනා තොරතුරු සාර්ථකව සුරකින ලදී.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _clearForm(viewModel);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DisastersFormScreen()),
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
    final viewModel = context.watch<ProposalsViewModel>();
    final bool isEmpty = _isFormEmpty();

    return AppScreen(
      title: 'යෝජනා',
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

            // Proposals Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '08. යෝජනා',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: 'යෝජිත සංවර්ධන ව්‍යාපෘතිය ඇතුලත් කරන්න:',
                    hint: 'ව්‍යාපෘතියේ නම / විස්තරය',
                    controller: _projectCtrl,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: 'මෙමගින් ප්‍රතිලාභ ලබන්නන් ගණන ආසන්නව:',
                    hint: '0000000',
                    controller: _beneficiariesCtrl,
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Action Button: Save (if filled) OR Next (if empty)
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

            // Entered Data Records Section
            _buildEnteredRecordsSection(viewModel),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Displays all already entered data fields for this GN Division
  Widget _buildEnteredRecordsSection(ProposalsViewModel viewModel) {
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
                Icon(Icons.lightbulb_outline_rounded,
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
          stream: viewModel.gnProposalsStream,
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
                    'මෙම වසම සඳහා තවමත් කිසිදු යෝජනා දත්තයක් ඇතුළත් කර නොමැත.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final isCurrentEditing = viewModel.editingDocId == doc.id;
                final proposal = (data['proposal'] as Map?) ?? {};

                final project =
                    (proposal['proposed_project'] ?? '').toString();
                final beneficiaries =
                    (proposal['beneficiaries_count'] ?? '').toString();

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
                            const Icon(Icons.assignment_outlined,
                                size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                project,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (beneficiaries.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text(
                              'ප්‍රතිලාභීන් ගණන: $beneficiaries',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
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
                                        'මෙම යෝජනා වාර්තාව ස්ථිරවම මකා දැමීමට ඔබට අවශ්‍යද?'),
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

  Widget _buildCollectorLocationCard(ProposalsViewModel viewModel) {
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