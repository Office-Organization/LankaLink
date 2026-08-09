import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/app_strings.dart';
import '../core/app_exception.dart';
import '../models/app_user.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository(this._auth, this._db) {
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  late final StreamSubscription<User?> _authStateSubscription;

  AppUser? user;
  bool isLoading = true;

  bool get isSignedIn => user != null;
  bool get isActive => user?.canSignIn ?? false;

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      user = null;
    } else {
      try {
        debugPrint('🔄 Auth changed: User is signed in. Fetching profile...');
        
        // 1. Try to find the document by exact UID (Best Practice)
        var doc = await _db.collection(Db.users).doc(firebaseUser.uid).get();
        
        // 2. Fallback: If Doc ID doesn't match UID, search by email
        if (!doc.exists && firebaseUser.email != null) {
          debugPrint('⚠️ Document ID is not the UID. Searching by email...');
          final query = await _db.collection(Db.users)
              .where(Fields.email, isEqualTo: firebaseUser.email)
              .limit(1)
              .get();
              
          if (query.docs.isNotEmpty) {
            doc = query.docs.first;
          }
        }

        // 3. Process the document if found
        if (doc.exists) {
          user = AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          debugPrint('✅ AppUser profile loaded successfully! Redirecting...');
        } else {
          debugPrint('❌ User document completely missing from Firestore!');
          user = null;
        }
      } catch (e) {
        // If AppUser.fromMap fails (e.g. missing fields, wrong data types), it will print here
        debugPrint('🚨 Error loading AppUser profile: $e');
        user = null;
      }
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithNic(String nic, String password) async {
    final cleanNic = nic.trim();
    final cleanPassword = password.trim();

    try {
      debugPrint('🔎 1. Searching Firestore for NIC: "$cleanNic"');

      // 1. Check NIC in Firestore
      final query = await _db
          .collection(Db.users)
          .where(Fields.nic, isEqualTo: cleanNic)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        debugPrint('❌ NIC "$cleanNic" not found in Firestore.');
        throw const AppException('ඇතුළත් කළ ජා.හැ.අංකය පද්ධතියේ නැත.');
      }

      final userData = query.docs.first.data();
      final email = userData[Fields.email] as String?;

      debugPrint('✅ Found User Document! Email is: "$email"');

      if (email == null || email.trim().isEmpty) {
        debugPrint('❌ Document has no valid email address.');
        throw const AppException('මෙම ගිණුම සඳහා Email ලිපිනයක් සකසා නැත.');
      }

      // 2. Sign in with Firebase Auth
      debugPrint('🔐 2. Attempting Firebase Auth with Email: "$email"');
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: cleanPassword,
      );

      debugPrint('🎉 Sign in successful!');

    } on FirebaseException catch (e) {
      debugPrint('🚨 Firebase Error Code: ${e.code}');
      debugPrint('🚨 Firebase Error Message: ${e.message}');
      throw _translate(e);
    } catch (e) {
      debugPrint('🚨 System/App Error: $e');
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<void> signOut() => _auth.signOut();

  AppException _translate(FirebaseException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return const AppException('මුරපදය (Password) වැරදියි.');
      case 'user-not-found':
        return const AppException('මෙම Email එකට අදාළ User කෙනෙක් Auth හි නැත.');
      case 'permission-denied':
        return const AppException('Database Rules මගින් මෙම සෙවීම අවහිර කර ඇත (Permission Denied).');
      case 'network-request-failed':
        return const AppException(AppStrings.errNoNetwork);
      default:
        return AppException('Firebase Error [${e.code}]: ${e.message}');
    }
  }
}