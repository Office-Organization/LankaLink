import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/app_constants.dart';
import 'data/auth_repository.dart';
import 'data/voter_repository.dart';
import 'data/survey_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthRepository>(
          create: (_) => AuthRepository(auth, db),
        ),
        Provider<VoterRepository>(
          create: (_) => VoterRepository(db),
        ),
        Provider<SurveyRepository>(
          create: (_) => SurveyRepository(db, auth),
        ),
      ],
      child: const LankaLinkApp(),
    ),
  );
}