import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/login_view_model.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/signup_view_model.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/forgot_password_view_model.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/dashboard_view_model.dart';
import 'screens/survey/survey_screen.dart';
import 'screens/survey/survey_view_model.dart';
import 'screens/gn/gn_details_screen.dart';
import 'data/auth_repository.dart';
import 'data/voter_repository.dart';
import 'data/survey_repository.dart';

class LankaLinkApp extends StatelessWidget {
  const LankaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lanka Link',
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        Routes.login: (context) => ChangeNotifierProvider(
          create: (_) => LoginViewModel(context.read<AuthRepository>()),
          child: const LoginScreen(),
        ),
        Routes.signup: (context) => ChangeNotifierProvider(
          create: (_) => SignupViewModel(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
          ),
          child: const SignUpScreen(),
        ),
        Routes.forgotPassword: (context) => ChangeNotifierProvider(
          create: (_) => ForgotPasswordViewModel(FirebaseAuth.instance),
          child: const ForgotPasswordScreen(),
        ),
        Routes.dashboard: (context) => ChangeNotifierProvider(
          create: (_) => DashboardViewModel(),
          child: const DashboardScreen(),
        ),
        Routes.survey: (context) => ChangeNotifierProvider(
          create: (c) => SurveyViewModel(
            c.read<SurveyRepository>(),
            c.read<VoterRepository>(),
          ),
          child: const SurveyScreen(),
        ),
        Routes.gnDetails: (context) => const GNDetailsScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();

    if (auth.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!auth.isSignedIn) return const WelcomeScreen();
    if (!auth.isActive) return const PendingApprovalScreen();
    return const DashboardScreen();
  }
}