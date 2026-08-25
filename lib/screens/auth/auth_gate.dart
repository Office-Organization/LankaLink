import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lankalink/core/admin_dashboard_screen.dart';
import 'package:lankalink/data/auth_repository.dart';
import 'package:lankalink/screens/auth/login_screen.dart';
import 'package:lankalink/screens/auth/login_view_model.dart';
import 'package:lankalink/screens/dashboard/dashboard_screen.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to Firebase Auth state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While checking auth state, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If the user is NOT logged in, send them to the Login Screen
        if (!snapshot.hasData || snapshot.data == null) {
          return ChangeNotifierProvider(
            create: (c) => LoginViewModel(c.read<AuthRepository>()),
            child: const LoginScreen(),
          );
        }

        // 3. If the user IS logged in, fetch their role from Firestore to route them correctly
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            // While fetching the user document, show loading
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If we successfully get the user document, check the role
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              final role = data['role']?.toString();

              if (role == 'admin') {
                return const AdminDashboardScreen();
              }
              return const DashboardScreen(); // Default for 'data collector' or other roles
            }

            // 4. Fallback: If user doc doesn't exist, sign out. The stream will rebuild and show LoginScreen.
            FirebaseAuth.instance.signOut();
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}
