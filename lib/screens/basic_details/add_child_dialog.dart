import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/basic_details.dart';

class AddChildDialog extends StatefulWidget {
  final ChildInfo? existingChild;

  const AddChildDialog({super.key, this.existingChild});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _disabilityCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _antiSocialDescCtrl = TextEditingController();

  bool _attendsSchool = true;
  String _gender = 'පුරුෂ';

  bool _hasSpecialNeeds = false;
  bool _hasAudioNeed = false;
  bool _hasVisualNeed = false;
  bool _hasOtherNeed = false;

  bool _receivesGovtAssistance = false;
  bool _hasAntiSocialActivities = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.existingChild != null) {
      final c = widget.existingChild!;
      _nameCtrl.text = c.name;
      _dobCtrl.text = c.dob;
      _disabilityCtrl.text = c.disabilityAllowance > 0
          ? c.disabilityAllowance.toString()
          : '';
      _chronicCtrl.text = c.chronicIllnessAllowance > 0
          ? c.chronicIllnessAllowance.toString()
          : '';

      _attendsSchool = c.attendsSchool;
      _gender = c.gender;
      _hasSpecialNeeds = c.hasSpecialNeeds;
      _hasAudioNeed = c.hasAudioNeed;
      _hasVisualNeed = c.hasVisualNeed;
      _hasOtherNeed = c.hasOtherNeed;
      _receivesGovtAssistance = c.receivesGovtAssistance;
      _hasAntiSocialActivities = c.hasAntiSocialActivities;
      _antiSocialDescCtrl.text = c.antiSocialDescription;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _disabilityCtrl.dispose();
    _chronicCtrl.dispose();
    _antiSocialDescCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'කරුණාකර නම ඇතුළත් කරන්න.');
      return;
    }

    final child = ChildInfo(
      id: widget.existingChild?.id,
      name: _nameCtrl.text.trim(),
      attendsSchool: _attendsSchool,
      dob: _dobCtrl.text.trim(),
      gender: _gender,
      hasSpecialNeeds: _hasSpecialNeeds,
      hasAudioNeed: _hasSpecialNeeds ? _hasAudioNeed : false,
      hasVisualNeed: _hasSpecialNeeds ? _hasVisualNeed : false,
      hasOtherNeed: _hasSpecialNeeds ? _hasOtherNeed : false,
      receivesGovtAssistance: _receivesGovtAssistance,
      disabilityAllowance: double.tryParse(_disabilityCtrl.text.trim()) ?? 0.0,
      chronicIllnessAllowance: double.tryParse(_chronicCtrl.text.trim()) ?? 0.0,
      hasAntiSocialActivities: _hasAntiSocialActivities,
      antiSocialDescription: _hasAntiSocialActivities
          ? _antiSocialDescCtrl.text.trim()
          : '',
    );
    Navigator.pop(context, child);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
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
                'පාසල්',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _attendsSchool,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _attendsSchool = true),
                  ),
                  const Text('යන', style: TextStyle(fontFamily: 'UNGanganee')),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: !_attendsSchool,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _attendsSchool = false),
                  ),
                  const Text(
                    'නොයන',
                    style: TextStyle(fontFamily: 'UNGanganee'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                    firstDate: DateTime(2000),
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
              const SizedBox(height: 12),

              const Text(
                'විශේෂ අවශ්‍යතාවල අවශ්‍යතාවය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _hasSpecialNeeds,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _hasSpecialNeeds = true),
                  ),
                  const Text(
                    'අවශ්‍යයි',
                    style: TextStyle(fontFamily: 'UNGanganee'),
                  ),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: !_hasSpecialNeeds,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _hasSpecialNeeds = false),
                  ),
                  const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                ],
              ),
              if (_hasSpecialNeeds) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasAudioNeed,
                            activeColor: Colors.black87,
                            onChanged: (v) =>
                                setState(() => _hasAudioNeed = v!),
                          ),
                          const Text(
                            'ශ්‍රව්‍ය',
                            style: TextStyle(fontFamily: 'UNGanganee'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _hasVisualNeed,
                            activeColor: Colors.black87,
                            onChanged: (v) =>
                                setState(() => _hasVisualNeed = v!),
                          ),
                          const Text(
                            'දෘශ්‍ය',
                            style: TextStyle(fontFamily: 'UNGanganee'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _hasOtherNeed,
                            activeColor: Colors.black87,
                            onChanged: (v) =>
                                setState(() => _hasOtherNeed = v!),
                          ),
                          const Text(
                            'වෙනත්',
                            style: TextStyle(fontFamily: 'UNGanganee'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              const Text(
                'දැනටමත් රජයේ ආධාර ලබන්නේද?',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButtonFormField<bool>(
                initialValue: _receivesGovtAssistance,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.fieldFill,
                ),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text(
                      'ඇත',
                      style: TextStyle(fontFamily: 'UNGanganee'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text(
                      'නැත',
                      style: TextStyle(fontFamily: 'UNGanganee'),
                    ),
                  ),
                ],
                onChanged: (val) =>
                    setState(() => _receivesGovtAssistance = val!),
              ),
              if (_receivesGovtAssistance) ...[
                const SizedBox(height: 16),
                const Text(
                  'ආබාධිත දීමනා ලබන්නේද, ගණන ඇතුලත් කරන්න',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _disabilityCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  'දීර්ඝකාලීන රෝග දීමනා ලබන්නේද, ගණන ඇතුලත් කරන්න',
                  style: TextStyle(
                    fontFamily: 'UNSamantha',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _chronicCtrl,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              const Text(
                'සමාජ විරෝධී ක්‍රියාකාරකම් සිදු කර ඇත්ද?',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _hasAntiSocialActivities,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _hasAntiSocialActivities = true),
                  ),
                  const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee')),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: !_hasAntiSocialActivities,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _hasAntiSocialActivities = false),
                  ),
                  const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                ],
              ),
              if (_hasAntiSocialActivities) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _antiSocialDescCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'සමාජ විරෝධී ක්‍රියාකාරකම් විස්තරය ඇතුළත් කරන්න...',
                  ),
                ),
              ],

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