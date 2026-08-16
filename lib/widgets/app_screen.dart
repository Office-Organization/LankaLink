import 'package:flutter/material.dart';
import 'package:lankalink/core/app_theme.dart';

/// A shared scaffold used by most screens to keep the AppBar consistent.
class AppScreen extends StatelessWidget {
  const AppScreen({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: AppColors.white),
        backgroundColor: AppColors.primary,
        elevation: 2.0,
        iconTheme: const IconThemeData(color: AppColors.white),
        centerTitle: true,
      ),
      body: child,
    );
  }
}
