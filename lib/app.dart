import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_constants.dart';
import 'data/auth_repository.dart';
import 'data/survey_repository.dart';
import 'data/voter_repository.dart';
import 'core/admin_login_screen.dart';
import 'core/admin_signup_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/survey/survey_screen.dart';
import 'screens/survey/survey_view_model.dart';
import 'screens/gn/gn_details_screen.dart';
import 'screens/basic_details/basic_details_screen.dart';
import 'screens/basic_details/basic_details_view_model.dart';
import 'screens/housing/housing_screen.dart';
import 'screens/housing/housing_view_model.dart';
import 'screens/income/income_screen.dart';
import 'screens/income/income_view_model.dart';
import 'screens/assets/assets_main_screen.dart';
import 'screens/assets/immovable_assets_screen.dart';
import 'screens/assets/movable_assets_screen.dart';
import 'screens/assets/assets_view_model.dart';

class LankaLinkApp extends StatelessWidget {
  const LankaLinkApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LankaLink',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const AuthGate(),
    routes: {
      '/signup': (_) => const SignupScreen(),
      '/admin_signup': (_) => const AdminSignupScreen(),
      '/admin_login': (_) => const AdminLoginScreen(),
      Routes.family: (_) => ChangeNotifierProvider(
        create: (c) => SurveyViewModel(
          c.read<SurveyRepository>(),
          c.read<VoterRepository>(),
        ),
        child: const SurveyScreen(),
      ),
      Routes.basicDetails: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final houseNumber = args is String ? args : '';
        return ChangeNotifierProvider(
          create: (c) =>
              BasicDetailsViewModel(c.read<SurveyRepository>(), houseNumber),
          child: const BasicDetailsScreen(),
        );
      },
      Routes.housing: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final houseNumber = args is String ? args : '';
        return ChangeNotifierProvider(
          create: (c) =>
              HousingViewModel(c.read<SurveyRepository>(), houseNumber),
          child: const HousingScreen(),
        );
      },
      Routes.income: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final houseNumber = args is String ? args : '';
        return ChangeNotifierProvider(
          create: (c) =>
              IncomeViewModel(c.read<SurveyRepository>(), houseNumber),
          child: const IncomeScreen(),
        );
      },
      Routes.assetsMain: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final houseNumber = args is String ? args : '';
        return ChangeNotifierProvider(
          create: (c) =>
              AssetsViewModel(c.read<SurveyRepository>(), houseNumber),
          child: const AssetsMainScreen(),
        );
      },
      Routes.assetsImmovable: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final houseNumber = args is String ? args : '';
        return ChangeNotifierProvider(
          create: (c) =>
              AssetsViewModel(c.read<SurveyRepository>(), houseNumber),
          child: const ImmovableAssetsScreen(),
        );
      },
      Routes.assetsMovable: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final houseNumber = args is String ? args : '';
        return ChangeNotifierProvider(
          create: (c) =>
              AssetsViewModel(c.read<SurveyRepository>(), houseNumber),
          child: const MovableAssetsScreen(),
        );
      },
      Routes.gn: (_) => const GnDetailsScreen(),
    },
  );
}
