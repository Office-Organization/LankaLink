import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../core/app_theme.dart';
import '../survey_view_model.dart';
import '../../../models/survey.dart';
import '../add_member_dialog.dart';

class FamilyStep extends StatefulWidget {
  const FamilyStep({super.key});

  @override
  State<FamilyStep> createState() => _FamilyStepState();
}

class _FamilyStepState extends State<FamilyStep> {
  final _houseNumberCtrl = TextEditingController();
  final _specialCountCtrl = TextEditingController();
  final _specialAmountCtrl = TextEditingController();
  final _specialDescCtrl = TextEditingController(); 
  
  bool _isEditingSpecialNeeds = false; 

  @override
  void initState() {
    super.initState();
    _specialCountCtrl.addListener(_updateSpecialNeeds);
    _specialAmountCtrl.addListener(_updateSpecialNeeds);
    _specialDescCtrl.addListener(_updateSpecialNeeds);
  }

  void _updateSpecialNeeds() {
    if (!mounted) return;
    final countText = _specialCountCtrl.text.trim();
    final amountText = _specialAmountCtrl.text.trim();
    final descText = _specialDescCtrl.text.trim();
    
    final count = countText.isEmpty ? 0 : (int.tryParse(countText) ?? 0);
    final amount = amountText.isEmpty ? 0.0 : (double.tryParse(amountText) ?? 0.0);
    
    context.read<SurveyViewModel>().updateSpecialNeeds(count, amount, descText);
  }

  @override
  void dispose() {
    _houseNumberCtrl.dispose();
    _specialCountCtrl.dispose();
    _specialAmountCtrl.dispose();
    _specialDescCtrl.dispose();
    super.dispose();
  }

  Widget _buildSpecialNeedsSection(FamilyInfo family) {
    final hasData = family.specialNeedsCount > 0 || 
                    family.specialNeedsAmount > 0 || 
                    family.specialNeedDescription.isNotEmpty;

    if (hasData && !_isEditingSpecialNeeds) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('විශේෂ අවශ්‍යතා සහිත සාමාජිකයන්', style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () {
                  _specialCountCtrl.text = family.specialNeedsCount > 0 ? family.specialNeedsCount.toString() : '';
                  _specialAmountCtrl.text = family.specialNeedsAmount > 0 ? family.specialNeedsAmount.toString() : '';
                  _specialDescCtrl.text = family.specialNeedDescription;
                  setState(() => _isEditingSpecialNeeds = true);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
               color: AppColors.fieldFill,
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                     Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                             const Text('ගණන', style: TextStyle(fontSize: 13, color: Colors.black54)),
                             const SizedBox(height: 4),
                             Text(family.specialNeedsCount.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                         ],
                     ),
                     Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                             const Text('මුදල (රුපියල්)', style: TextStyle(fontSize: 13, color: Colors.black54)),
                             const SizedBox(height: 4),
                             Text(family.specialNeedsAmount.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                         ],
                     )
                 ]
             )
          ),
          if (family.specialNeedDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'අවශ්‍යතාවය: ${family.specialNeedDescription}', 
              style: const TextStyle(fontSize: 14, color: Colors.black54)
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('විශේෂ අවශ්‍යතා සහිත සාමාජිකයන්', style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16)),
            if (hasData) 
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green, size: 20),
                onPressed: () => setState(() => _isEditingSpecialNeeds = false),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _specialCountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ගණන', hintText: '0'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _specialAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'මුදල (රුපියල්)', hintText: '0.00'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _specialDescCtrl,
          decoration: const InputDecoration(
            labelText: 'විශේෂ අවශ්‍යතාවය කුමක්ද? (විකල්ප)', 
            hintText: 'උදා: ආබාධිත / නිදන්ගත රෝග',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();
    final family = vm.survey.family;
    final members = family.members;
    
    final adults = members.where((m) => m.isAdult).toList();
    final children = members.where((m) => !m.isAdult).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ගෘහ මූලික අංකය',
              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              height: 40,
              child: TextField(
                controller: _houseNumberCtrl,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'අංකය (Enter ඔබන්න)',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black54, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onSubmitted: (value) async {
                  await vm.searchHouse(value);
                  setState(() => _isEditingSpecialNeeds = false); 
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        if (vm.isBusy)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),

        if (!vm.isBusy && vm.survey.houseNumber.isNotEmpty) ...[
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'අස්වැසුම ප්‍රතිලාභ',
                      style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Text(
                          family.hasAswasuma ? 'ඇත' : 'නැත',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: family.hasAswasuma ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: family.hasAswasuma,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            context.read<SurveyViewModel>().toggleAswasuma(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),
                _buildSpecialNeedsSection(family),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('වැඩිහිටි සාමාජිකයන් (අවු: 18 ට වැඩි)'),
          const SizedBox(height: 12),
          if (adults.isEmpty)
            const Text('දත්ත නොමැත', style: TextStyle(color: Colors.grey)),
          ...adults.map((m) => _buildMemberTile(context, m)),
          
          const SizedBox(height: 24),

          _buildSectionTitle('ළමා සාමාජිකයන් (අවු: 18 ට අඩු)'),
          const SizedBox(height: 12),
          if (children.isEmpty)
            const Text('දත්ත නොමැත', style: TextStyle(color: Colors.grey)),
          ...children.map((m) => _buildMemberTile(context, m)),

          const SizedBox(height: 32),

          OutlinedButton.icon(
            onPressed: () async {
              final newMember = await showDialog<FamilyMember>(
                context: context,
                builder: (_) => const AddMemberDialog(),
              );
              if (newMember != null && context.mounted) {
                context.read<SurveyViewModel>().addMember(newMember);
              }
            },
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text('සාමාජිකයෙකු එක් කරන්න', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          _buildCard(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'පවුල පිළිබඳ තවත් තොරතුරු ඇතුලත් කිරීමට හෝ යාවත්කාලීන කිරීමට ඉදිරියට යන්න.',
                style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildMemberTile(BuildContext context, FamilyMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            member.gender == 'ස්ත්‍රී' ? Icons.face_3 : Icons.face,
            color: AppColors.primary,
          ),
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('වයස: ${member.age} | NIC: ${member.nic.isEmpty ? "-" : member.nic}', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () async {
                final updatedMember = await showDialog<FamilyMember>(
                  context: context,
                  builder: (_) => AddMemberDialog(existingMember: member),
                );
                if (updatedMember != null && context.mounted) {
                  context.read<SurveyViewModel>().updateMember(updatedMember);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => context.read<SurveyViewModel>().removeMember(member.id),
            ),
          ],
        ),
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
}