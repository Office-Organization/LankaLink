import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  int? selectedCardIndex;

  void selectCard(int index) {
    selectedCardIndex = index;
    notifyListeners();
  }

  void clearSelection() {
    selectedCardIndex = null;
    notifyListeners();
  }
}