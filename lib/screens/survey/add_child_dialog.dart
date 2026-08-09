import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../models/child.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_check_option.dart';
import 'survey_view_model.dart';

void showAddChildDialog(BuildContext context, SurveyViewModel vm) {
  final nameCtrl = TextEditingController();
  final nicCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final schoolCtrl = TextEditingController();
  String gender = 'පිරිමි';
  bool attendsSchool = true;
  bool specialNeeds = false;

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('දරුවෙක් එකතු කරන්න', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                AppTextField(controller: nicCtrl, label: 'NIC අංකය (අනිවාර්ය)'),
                AppTextField(controller: nameCtrl, label: 'නම'),
                AppTextField(controller: dobCtrl, label: 'උපන්දිනය', hint: 'mm/dd/yyyy'),
                Row(
                  children: [
                    AppCheckOption(label: 'පිරිමි', selected: gender == 'පිරිමි', onTap: () => gender = 'පිරිමි'),
                    const SizedBox(width: 16),
                    AppCheckOption(label: 'ගැහැණු', selected: gender == 'ගැහැණු', onTap: () => gender = 'ගැහැණු'),
                  ],
                ),
                Row(
                  children: [
                    AppCheckOption(label: 'යන', selected: attendsSchool, onTap: () => attendsSchool = !attendsSchool),
                    const SizedBox(width: 16),
                    AppCheckOption(label: 'නොයන', selected: !attendsSchool, onTap: () => attendsSchool = !attendsSchool),
                  ],
                ),
                if (attendsSchool) AppTextField(controller: schoolCtrl, label: 'පාසලේ නම'),
                Row(
                  children: [
                    AppCheckOption(label: 'විශේෂ අවශ්‍යතා සහිතද', selected: specialNeeds, onTap: () => specialNeeds = !specialNeeds),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && nicCtrl.text.isNotEmpty) {
                        final child = Child(
                          nic: nicCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          dob: dobCtrl.text.trim(),
                          gender: gender,
                          school: schoolCtrl.text.trim(),
                          attendsSchool: attendsSchool,
                          specialNeeds: specialNeeds,
                        );
                        vm.addChild(child);
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text(AppStrings.errChildNameNic)),
                        );
                      }
                    },
                    child: const Text(AppStrings.ok),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}