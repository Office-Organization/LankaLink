import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_constants.dart';
import 'data/auth_repository.dart';
import 'data/survey_repository.dart';
import 'data/voter_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/login_view_model.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/survey/survey_screen.dart';
import 'screens/survey/survey_view_model.dart';
import 'screens/gn/gn_details_screen.dart';
import 'screens/basic_details/basic_details_screen.dart';
import 'screens/basic_details/basic_details_view_model.dart';
import 'screens/housing/housing_screen.dart';
import 'screens/housing/housing_view_model.dart';
import 'screens/income/income_screen.dart'; // 🔥 අලුත් import
import 'screens/income/income_view_model.dart'; // 🔥 අලුත් import

class LankaLinkApp extends StatelessWidget {
  const LankaLinkApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LankaLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(), 
        routes: {
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
              create: (c) => BasicDetailsViewModel(
                c.read<SurveyRepository>(), 
                houseNumber,
              ),
              child: const BasicDetailsScreen(),
            );
          },

          Routes.housing: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final houseNumber = args is String ? args : ''; 
            
            return ChangeNotifierProvider(
              create: (c) => HousingViewModel(
                c.read<SurveyRepository>(), 
                houseNumber,
              ),
              child: const HousingScreen(),
            );
          },

          // 🔥 අලුත් Income Route එක
          Routes.income: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final houseNumber = args is String ? args : ''; 
            
            return ChangeNotifierProvider(
              create: (c) => IncomeViewModel(
                c.read<SurveyRepository>(), 
                houseNumber,
              ),
              child: const IncomeScreen(),
            );
          },

          Routes.gn: (_) => const GnDetailsScreen(),
        },
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!auth.isSignedIn) {
      return ChangeNotifierProvider(
        create: (c) => LoginViewModel(c.read<AuthRepository>()),
        child: const LoginScreen(),
      );
    }
    
    return const DashboardScreen();
  }
}