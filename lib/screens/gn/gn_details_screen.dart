import 'package:flutter/material.dart';
import '../../widgets/app_screen.dart';

class GnDetailsScreen extends StatelessWidget {
  const GnDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'ග්‍රාම නිලධාරී තොරතුරු',
      child: Center(
        child: Text(
          'ග්‍රාම නිලධාරී වසමට අදාල තොරතුරු\nපෝරමය මෙහි පැමිණේ.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      ),
    );
  }
}
