import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/basic_details.dart';

class AddMemberDialog extends StatefulWidget {
  final FamilyMember? existingMember;

  const AddMemberDialog({super.key, this.existingMember});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _nameCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _disabilityCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _antiSocialDescCtrl = TextEditingController();

  String _gender = 'පුරුෂ';
  String _relationship = 'දරුවා';
  bool _attendsSchool = true;
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
    if (widget.existingMember != null) {
      final m = widget.existingMember!;
      _nameCtrl.text = m.fullName;
      _nicCtrl.text = m.nic;
      _dobCtrl.text = m.dob.split('T')[0]; // Remove Time part for input field
      _gender = m.gender;
      _relationship = m.relationship;
      _attendsSchool = m.attendsSchool;
      _hasSpecialNeeds = m.hasSpecialNeeds;
      _hasAudioNeed = m.hasAudioNeed;
      _hasVisualNeed = m.hasVisualNeed;
      _hasOtherNeed = m.hasOtherNeed;
      _receivesGovtAssistance = m.receivesGovtAssistance;
      _disabilityCtrl.text = m.disabilityAllowance > 0 ? m.disabilityAllowance.toString() : '';
      _chronicCtrl.text = m.chronicIllnessAllowance > 0 ? m.chronicIllnessAllowance.toString() : '';
      _hasAntiSocialActivities = m.hasAntiSocialActivities;
      _antiSocialDescCtrl.text = m.antiSocialDescription;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicCtrl.dispose();
    _dobCtrl.dispose();
    _disabilityCtrl.dispose();
    _chronicCtrl.dispose();
    _antiSocialDescCtrl.dispose();
    super.dispose();
  }

  // NIC එකෙන් උපන්දිනය සෙවීමේ Logic එක
  DateTime? _getDobFromNic(String nicStr) {
    if (nicStr.isEmpty) return null;
    nicStr = nicStr.trim().toUpperCase();
    
    int year;
    int days;

    if (nicStr.length == 10 && (nicStr.endsWith('V') || nicStr.endsWith('X'))) {
      year = 1900 + int.parse(nicStr.substring(0, 2));
      days = int.parse(nicStr.substring(2, 5));
    } else if (nicStr.length == 12) {
      year = int.parse(nicStr.substring(0, 4));
      days = int.parse(nicStr.substring(4, 7));
    } else {
      return null; 
    }

    if (days > 500) days -= 500;

    DateTime dob = DateTime(year, 1, 1).add(Duration(days: days - 1));
    bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    if (!isLeapYear && days > 59) {
      dob = dob.subtract(const Duration(days: 1));
    }
    return dob;
  }

