import 'package:flutter/material.dart';
import '../../widgets/app_screen.dart';
import 'infrastructure_form_screen.dart'; // Local import within the 'gn' folder

class GnDetailsScreen extends StatelessWidget {
  const GnDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'ග්‍රාම නිලධාරී තොරතුරු',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'ග්‍රාම නිලධාරී වසමට අදාල තොරතුරු\nපෝරමය මෙහි පැමිණේ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ),
            ),
            // Next Page Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InfrastructureFormScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'යටිතල පහසුකම් පෝරමය වෙත',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
