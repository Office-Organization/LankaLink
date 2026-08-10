import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../survey_view_model.dart';
import '../../../models/survey.dart';

class FamilyStep extends StatefulWidget {
  const FamilyStep({super.key});

  @override
  State<FamilyStep> createState() => _FamilyStepState();
}

class _FamilyStepState extends State<FamilyStep> {
  late final SurveyViewModel _vm;
  final _houseNumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = context.read<SurveyViewModel>();
  }

  @override
  void dispose() {
    _houseNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ගෘහ මූලික අංකය ඇතුළත් කිරීම (Enter එබූ විට සොයයි)
        Row(
          children: [
            const Text('ගෘහ මූලික අංකය', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _houseNumberCtrl,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'අංකය ටයිප් කර Enter ඔබන්න',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.grey.shade300,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) => vm.searchHouse(value), // ස්වයංක්‍රීය දත්ත ලබාගැනීම
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // දත්ත සොයමින් පවතින විට Loading පෙන්වීම
        if (vm.isBusy)
          const Center(child: CircularProgressIndicator()),

        // සාමාජිකයින්ගේ ලැයිස්තුව (Card 1)
        if (!vm.isBusy && vm.familyMembers.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('පවුල් සාමාජිකයන්', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...vm.familyMembers.asMap().entries.map((entry) {
                  int idx = entry.key + 1;
                  var member = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text('($idx.) ${member.name}')),
                        Icon(Icons.face, color: Colors.orange.shade800), // අයිකනය
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          
        const SizedBox(height: 16),
        
        // අස්වැසුම තොරතුරු පෝරමය (Card 2) - අලුත් දත්ත එකතු කිරීම සඳහා
        if (!vm.isBusy && vm.familyMembers.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('අස්වැසුම', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('ඇත', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('විශේෂ අවශ්‍යතා සහිත සාමාජිකයන් ගණන:', style: TextStyle(fontSize: 12)),
                // මෙම ස්ථානයට අමතර දත්ත ඇතුළත් කිරීමේ Fields ඉදිරියේදී එක් කළ හැක
              ],
            ),
          ),
      ],
    );
  }
}