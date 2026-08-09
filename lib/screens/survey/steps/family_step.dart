import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_strings.dart';
import '../../../models/survey.dart';
import '../../../widgets/app_text_field.dart';
import '../../survey/survey_view_model.dart';

class FamilyStep extends StatefulWidget {
  const FamilyStep({super.key});

  @override
  State<FamilyStep> createState() => _FamilyStepState();
}

class _FamilyStepState extends State<FamilyStep> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _membersCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SurveyViewModel>();
      if (vm.survey != null) {
        _membersCtrl.text = vm.survey!.familyMembersNames.join(', ');
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _membersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _searchCtrl,
                label: 'ගෘහ අංකය (සොයන්න)',
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                vm.loadOrCreate(_searchCtrl.text.trim());
              },
              child: const Text('සොයන්න'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (vm.survey != null) ...[
          Text('ගෘහ මූලික අංකය: ${vm.survey!.houseNumber}'),
          const SizedBox(height: 8),
          Text('ගෘහ මූලිකයා: ${vm.survey!.householderName}'),
          const SizedBox(height: 16),
          AppTextField(
            controller: _membersCtrl,
            label: 'පවුල් සාමාජිකයන් (කොමාවෙන් වෙන් කරන්න)',
            maxLines: 3,
            onChanged: (val) {
              final members = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              vm.updateFamilyMembers(members);
            },
          ),
        ],
        if (vm.error != null) ...[
          const SizedBox(height: 16),
          Text(vm.error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}