import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_constants.dart';
import 'data/auth_repository.dart';
import 'data/survey_repository.dart';
import 'data/voter_repository.dart'; // අලුතින් එක් කරන ලදී
import 'screens/auth/login_screen.dart';
import 'screens/auth/login_view_model.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/survey/survey_screen.dart';
import 'screens/survey/survey_view_model.dart';
import 'screens/gn/gn_details_screen.dart';

class LankaLinkApp extends StatelessWidget {
  const LankaLinkApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LankaLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(), // මුලින්ම AuthGate වෙත යවයි
        routes: {
          // පවුල් තොරතුරු තිරය සඳහා Route එක සහ ViewModel සැකසීම
          Routes.family: (_) => ChangeNotifierProvider(
            create: (c) => SurveyViewModel(
              c.read<SurveyRepository>(),
              c.read<VoterRepository>(), // අලුතින් එක් කරන ලදී
            ),
            child: const SurveyScreen(),
          ),
          // ග්‍රාම නිලධාරී තොරතුරු තිරය සඳහා Route එක
          Routes.gn: (_) => const GnDetailsScreen(),
        },
      );
}

/// පරිශීලකයා ලොග් වී ඇත්දැයි පරීක්ෂා කර අදාළ තිරය තීරණය කරන කොටස
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();

    // දත්ත පරීක්ෂා කරන තුරු Loading තිරය පෙන්වීම
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // ලොග් වී නොමැති නම් Login තිරය පෙන්වීම
    if (!auth.isSignedIn) {
      return ChangeNotifierProvider(
        create: (c) => LoginViewModel(c.read<AuthRepository>()),
        child: const LoginScreen(),
      );
    }
    
    // සාර්ථකව ලොග් වී ඇත්නම් Dashboard එක පෙන්වීම
    return const DashboardScreen();
  }
}