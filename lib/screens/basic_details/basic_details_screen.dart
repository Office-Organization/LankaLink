import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'basic_details_view_model.dart';
import 'add_child_dialog.dart';
import 'add_other_member_dialog.dart';
import '../../models/basic_details.dart' show OtherMemberInfo, ChildInfo, BasicDetails;

class BasicDetailsScreen extends StatefulWidget {
  const BasicDetailsScreen({super.key});

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  // මූලික තොරතුරු සංස්කරණය කරනවාද යන්න තීරණය කරන State variable එක
  bool _isEditingPersonalInfo = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BasicDetailsViewModel>();
    final details = vm.details;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.lightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'මූලික තොරතුරු',
          style: TextStyle(
            fontFamily: 'UNSamantha',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: vm.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message display area
                  if (vm.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      color: AppColors.dangerBackground,
                      width: double.infinity,
                      child: Text(
                        vm.error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontFamily: 'UNGanganee',
                        ),
                      ),
                    ),

                  _buildLabel('ගෘහ මූලික අංකය'),
                  TextFormField(
                    initialValue: details.houseNumber,
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // නව View/Edit ලොජික් එක ඇතුළත් කළ මූලික තොරතුරු කොටස
                  _buildPersonalInfoSection(details, vm),

                  const SizedBox(height: 32),

                  // Section: Manage children details (under 18 years of age)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text(
                        'වයස අවුරුදු (18) ට අඩු දරුවන් පිළිබඳ විස්තර',
                        style: TextStyle(
                          fontFamily: 'UNSamantha',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      initiallyExpanded: true,
                      children: [
                        ...details.children.map(
                          (child) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${child.name} ${vm.getCategoryLabel(child.dob)}',
                              style: const TextStyle(
                                fontFamily: 'UNGanganee',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'වයස: අවුරුදු ${vm.getAge(child.dob)} | උපන් දිනය: ${child.dob} | ${child.gender}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.info),
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
                                  icon: const Icon(Icons.delete, color: AppColors.danger),
                                  onPressed: () => vm.removeChild(child.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                            child: const Text(
                              'එකතු කරන්න',
                              style: TextStyle(
                                fontFamily: 'UNSamantha',
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Manage other adult family members (over 18 years of age)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text(
                        'වෙනත් පවුලේ සාමාජිකයන් (අවු: 18 ට වැඩි)',
                        style: TextStyle(
                          fontFamily: 'UNSamantha',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      initiallyExpanded: true,
                      children: [
                        ...details.otherMembers.map(
                          (member) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${member.name ?? 'Unknown'} ${member.dateOfBirth != null && member.dateOfBirth!.isNotEmpty ? vm.getCategoryLabel(member.dateOfBirth!) : ''}',
                              style: const TextStyle(
                                fontFamily: 'UNGanganee',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'NIC: ${member.nic ?? '-'} | ${member.gender ?? '-'} | වයස: ${member.dateOfBirth != null && member.dateOfBirth!.isNotEmpty ? vm.getAge(member.dateOfBirth!).toString() : '-'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.info),
                                  onPressed: () async {
                                    final updatedMember = await showDialog<OtherMemberInfo>(
                                      context: context,
                                      builder: (_) => AddOtherMemberDialog(existingMember: member),
                                    );
                                    if (updatedMember != null) {
                                      vm.updateOtherMember(updatedMember);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.danger),
                                  onPressed: () => vm.removeOtherMember(member.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final newMember = await showDialog<OtherMemberInfo>(
                                context: context,
                                builder: (_) => const AddOtherMemberDialog(),
                              );
                              if (newMember != null) {
                                vm.addOtherMember(newMember);
                              }
                            },
                            child: const Text(
                              'සාමාජිකයෙකු එක් කරන්න',
                              style: TextStyle(
                                fontFamily: 'UNSamantha',
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('සමාජ විරෝධී ක්‍රියාකාරකම් සිදු කර ඇත්ද?'),
                  Row(
                    children: [
                      const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee')),
                      Checkbox(
                        value: details.hasAntiSocialActivities,
                        activeColor: AppColors.primary,
                        onChanged: (val) => vm.updateField(hasAntiSocialActivities: true),
                      ),
                      const SizedBox(width: 16),
                      const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                      Checkbox(
                        value: !details.hasAntiSocialActivities,
                        activeColor: AppColors.primary,
                        onChanged: (val) => vm.updateField(hasAntiSocialActivities: false),
                      ),
                    ],
                  ),
                  if (details.hasAntiSocialActivities) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: details.antiSocialDescription,
                      maxLines: 4,
                      onChanged: (val) => vm.updateField(antiSocialDescription: val),
                      decoration: const InputDecoration(
                        hintText: 'විස්තරය මෙහි ලියන්න...',
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // Submit Data Button
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          final success = await vm.save();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('දත්ත සාර්ථකව සුරැකිණි!')),
                            );
                            Navigator.pushNamed(context, Routes.housing, arguments: vm.houseNumber);
                          }
                        },
                        child: const Text(
                          'සුරකින්න',
                          style: TextStyle(
                            fontFamily: 'UNSamantha',
                            fontSize: 22,
                            color: AppColors.white,
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

  // View Mode සහ Edit Mode පාලනය කරන ප්‍රධාන කොටස
  Widget _buildPersonalInfoSection(BasicDetails details, BasicDetailsViewModel vm) {
    // දත්ත දැනටමත් ඇතුළත් කර ඇත්දැයි බැලීම
    final hasData = details.headName.isNotEmpty || details.nic.isNotEmpty || details.phone.isNotEmpty;

    // View Mode (දත්ත පෙන්වන කොටුව)
    if (hasData && !_isEditingPersonalInfo) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ගෘහ මූලිකයාගේ විස්තර',
                  style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => setState(() => _isEditingPersonalInfo = true),
                ),
              ],
            ),
            const Divider(),
            _buildViewRow('නම:', details.headName),
            _buildViewRow('ස්ත්‍රී/පුරුෂ භාවය:', details.headGender),
            _buildViewRow('ජා.හැ. අංකය:', details.nic),
            _buildViewRow('උපන් දිනය:', details.dob),
            _buildViewRow('දුරකථන:', details.phone),
            _buildViewRow('ඊමේල්:', details.email),
            _buildViewRow('ජාතිය:', details.nationality),
          ],
        ),
      );
    }

    // Edit Mode (දත්ත වෙනස් කරන TextFields)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ගෘහ මූලිකයාගේ විස්තර ඇතුළත් කරන්න',
              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (hasData)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green, size: 24),
                onPressed: () => setState(() => _isEditingPersonalInfo = false),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('ගෘහ මූලිකත්වය'),
        Row(
          children: [
            const Text('පිරිමි', style: TextStyle(fontFamily: 'UNGanganee')),
            Checkbox(
              value: details.headGender == 'පිරිමි',
              activeColor: AppColors.primary,
              onChanged: (val) => vm.updateField(headGender: 'පිරිමි'),
            ),
            const SizedBox(width: 16),
            const Text('කාන්තා', style: TextStyle(fontFamily: 'UNGanganee')),
            Checkbox(
              value: details.headGender == 'කාන්තා',
              activeColor: AppColors.primary,
              onChanged: (val) => vm.updateField(headGender: 'කාන්තා'),
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
        _buildLabel('උපන් දිනය'),
        GestureDetector(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: details.dob.isNotEmpty ? (DateTime.tryParse(details.dob) ?? DateTime.now()) : DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null) {
              final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
              vm.updateField(dob: formattedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textDisabled),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  details.dob.isNotEmpty ? details.dob : 'උපන් දිනය තෝරන්න',
                  style: TextStyle(
                    fontFamily: 'UNGanganee',
                    color: details.dob.isEmpty ? AppColors.textDisabled : AppColors.textSecondary,
                  ),
                ),
                const Icon(Icons.calendar_today, color: AppColors.info, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('දුරකථන අංකය'),
        TextFormField(
          initialValue: details.phone,
          onChanged: (val) => vm.updateField(phone: val),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildLabel('ඊමේල් ලිපිනය'),
        TextFormField(
          initialValue: details.email,
          onChanged: (val) => vm.updateField(email: val),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildLabel('ජාතිය'),
        DropdownButtonFormField<String>(
          initialValue: details.nationality,
          decoration: const InputDecoration(filled: true, fillColor: AppColors.fieldFill),
          items: ['සිංහල', 'දෙමළ', 'මුස්ලිම්'].map((String val) {
            return DropdownMenuItem(
              value: val,
              child: Text(val, style: const TextStyle(fontFamily: 'UNGanganee')),
            );
          }).toList(),
          onChanged: (val) => vm.updateField(nationality: val),
        ),
      ],
    );
  }

  // View Mode එකේ පේළි පෙන්වීමට සරල Widget එකක්
  Widget _buildViewRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // Helper widget to construct standard labels
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'UNSamantha',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}