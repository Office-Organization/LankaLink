import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'basic_details_view_model.dart';
import 'add_child_dialog.dart';
import '../../models/basic_details.dart';

class BasicDetailsScreen extends StatelessWidget {
  const BasicDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BasicDetailsViewModel>();
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
        title: const Text('මූලික තොරතුරු', style: TextStyle(fontFamily: 'UNSamantha', color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: vm.isBusy 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.red.shade100,
                    width: double.infinity,
                    child: Text(vm.error!, style: const TextStyle(color: Colors.red, fontFamily: 'UNGanganee')),
                  ),
                  
                _buildLabel('ගෘහ මූලික අංකය'),
                TextFormField(
                  initialValue: details.houseNumber,
                  enabled: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildLabel('ගෘහ මූලිකත්වය'),
                Row(
                  children: [
                    const Text('පිරිමි', style: TextStyle(fontFamily: 'UNGanganee')),
                    Checkbox(
                      value: details.headGender == 'පිරිමි', 
                      activeColor: AppColors.primary,
                      onChanged: (val) => vm.updateField(headGender: 'පිරිමි')
                    ),
                    const SizedBox(width: 16),
                    const Text('කාන්තා', style: TextStyle(fontFamily: 'UNGanganee')),
                    Checkbox(
                      value: details.headGender == 'කාන්තා', 
                      activeColor: AppColors.primary,
                      onChanged: (val) => vm.updateField(headGender: 'කාන්තා')
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel('ගෘහ මූලිකයාගේ නම'),
                TextFormField(
                  initialValue: details.headName,
                  onChanged: (val) => vm.updateField(headName: val),
                  decoration: const InputDecoration(hintText: 'නම ඇතුළත් කරන්න'),
                ),
                const SizedBox(height: 16),

                _buildLabel('ජාතික හැඳුනුම්පත් අංකය'),
                TextFormField(
                  initialValue: details.nic,
                  onChanged: (val) => vm.updateField(nic: val),
                  decoration: const InputDecoration(hintText: 'NIC අංකය'),
                ),
                const SizedBox(height: 16),

                _buildLabel('උපන්දිනය'),
                TextFormField(
                  initialValue: details.dob,
                  onChanged: (val) => vm.updateField(dob: val),
                  decoration: const InputDecoration(hintText: 'yyyy-mm-dd'),
                ),
                const SizedBox(height: 16),

                _buildLabel('දුරකථන අංකය'),
                TextFormField(
                  initialValue: details.phone,
                  onChanged: (val) => vm.updateField(phone: val),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                _buildLabel('ඊ මේල්'),
                TextFormField(
                  initialValue: details.email,
                  onChanged: (val) => vm.updateField(email: val),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildLabel('ජාතිය'),
                DropdownButtonFormField<String>(
                  value: details.nationality,
                  decoration: const InputDecoration(filled: true, fillColor: AppColors.fieldFill),
                  items: ['සිංහල', 'දෙමළ', 'මුස්ලිම්'].map((String val) {
                    return DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontFamily: 'UNGanganee')));
                  }).toList(),
                  onChanged: (val) => vm.updateField(nationality: val),
                ),
                const SizedBox(height: 32),

                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text('වයස අවුරුදු (18) ට අඩු දරුවන් පිළිබඳ විස්තර', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue)),
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: true,
                    children: [
                      ...details.children.map((child) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(child.name, style: const TextStyle(fontFamily: 'UNGanganee', fontWeight: FontWeight.bold)),
                        subtitle: Text('උපන්දිනය: ${child.dob} | ${child.gender}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final updatedChild = await showDialog<ChildInfo>(
                                  context: context,
                                  builder: (_) => AddChildDialog(existingChild: child),
                                );
                                if (updatedChild != null) {
                                  vm.updateChild(updatedChild);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => vm.removeChild(child.id),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          onPressed: () async {
                            final newChild = await showDialog<ChildInfo>(
                              context: context,
                              builder: (_) => const AddChildDialog(),
                            );
                            if (newChild != null) {
                              vm.addChild(newChild);
                            }
                          },
                          child: const Text('එකතු කරන්න', style: TextStyle(fontFamily: 'UNSamantha', color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabel('සමාජ විරෝධී ක්‍රියාකාරකම් සිදු කර ඇත්ද නැත්ද'),
                Row(
                  children: [
                    const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee')),
                    Checkbox(
                      value: details.hasAntiSocialActivities, 
                      activeColor: AppColors.primary,
                      onChanged: (val) => vm.updateField(hasAntiSocialActivities: true)
                    ),
                    const SizedBox(width: 16),
                    const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                    Checkbox(
                      value: !details.hasAntiSocialActivities, 
                      activeColor: AppColors.primary,
                      onChanged: (val) => vm.updateField(hasAntiSocialActivities: false)
                    ),
                  ],
                ),
                if (details.hasAntiSocialActivities) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: details.antiSocialDescription,
                    maxLines: 4,
                    onChanged: (val) => vm.updateField(antiSocialDescription: val),
                    decoration: const InputDecoration(hintText: 'විස්තරය මෙහි ලියන්න...'),
                  ),
                ],
                const SizedBox(height: 40),

                Center(
                  child: SizedBox(
                    width: 200,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        final success = await vm.save();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('දත්ත සාර්ථකව සුරැකිණි!')),
                          );
                          Navigator.pushNamed(
                            context, 
                            Routes.housing, 
                            arguments: vm.houseNumber,
                          );
                        }
                      },
                      child: const Text('සුරකින්න', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}