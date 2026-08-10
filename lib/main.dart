import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'data/auth_repository.dart';
import 'data/survey_repository.dart';
// අදාළ import එකතු කරන්න
import 'data/voter_repository.dart';

// MultiProvider එක ඇතුළත providers ලැයිස්තුවට මෙය එක් කරන්න:

void main() async {
  // Firebase ආරම්භ කිරීමට පෙර Flutter Binding සහතික කිරීම
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase Initialize කිරීම
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  runApp(
    MultiProvider(
      providers: [
        // AuthRepository එක මුළු App එකටම ලබා දීම
        ChangeNotifierProvider(create: (_) => AuthRepository(auth, db)),
        // SurveyRepository එක මුළු App එකටම ලබා දීම
        Provider(create: (_) => SurveyRepository(db)),
                Provider(create: (_) => VoterRepository(db)),

      ],
      child: const LankaLinkApp(),
    ),
  );
}