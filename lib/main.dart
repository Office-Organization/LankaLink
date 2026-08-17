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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // Force Firebase to NOT save the session. 
  // This ensures a page refresh will clear the login and send them to the login screen.
  await auth.setPersistence(Persistence.NONE);

  // Enable Firestore Offline Persistence
  try {
    await db.enableNetwork();
    db.settings = const Settings(persistenceEnabled: true);
  } catch (e) {
    debugPrint("Offline persistence error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthRepository(auth, db)),
        Provider(create: (_) => SurveyRepository(db)),
        Provider(create: (_) => VoterRepository(db)),
      ],
      child: const LankaLinkApp(),
    ),
  );
}