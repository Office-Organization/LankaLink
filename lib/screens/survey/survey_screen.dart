import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/app_constants.dart';
import '../../widgets/app_screen.dart';
import '../../widgets/status_views.dart';
import 'survey_view_model.dart';
import 'steps/family_step.dart';
import 'steps/basic_step.dart';
import 'steps/housing_step.dart';
import 'steps/income_step.dart';
import 'steps/health_step.dart';
import 'steps/review_step.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  final List<Widget> _steps = const [
    FamilyStep(),
    BasicStep(),
    HousingStep(),
    IncomeStep(),
    HealthStep(),
    ReviewStep(),
  ];
  final List<String> _titles = [
    AppStrings.familyDetails,
    AppStrings.basicDetails,
    AppStrings.housingDetails,
    AppStrings.incomeSources,
    AppStrings.healthNutrition,
    AppStrings.review,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();

    if (vm.isBusy) return const LoadingView();
    if (vm.error != null) {
      return ErrorView(
        vm.error!,
        onRetry: () => vm.loadOrCreate(''), // we need the house number, but we'll pass from args
      );
    }
    if (vm.survey == null) {
      // Should not happen after load
      return const SizedBox.shrink();
    }

    return AppScreen(
      title: _titles[vm.currentPage],
      showBack: vm.currentPage > 0,
      child: Column(
        children: [
          // Page indicator or step number
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: vm.currentPage == index ? Colors.blue : Colors.grey.shade300,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => vm.goToPage(page),
              children: _steps,
            ),
          ),
          const SizedBox(height: 16),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (vm.currentPage > 0)
                TextButton(
                  onPressed: () => _goToPage(vm.currentPage - 1),
                  child: const Text(AppStrings.back),
                ),
              if (vm.currentPage < _steps.length - 1)
                ElevatedButton(
                  onPressed: () => _saveAndNext(vm),
                  child: const Text(AppStrings.next),
                ),
              if (vm.currentPage == _steps.length - 1)
                ElevatedButton(
                  onPressed: () => _finish(vm),
                  child: const Text('සමාප්ත කරන්න'),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveAndNext(SurveyViewModel vm) async {
    await vm.saveAndContinue();
    if (vm.error == null) {
      _goToPage(vm.currentPage + 1);
    }
  }

  Future<void> _finish(SurveyViewModel vm) async {
    await vm.saveAndContinue();
    if (vm.error == null) {
      // Navigate back to dashboard or show success
      Navigator.popUntil(context, ModalRoute.withName('/'));
    }
  }
}