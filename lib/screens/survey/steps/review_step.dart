import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../survey_view_model.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();
    final survey = vm.survey;
    if (survey == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('ගෘහ අංකය', survey.houseNumber),
          _buildSection('ගෘහ මූලිකයා', survey.householderName),
          _buildSection('පවුල් සාමාජිකයන්', survey.familyMembersNames.join(', ')),
          _buildSection('සමෘද්ධි', survey.samurdhiStatus ? 'ඔව්' : 'නැත'),
          _buildSection('දරුවන්', survey.children.isEmpty ? 'නැත' : survey.children.map((c) => c.name).join(', ')),
          const Divider(),
          const Text('නිවාස තොරතුරු', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildSection('හිමිකම', survey.housing.houseOwnership ? 'ඇත' : 'නැත'),
          _buildSection('විදුලිය', survey.housing.electricity ? 'ඇත' : 'නැත'),
          _buildSection('ජලය', survey.housing.water ? 'ඇත' : 'නැත'),
          const Divider(),
          const Text('ආදායම් මාර්ග', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildSection('ප්‍රධාන ආදායම', survey.income.mainIncome),
          _buildSection('රැකියාව', survey.income.job),
          const Divider(),
          const Text('සෞඛ්‍ය හා පෝෂණ', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildSection('ප්‍රධාන ආබාධ', survey.health.hasMainDisability ? 'ඇත' : 'නැත'),
          _buildSection('බීම', survey.health.drinks),
        ],
      ),
    );
  }

  Widget _buildSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}