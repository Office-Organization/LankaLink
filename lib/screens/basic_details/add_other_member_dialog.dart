import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/basic_details.dart' show OtherMemberInfo;

class AddOtherMemberDialog extends StatefulWidget {
  final OtherMemberInfo? existingMember;

  const AddOtherMemberDialog({super.key, this.existingMember});

  @override
  State<AddOtherMemberDialog> createState() => _AddOtherMemberDialogState();
}

class _AddOtherMemberDialogState extends State<AddOtherMemberDialog> {
  final _nameCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String _gender = 'පුරුෂ';
  String _relationship = 'බිරිඳ/ස්වාමිපුරුෂයා';
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.existingMember != null) {
      final m = widget.existingMember!;
      _nameCtrl.text = m.name ?? '';
      _nicCtrl.text = m.nic ?? '';
      _dobCtrl.text = m.dateOfBirth ?? '';
      _gender = m.gender ?? 'පුරුෂ';
      _relationship = m.relationship ?? 'බිරිඳ/ස්වාමිපුරුෂයා';
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'කරුණාකර නම ඇතුළත් කරන්න.');
      return;
    }

    final member = OtherMemberInfo(
      id: widget.existingMember?.id ?? '',
      name: _nameCtrl.text.trim(),
      nic: _nicCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      gender: _gender,
      relationship: _relationship,
    );
    Navigator.pop(context, member);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),

              const Text(
                'නම',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'නම ඇතුළත් කරන්න'),
              ),
              const SizedBox(height: 16),

              const Text(
                'ජාතික හැඳුනුම්පත් අංකය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: _nicCtrl,
                decoration: const InputDecoration(hintText: 'NIC අංකය'),
              ),
              const SizedBox(height: 16),

              const Text(
                'උපන්දිනය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _dobCtrl.text.isNotEmpty
                        ? DateTime.tryParse(_dobCtrl.text) ?? DateTime.now()
                        : DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _dobCtrl.text =
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dobCtrl.text.isNotEmpty
                            ? _dobCtrl.text
                            : 'උපන්දිනය තෝරන්න',
                        style: TextStyle(
                          fontFamily: 'UNGanganee',
                          color: _dobCtrl.text.isEmpty
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'ස්ත්‍රී පුරුෂ භාවය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _gender == 'ස්ත්‍රී',
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _gender = 'ස්ත්‍රී'),
                  ),
                  const Text(
                    'ස්ත්‍රී',
                    style: TextStyle(fontFamily: 'UNGanganee'),
                  ),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _gender == 'පුරුෂ',
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _gender = 'පුරුෂ'),
                  ),
                  const Text(
                    'පුරුෂ',
                    style: TextStyle(fontFamily: 'UNGanganee'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'ඥාතීත්වය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _relationship,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.fieldFill,
                ),
                items:
                    [
                      'බිරිඳ/ස්වාමිපුරුෂයා',
                      'දරුවා (වැඩිහිටි)',
                      'සහෝදරයා/සහෝදරිය',
                      'දෙමව්පියන්',
                      'වෙනත්',
                    ].map((String val) {
                      return DropdownMenuItem(
                        value: val,
                        child: Text(
                          val,
                          style: const TextStyle(fontFamily: 'UNGanganee'),
                        ),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => _relationship = val!),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text(
                    'හරි',
                    style: TextStyle(
                      fontFamily: 'UNSamantha',
                      fontSize: 18,
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
}
