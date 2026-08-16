import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'assets_view_model.dart';

class MovableAssetsScreen extends StatelessWidget {
  const MovableAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssetsViewModel>();
    final details = vm.details;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'වාහන ඇත්නම් තෝරන්න',
              style: TextStyle(
                fontFamily: 'UNSamantha',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildCheckRow(
              'බයික්',
              details.hasBike,
              (v) => vm.updateField(hasBike: v),
              'ත්‍රී වීල්',
              details.hasThreeWheeler,
              (v) => vm.updateField(hasThreeWheeler: v),
            ),
            _buildCheckRow(
              'වෑන්',
              details.hasVan,
              (v) => vm.updateField(hasVan: v),
              'ලොරි',
              details.hasLorry,
              (v) => vm.updateField(hasLorry: v),
            ),
            _buildCheckRow(
              'බස්',
              details.hasBus,
              (v) => vm.updateField(hasBus: v),
              'ට්‍රැක්ටර්',
              details.hasTractor,
              (v) => vm.updateField(hasTractor: v),
            ),
            _buildCheckRow(
              'කාර්',
              details.hasCar,
              (v) => vm.updateField(hasCar: v),
              'කැබ්',
              details.hasCab,
              (v) => vm.updateField(hasCab: v),
            ),

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'වෙනත්',
                        style: TextStyle(
                          fontFamily: 'UNGanganee',
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Checkbox(
                        value: details.hasOtherVehicle,
                        activeColor: Colors.black,
                        onChanged: (v) => vm.updateField(hasOtherVehicle: v),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container()), // Empty space for layout balance
              ],
            ),

            const SizedBox(height: 80),
            Center(
              child: SizedBox(
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
                    await vm.save();
                    if (context.mounted) Navigator.pop(context);
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(
    String t1,
    bool v1,
    Function(bool?) onChange1,
    String t2,
    bool v2,
    Function(bool?) onChange2,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  t1,
                  style: const TextStyle(
                    fontFamily: 'UNGanganee',
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: v1,
                  activeColor: Colors.black,
                  onChanged: onChange1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              children: [
                Text(
                  t2,
                  style: const TextStyle(
                    fontFamily: 'UNGanganee',
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: v2,
                  activeColor: Colors.black,
                  onChanged: onChange2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
