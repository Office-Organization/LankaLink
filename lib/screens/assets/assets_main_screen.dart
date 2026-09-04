import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'assets_view_model.dart';

class AssetsMainScreen extends StatefulWidget {
  const AssetsMainScreen({super.key});

  @override
  State<AssetsMainScreen> createState() => _AssetsMainScreenState();
}

class _AssetsMainScreenState extends State<AssetsMainScreen> {
  // නිශ්චල හෝ චංචල බොත්තම් වලින් එකක් හෝ එබුවාද යන්න සටහන් කරගන්නා විචල්‍යය
  bool _hasVisitedAssetPage = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssetsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'දේපල හා වත්කම්',
          style: TextStyle(
            fontFamily: 'UNSamantha',
            color: AppColors.textPrimary,
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
              _buildNavButton(context, 'නිශ්චල', () async {
                await Navigator.pushNamed(
                  context,
                  Routes.assetsImmovable,
                  arguments: vm.houseNumber,
                );
                // ආපසු ආ පසු බොත්තම සක්‍රීය කරයි
                if (mounted) {
                  setState(() => _hasVisitedAssetPage = true);
                }
              }),
              const SizedBox(height: 30),
              _buildNavButton(context, 'චංචල', () async {
                await Navigator.pushNamed(
                  context,
                  Routes.assetsMovable,
                  arguments: vm.houseNumber,
                );
                // ආපසු ආ පසු බොත්තම සක්‍රීය කරයි
                if (mounted) {
                  setState(() => _hasVisitedAssetPage = true);
                }
              }),
              
              const SizedBox(height: 80),
              
              SizedBox(
                width: double.infinity, // බොත්තම තිරයේ පළලටම දිස්වීමට
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // 🟢 බොත්තම සක්‍රීය නම් කොළ පාට, අක්‍රීය නම් අළු පාට පෙන්වීමට
                    backgroundColor: _hasVisitedAssetPage 
                        ? AppColors.primary 
                        : Colors.grey.shade400, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 🟢 බොත්තම් දෙකෙන් එකක් හෝ ඔබා ඇත්නම් පමණක් ක්‍රියාත්මක වේ
                    if (_hasVisitedAssetPage) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'සියලුම තොරතුරු සාර්ථකව සුරැකිණි!',
                            style: TextStyle(
                              fontFamily: 'UNSamantha', 
                              color: AppColors.white, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      
                      // 🟢 සියලුම පිටු වසා දමා පළමු පිටුවටම (Home / First Page) යාම
                      Navigator.popUntil(context, (route) => route.isFirst);
                      
                    } else {
                      // 🟢 එසේ නොමැති නම් අනතුරු ඇඟවීමක් පෙන්වයි
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'කරුණාකර ඉදිරියට යාමට පෙර නිශ්චල හෝ චංචල දේපල තොරතුරු පරීක්ෂා කරන්න.',
                            style: TextStyle(
                              fontFamily: 'UNSamantha', 
                              color: Colors.white, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'අවසන් කර මුල් පිටුවට යන්න',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontSize: 20,
                      color: AppColors.white,
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2), 
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'UNSamantha',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}