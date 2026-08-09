import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'data/auth_repository.dart';
import 'data/voter_repository.dart';
import 'data/survey_repository.dart';
import 'screens/auth/forgot_password_view_model.dart';
import 'screens/auth/login_view_model.dart';
import 'screens/auth/signup_view_model.dart';
import 'screens/dashboard/dashboard_view_model.dart';
import 'screens/survey/survey_view_model.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // Repositories
        // FIX: Changed from Provider to ChangeNotifierProvider
        ChangeNotifierProvider<AuthRepository>(
          create: (_) =>
              AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
        ),
        Provider<VoterRepository>(
          create: (_) => VoterRepository(FirebaseFirestore.instance),
        ),
        // FIX 1: Use standard Provider instead of ProxyProvider2. 
        // We can pass the Firebase instances directly here.
        Provider<SurveyRepository>(
          create: (_) => SurveyRepository(
            FirebaseFirestore.instance,
            FirebaseAuth.instance,
          ),
        ),

        // View Models
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<SignupViewModel>(
          create: (_) => SignupViewModel(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
          ),
        ),
        ChangeNotifierProvider<ForgotPasswordViewModel>(
          create: (_) => ForgotPasswordViewModel(FirebaseAuth.instance),
        ),
        ChangeNotifierProvider<DashboardViewModel>(
          create: (_) => DashboardViewModel(),
        ),
        // FIX 2: Simplified to a standard ChangeNotifierProvider.
        // It reads the repositories once upon creation.
        ChangeNotifierProvider<SurveyViewModel>(
          create: (context) => SurveyViewModel(
            context.read<SurveyRepository>(),
            context.read<VoterRepository>(),
          ),
        ),
      ],
      child: const LankaLinkApp(),
    ),
  );
}