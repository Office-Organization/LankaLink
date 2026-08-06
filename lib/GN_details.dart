
import 'package:flutter/material.dart';

class GNDetailsScreen extends StatelessWidget {
  const GNDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ග්‍රාම නිලධාරී තොරතුරු'), 
        backgroundColor: const Color(0xFFC2185B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'ග්‍රාම නිලධාරී වසමට අදාල තොරතුරු මෙහි දිස්වනු ඇත.', // "GN division details will appear here"
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}