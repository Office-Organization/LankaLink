import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_constants.dart';
import '../../core/app_strings.dart';
import '../../core/app_exception.dart';
import '../../models/app_user.dart';

class SignupViewModel extends ChangeNotifier {
  SignupViewModel(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  bool isLoading = false;
  String? error;
  bool isNicTaken = false;
  bool isCheckingNic = false;

  Future<void> checkNic(String nic) async {
    if (nic.length < 6) {
      isCheckingNic = false;
      isNicTaken = false;
      notifyListeners();
      return;
    }
    isCheckingNic = true;
    notifyListeners();
    try {
      final query = await _db
          .collection(Db.users)
          .where(Fields.nic, isEqualTo: nic.trim())
          .get();
      isNicTaken = query.docs.isNotEmpty;
      if (isNicTaken) {
        error = AppStrings.errDuplicateNic;
      } else {
        error = null;
      }
    } catch (_) {
      isNicTaken = false;
      error = null;
    } finally {
      isCheckingNic = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String fullName,
    required String nic,
    required String email,
    required String mobile,
    required String? district,
    required String gnDivision,
    required String password,
    required String confirmPassword,
  }) async {
    // Validation
    if (fullName.isEmpty || nic.isEmpty || email.isEmpty || mobile.isEmpty || gnDivision.isEmpty) {
      error = AppStrings.errEmptyFields;
      notifyListeners();
      return;
    }
    if (password != confirmPassword) {
      error = AppStrings.errPasswordMismatch;
      notifyListeners();
      return;
    }
    if (isNicTaken) {
      error = AppStrings.errDuplicateNic;
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Final check for duplicate NIC
      final finalCheck = await _db
          .collection(Db.users)
          .where(Fields.nic, isEqualTo: nic.trim())
          .get();
      if (finalCheck.docs.isNotEmpty) {
        throw const AppException(AppStrings.errDuplicateNic);
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Save user profile
      final appUser = AppUser(
        uid: userCredential.user!.uid,
        fullName: fullName.trim(),
        nic: nic.trim(),
        email: email.trim(),
        mobilePhone: mobile.trim(),
        district: district,
        gnDivision: gnDivision.trim(),
        status: UserStatus.inactive,
      );
      await _db.collection(Db.users).doc(appUser.uid).set(appUser.toMap());

      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          error = AppStrings.errWeakPassword;
          break;
        case 'email-already-in-use':
          error = AppStrings.errEmailInUse;
          break;
        default:
          error = e.message ?? AppStrings.errSaveFailed;
      }
    } on AppException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}