  // NIC එකෙන් Gender සෙවීමේ Logic එක
  String? _getGenderFromNic(String nicStr) {
    if (nicStr.isEmpty) return null;
    nicStr = nicStr.trim().toUpperCase();
    int days = 0;
    
    if (nicStr.length == 10) {
      days = int.tryParse(nicStr.substring(2, 5)) ?? 0;
    } else if (nicStr.length == 12) {
      days = int.tryParse(nicStr.substring(4, 7)) ?? 0;
    }
    if (days == 0) return null;
    return days > 500 ? 'ස්ත්‍රී' : 'පුරුෂ';
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'කරුණාකර නම ඇතුළත් කරන්න.');
      return;
    }

    DateTime? calculatedDob;
    String finalGender = _gender;
    
    // උපන්දිනය ඇතුළත් කර නොමැති නම් NIC එකෙන් සෙවීම
    if (_dobCtrl.text.trim().isEmpty) {
      if (_nicCtrl.text.trim().isEmpty) {
        setState(() => _errorMsg = 'කරුණාකර උපන් දිනය හෝ ජාතික හැඳුනුම්පත් අංකය ඇතුළත් කරන්න.');
        return;
      }
      calculatedDob = _getDobFromNic(_nicCtrl.text.trim());
      if (calculatedDob == null) {
        setState(() => _errorMsg = 'ඇතුළත් කළ ජාතික හැඳුනුම්පත් අංකය වැරදියි.');
        return;
      }
      // NIC එකෙන් ස්ත්‍රී පුරුෂ භාවය ගන්නවා (User වෙනස් කරල නැත්නම්)
      finalGender = _getGenderFromNic(_nicCtrl.text.trim()) ?? _gender;
    } else {
      calculatedDob = DateTime.tryParse(_dobCtrl.text.trim());
      if (calculatedDob == null) {
        setState(() => _errorMsg = 'උපන් දිනය වැරදියි.');
        return;
      }
    }

    // වයස ගණනය කිරීම
    final now = DateTime.now();
    int age = now.year - calculatedDob.year;
    if (now.month < calculatedDob.month || (now.month == calculatedDob.month && now.day < calculatedDob.day)) {
      age--;
    }
    
    bool isAdult = age >= 18;
    
    // JSON අකෘතියට (Format එකට) ගැලපෙන සේ උපන්දිනය සැකසීම
    String finalDob = "${calculatedDob.year}-${calculatedDob.month.toString().padLeft(2, '0')}-${calculatedDob.day.toString().padLeft(2, '0')}T00:00:00.000";

    final member = FamilyMember(
      id: widget.existingMember?.id.isNotEmpty == true 
          ? widget.existingMember!.id 
          : DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: _nameCtrl.text.trim(),
      nic: _nicCtrl.text.trim(),
      dob: finalDob,
      age: age,
      gender: finalGender,
      isAdult: isAdult,
      
      relationship: _relationship,
      attendsSchool: _attendsSchool,
      hasSpecialNeeds: _hasSpecialNeeds,
      hasAudioNeed: _hasSpecialNeeds ? _hasAudioNeed : false,
      hasVisualNeed: _hasSpecialNeeds ? _hasVisualNeed : false,
      hasOtherNeed: _hasSpecialNeeds ? _hasOtherNeed : false,
      receivesGovtAssistance: _receivesGovtAssistance,
      disabilityAllowance: double.tryParse(_disabilityCtrl.text.trim()) ?? 0.0,
      chronicIllnessAllowance: double.tryParse(_chronicCtrl.text.trim()) ?? 0.0,
      hasAntiSocialActivities: _hasAntiSocialActivities,
      antiSocialDescription: _hasAntiSocialActivities ? _antiSocialDescCtrl.text.trim() : '',
    );

    Navigator.pop(context, member);
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
              const Text('සාමාජිකයෙකු ඇතුළත් කරන්න', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_errorMsg!, style: const TextStyle(color: AppColors.danger)),
                ),

              _buildTitle('නම (Full Name)'),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'නම ඇතුළත් කරන්න')),
              const SizedBox(height: 12),

              _buildTitle('ජාතික හැඳුනුම්පත් අංකය (NIC)'),
              TextField(controller: _nicCtrl, decoration: const InputDecoration(hintText: 'NIC අංකය')),
              const SizedBox(height: 12),

              _buildTitle('උපන්දිනය (DOB - NIC එක ඇත්නම් අත්‍යාවශ්‍ය නොවේ)'),
              GestureDetector(
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _dobCtrl.text.isNotEmpty ? DateTime.tryParse(_dobCtrl.text) ?? DateTime.now() : DateTime.now(),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _dobCtrl.text = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                      _errorMsg = null;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dobCtrl.text.isNotEmpty ? _dobCtrl.text : 'උපන්දිනය තෝරන්න', style: TextStyle(fontFamily: 'UNGanganee', color: _dobCtrl.text.isEmpty ? Colors.grey : Colors.black)),
                      const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildTitle('ස්ත්‍රී පුරුෂ භාවය'),
              Row(
                children: [
                  Radio<String>(value: 'ස්ත්‍රී', groupValue: _gender, activeColor: AppColors.primary, onChanged: (val) => setState(() => _gender = val!)),
                  const Text('ස්ත්‍රී', style: TextStyle(fontFamily: 'UNGanganee')),
                  Radio<String>(value: 'පුරුෂ', groupValue: _gender, activeColor: AppColors.primary, onChanged: (val) => setState(() => _gender = val!)),
                  const Text('පුරුෂ', style: TextStyle(fontFamily: 'UNGanganee')),
                ],
              ),
              const SizedBox(height: 12),

              _buildTitle('ඥාතීත්වය'),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: const InputDecoration(filled: true, fillColor: AppColors.fieldFill),
                items: ['බිරිඳ/ස්වාමිපුරුෂයා', 'දරුවා', 'සහෝදරයා/සහෝදරිය', 'දෙමව්පියන්', 'වෙනත්'].map((String val) {
                  return DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontFamily: 'UNGanganee')));
                }).toList(),
                onChanged: (val) => setState(() => _relationship = val!),
              ),
              const Divider(height: 32),

              _buildTitle('පාසල් යන/නොයන'),
              Row(
                children: [
                  Radio<bool>(value: true, groupValue: _attendsSchool, activeColor: AppColors.primary, onChanged: (val) => setState(() => _attendsSchool = val!)),
                  const Text('යන', style: TextStyle(fontFamily: 'UNGanganee')),
                  Radio<bool>(value: false, groupValue: _attendsSchool, activeColor: AppColors.primary, onChanged: (val) => setState(() => _attendsSchool = val!)),
                  const Text('නොයන', style: TextStyle(fontFamily: 'UNGanganee')),
                ],
              ),
              const SizedBox(height: 12),

              _buildTitle('විශේෂ අවශ්‍යතාවල අවශ්‍යතාවය'),
              Row(
                children: [
                  Radio<bool>(value: true, groupValue: _hasSpecialNeeds, activeColor: AppColors.primary, onChanged: (val) => setState(() => _hasSpecialNeeds = val!)),
                  const Text('අවශ්‍යයි', style: TextStyle(fontFamily: 'UNGanganee')),
                  Radio<bool>(value: false, groupValue: _hasSpecialNeeds, activeColor: AppColors.primary, onChanged: (val) => setState(() => _hasSpecialNeeds = val!)),
                  const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                ],
              ),
              if (_hasSpecialNeeds) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      CheckboxListTile(title: const Text('ශ්‍රව්‍ය', style: TextStyle(fontFamily: 'UNGanganee')), value: _hasAudioNeed, onChanged: (v) => setState(() => _hasAudioNeed = v!), controlAffinity: ListTileControlAffinity.leading),
                      CheckboxListTile(title: const Text('දෘශ්‍ය', style: TextStyle(fontFamily: 'UNGanganee')), value: _hasVisualNeed, onChanged: (v) => setState(() => _hasVisualNeed = v!), controlAffinity: ListTileControlAffinity.leading),
                      CheckboxListTile(title: const Text('වෙනත්', style: TextStyle(fontFamily: 'UNGanganee')), value: _hasOtherNeed, onChanged: (v) => setState(() => _hasOtherNeed = v!), controlAffinity: ListTileControlAffinity.leading),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              _buildTitle('දැනටමත් රජයේ ආධාර ලබන්නේද?'),
              Row(
                children: [
                  Radio<bool>(value: true, groupValue: _receivesGovtAssistance, activeColor: AppColors.primary, onChanged: (val) => setState(() => _receivesGovtAssistance = val!)),
                  const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee')),
                  Radio<bool>(value: false, groupValue: _receivesGovtAssistance, activeColor: AppColors.primary, onChanged: (val) => setState(() => _receivesGovtAssistance = val!)),
                  const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                ],
              ),
              if (_receivesGovtAssistance) ...[
                const SizedBox(height: 8),
                TextField(controller: _disabilityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ආබාධිත දීමනා ගණන')),
                const SizedBox(height: 8),
                TextField(controller: _chronicCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'දීර්ඝකාලීන රෝග දීමනා ගණන')),
              ],
              const Divider(height: 32),

              _buildTitle('සමාජ විරෝධී ක්‍රියාකාරකම් සිදු කර ඇත්ද?'),
              Row(
                children: [
                  Radio<bool>(value: true, groupValue: _hasAntiSocialActivities, activeColor: AppColors.primary, onChanged: (val) => setState(() => _hasAntiSocialActivities = val!)),
                  const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee')),
                  Radio<bool>(value: false, groupValue: _hasAntiSocialActivities, activeColor: AppColors.primary, onChanged: (val) => setState(() => _hasAntiSocialActivities = val!)),
                  const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                ],
              ),
              if (_hasAntiSocialActivities) ...[
                const SizedBox(height: 8),
                TextField(controller: _antiSocialDescCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'විස්තරය ඇතුළත් කරන්න...')),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _save,
                  child: const Text('හරි', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(text, style: const TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold));
  }
}