import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/survey.dart';

class AddMemberDialog extends StatefulWidget {
  final FamilyMember? existingMember; 

  const AddMemberDialog({super.key, this.existingMember});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _nameCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _selectedGender = 'පුරුෂ';
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.existingMember != null) {
      _nameCtrl.text = widget.existingMember!.name;
      _nicCtrl.text = widget.existingMember!.nic;
      _selectedDate = widget.existingMember!.birthday;
      _selectedGender = widget.existingMember!.gender;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _selectedDate == null) {
      setState(() => _errorMsg = 'තරු (*) ලකුණු කළ තොරතුරු අනිවාර්යයි.');
      return;
    }

    final newMember = FamilyMember(
      id: widget.existingMember?.id,
      name: _nameCtrl.text.trim(),
      birthday: _selectedDate!,
      gender: _selectedGender,
      nic: _nicCtrl.text.trim(),
    );

    Navigator.pop(context, newMember); 
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.existingMember == null ? 'සාමාජිකයෙකු එක් කරන්න' : 'තොරතුරු වෙනස් කරන්න',
        style: const TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            
            const Text('සම්පූර්ණ නම *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'නම ඇතුළත් කරන්න'),
            ),
            const SizedBox(height: 16),

            const Text('උපන් දිනය *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null 
                          ? 'දිනය තෝරන්න' 
                          : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black87),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('ස්ත්‍රී / පුරුෂ භාවය *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio<String>(
                  value: 'පුරුෂ',
                  groupValue: _selectedGender,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedGender = val!),
                ),
                const Text('පුරුෂ'),
                Radio<String>(
                  value: 'ස්ත්‍රී',
                  groupValue: _selectedGender,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _selectedGender = val!),
                ),
                const Text('ස්ත්‍රී'),
              ],
            ),
            const SizedBox(height: 8),

            const Text('ජා.හැ.අංකය (NIC)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _nicCtrl,
              decoration: const InputDecoration(hintText: 'අංකය (ඇත්නම් පමණක්)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('අවලංගු කරන්න', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('සුරකින්න', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}