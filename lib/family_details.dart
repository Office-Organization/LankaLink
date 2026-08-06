
import 'package:flutter/material.dart';

class FamilyDetailsScreen extends StatelessWidget {
  const FamilyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('පවුල් තොරතුරු'), 
        backgroundColor: const Color(0xFFC2185B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'පවුල් තොරතුරු මෙහි දිස්වනු ඇත.', // "Family details will appear here"
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}