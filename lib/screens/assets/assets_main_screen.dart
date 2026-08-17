import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_constants.dart';
import 'assets_view_model.dart';

class AssetsMainScreen extends StatelessWidget {
  const AssetsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssetsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.lightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'දේපල හා වත්කම්',
          style: TextStyle(
            fontFamily: 'UNSamantha',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavButton(context, 'නිශ්චල', () {
                Navigator.pushNamed(
                  context,
                  Routes.assetsImmovable,
                  arguments: vm.houseNumber,
                );
              }),
              const SizedBox(height: 30),
              _buildNavButton(context, 'චංචල', () {
                Navigator.pushNamed(
                  context,
                  Routes.assetsMovable,
                  arguments: vm.houseNumber,
                );
              }),
              const SizedBox(height: 80),
              SizedBox(
                width: 200,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF56B4F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // Next Page logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('තොරතුරු සුරැකිණි!')),
                    );
                  },
                  child: const Text(
                    'ඊළඟ පිටුවට',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF56B4F8), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'UNSamantha',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
