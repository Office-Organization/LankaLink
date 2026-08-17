import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Import your screens properly based on your folder structure
import 'package:lankalink/screens/auth/login_screen.dart';
import 'package:lankalink/core/admin_dashboard_screen.dart';
import 'package:lankalink/screens/dashboard/dashboard_screen.dart';

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
          return const LoginScreen();
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
              } else {
                return const DashboardScreen(); // Default Data Collector Dashboard
              }
            }

            // 4. Fallback: If the user doc doesn't exist for some reason, log them out and go to Login
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          },
        );
      },
    );
  }
}