import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/survey/survey_screen.dart';
import 'screens/gn/gn_details_screen.dart';
import 'data/auth_repository.dart';

// If you already have this exactly like this in app_constants.dart, 
// you can delete this class block. Otherwise, keep it here so the compiler finds it.
class Routes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String survey = '/survey';
  static const String gnDetails = '/gn-details';
}

class LankaLinkApp extends StatelessWidget {
  const LankaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lanka Link',
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        // We can just return the screens directly now because 
        // main.dart is handling all the dependencies!
        '/': (context) => const AuthGate(),
        Routes.login: (context) => const LoginScreen(),
        Routes.signup: (context) => const SignUpScreen(),
        Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
        Routes.dashboard: (context) => const DashboardScreen(),
        Routes.survey: (context) => const SurveyScreen(),
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

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (!auth.isSignedIn) return const WelcomeScreen();
    if (!auth.isActive) return const PendingApprovalScreen();
    
    return const DashboardScreen();
  }
}