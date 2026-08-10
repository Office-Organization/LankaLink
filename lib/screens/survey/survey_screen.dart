import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_screen.dart';
import '../../widgets/app_button.dart';
import 'survey_view_model.dart';
import 'steps/family_step.dart';

class SurveyScreen extends StatelessWidget {
  const SurveyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();

    return AppScreen(
      title: 'පවුල් තොරතුරු',
      child: Column(
        children: [
          // Error පණිවිඩයක් පෙන්වීම
          if (vm.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
            ),

          // පෝරමය
          const Expanded(child: FamilyStep()),

          // සුරකින්න බොත්තම
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: AppButton(
              label: 'සුරකින්න',
              isLoading: vm.isBusy,
              onPressed: () async {
                final success = await context.read<SurveyViewModel>().save();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('දත්ත සාර්ථකව සුරැකිණි!')),
                  );
                  Navigator.pop(context); // සාර්ථක නම් Dashboard එකට ආපසු යයි
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
