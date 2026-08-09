import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../widgets/app_screen.dart';

class GNDetailsScreen extends StatelessWidget {
  const GNDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'ග්‍රාම නිලධාරී තොරතුරු',
      child: const Center(
        child: Text(
          'ග්‍රාම නිලධාරී වසමට අදාල තොරතුරු මෙහි දිස්වනු ඇත.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}