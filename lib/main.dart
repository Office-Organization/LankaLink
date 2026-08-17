import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'data/auth_repository.dart';
import 'data/survey_repository.dart';
import 'data/voter_repository.dart';

void main() async {
  // Ensure Flutter binding is initialized before starting Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // Enable Firestore Offline Persistence
  try {
    await db.enableNetwork();
    db.settings = const Settings(persistenceEnabled: true);
  } catch (e) {
    // Offline persistence error - app will still work with network
  }

  runApp(
    MultiProvider(
      providers: [
        // Provide AuthRepository to the entire app
        ChangeNotifierProvider(create: (_) => AuthRepository(auth, db)),
        // Provide SurveyRepository to the entire app
        Provider(create: (_) => SurveyRepository(db)),
        // Provide VoterRepository to the entire app
        Provider(create: (_) => VoterRepository(db)),
      ],
      child: const LankaLinkApp(),
    ),
  );
}