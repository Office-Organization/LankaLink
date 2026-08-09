import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final T value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          hint: hint != null ? Text(hint!, style: const TextStyle(fontFamily: 'UN-Imanee')) : null,
          items: items.map((T val) {
            return DropdownMenuItem<T>(
              value: val,
              child: Text(
                val.toString(),
                style: const TextStyle(fontFamily: 'UN-Imanee'),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}