import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import 'basic_details_view_model.dart';
import 'add_member_dialog.dart'; 
import '../../models/basic_details.dart' show FamilyMember, BasicDetails;

class BasicDetailsScreen extends StatefulWidget {
  const BasicDetailsScreen({super.key});

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _antiSocialController;

  @override
  void initState() {
    super.initState();
    final details = context.read<BasicDetailsViewModel>().details;
    _phoneController = TextEditingController(text: details.phone);
    _emailController = TextEditingController(text: details.email);
    _antiSocialController = TextEditingController(text: details.antiSocialDescription);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _antiSocialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BasicDetailsViewModel>();
    final details = vm.details;

    String? currentHeadId;
    try {
      currentHeadId = details.members
          .firstWhere((m) => m.fullName == details.headName && m.nic == details.nic)
          .id;
    } catch (e) {
      currentHeadId = null;
    }

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
          style: TextStyle(fontFamily: 'UNSamantha', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
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
                      color: AppColors.dangerBackground,
                      width: double.infinity,
                      child: Text(vm.error!, style: const TextStyle(color: AppColors.danger, fontFamily: 'UNGanganee')),
                    ),

                  _buildLabel('ගෘහ මූලික අංකය'),
                  TextFormField(
                    initialValue: details.houseNumber,
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  _buildPersonalInfoSection(details, vm),

                  const SizedBox(height: 32),

                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: const Text(
                      'පවුලේ සාමාජිකයන්ගේ විස්තර',
                      style: TextStyle(fontFamily: 'UNSamantha', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.info),
                    ),
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: true,
                    children: [
                      if (details.members.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('සාමාජිකයන් ඇතුළත් කර නොමැත.', style: TextStyle(fontFamily: 'UNGanganee')),
                        ),
                        
                      ...details.members.map((member) {
                        bool isHead = currentHeadId == member.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Radio<String>(
                            value: member.id,
                            groupValue: currentHeadId,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              if (val != null) {
                                vm.updateField(
                                  headName: member.fullName,
                                  nic: member.nic,
                                  headGender: member.gender,
                                  dob: member.dob.split('T')[0],
                                );
                              }
                            },
                          ),
                          title: Text(
                            '${member.fullName} ${member.isAdult ? "(වැඩිහිටි)" : "(ළමා)"}',
                            style: TextStyle(
                              fontFamily: 'UNGanganee', 
                              fontWeight: FontWeight.bold,
                              color: isHead ? AppColors.primary : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'වයස: අවුරුදු ${member.age} | ${member.nic.isNotEmpty ? "NIC: ${member.nic} | " : ""}උපන් දිනය: ${member.dob.split('T')[0]} | ${member.gender}'
                            '${member.hasAntiSocialActivities ? '\n(සමාජ විරෝධී: ${member.antiSocialDescription.isNotEmpty ? member.antiSocialDescription : 'ඇත'})' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.info),
                                onPressed: () async {
                                  final updatedMember = await showDialog<FamilyMember>(
                                    context: context,
                                    builder: (_) => AddMemberDialog(existingMember: member),
                                  );
                                  if (updatedMember != null) {
                                    vm.updateMember(updatedMember);
                                    if (isHead) {
                                      vm.updateField(
                                        headName: updatedMember.fullName,
                                        nic: updatedMember.nic,
                                        headGender: updatedMember.gender,
                                        dob: updatedMember.dob.split('T')[0],
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.danger),
                                onPressed: () {
                                  vm.removeMember(member.id);
                                  if (isHead) {
                                    vm.updateField(headName: '', nic: '', headGender: 'පිරිමි', dob: '');
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          onPressed: () async {
                            final newMember = await showDialog<FamilyMember>(
                              context: context,
                              builder: (_) => const AddMemberDialog(),
                            );
                            if (newMember != null) {
                              vm.addMember(newMember);
                              if (details.members.isEmpty && details.headName.isEmpty) {
                                vm.updateField(
                                  headName: newMember.fullName,
                                  nic: newMember.nic,
                                  headGender: newMember.gender,
                                  dob: newMember.dob.split('T')[0],
                                );
                              }
                            }
                          },
                          child: const Text('සාමාජිකයෙකු එක් කරන්න', style: TextStyle(fontFamily: 'UNSamantha', color: AppColors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('ගෘහ මූලිකයාගේ සමාජ විරෝධී ක්‍රියාකාරකම්'),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: details.hasAntiSocialActivities,
                        activeColor: AppColors.primary,
                        onChanged: (val) => vm.updateField(hasAntiSocialActivities: val),
                      ),
                      const Text('ඇත', style: TextStyle(fontFamily: 'UNGanganee')),
                      const SizedBox(width: 16),
                      Radio<bool>(
                        value: false,
                        groupValue: details.hasAntiSocialActivities,
                        activeColor: AppColors.primary,
                        onChanged: (val) => vm.updateField(hasAntiSocialActivities: val),
                      ),
                      const Text('නැත', style: TextStyle(fontFamily: 'UNGanganee')),
                    ],
                  ),
                  if (details.hasAntiSocialActivities) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _antiSocialController,
                      maxLines: 4,
                      onChanged: (val) => vm.updateField(antiSocialDescription: val),
                      decoration: const InputDecoration(hintText: 'විස්තරය මෙහි ලියන්න...'),
                    ),
                  ],

                  // 🟢 දත්ත යාවත්කාලීන කළ ලොගය (Update Log)
                  if (details.updatedBy != null || details.updatedAt != null)
                    _buildUpdateLog(details.updatedBy, details.updatedAt),

                  const SizedBox(height: 40),

                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                          elevation: 4
                        ),
                        // 🟢 FIX: Buffering ගැටලුව නිරාකරණය කිරීම
                        onPressed: () async {
                          if (details.headName.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('කරුණාකර සාමාජික ලැයිස්තුවෙන් ගෘහ මූලිකයා තෝරන්න!'), backgroundColor: Colors.red)
                             );
                             return;
                          }
                          
                          // Navigator සහ Messenger කලින්ම capture කරගැනීම
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final currentHouseNumber = vm.houseNumber;
                          
                          final success = await vm.save();
                          
                          if (success) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('දත්ත සාර්ථකව සුරැකිණි!'))
                            );
                            navigator.pushNamed(Routes.housing, arguments: currentHouseNumber);
                          }
                        },
                        child: const Text('සුරකින්න', style: TextStyle(fontFamily: 'UNSamantha', fontSize: 22, color: AppColors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 🟢 ලොගය පෙන්වන කොටස
  Widget _buildUpdateLog(String? updatedBy, DateTime? updatedAt) {
    final dateStr = updatedAt != null 
        ? "${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}  |  ${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')}" 
        : "නොදන්නා දිනයකි";
        
    return Container(
      margin: const EdgeInsets.only(top: 32),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.blueGrey.shade700),
              const SizedBox(width: 8),
              Text('දත්ත යාවත්කාලීන ලොගය', style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          Text('අවසන් වරට වෙනස් කළේ: ${updatedBy ?? "පද්ධතිය මගින්"}', style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
          const SizedBox(height: 4),
          Text('දිනය සහ වේලාව: $dateStr', style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(BasicDetails details, BasicDetailsViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldFill, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ගෘහ මූලිකයාගේ විස්තර', style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          
          if (details.headName.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text(
                'කරුණාකර පහත සාමාජික ලැයිස්තුවෙන් ගෘහ මූලිකයාව තෝරන්න (Radio Button එක ක්ලික් කරන්න).', 
                style: TextStyle(color: Colors.red, fontFamily: 'UNGanganee', fontWeight: FontWeight.bold)
              ),
            )
          else ...[
            _buildViewRow('නම:', details.headName),
            _buildViewRow('ස්ත්‍රී/පුරුෂ භාවය:', details.headGender),
            _buildViewRow('ජා.හැ. අංකය:', details.nic),
            _buildViewRow('උපන් දිනය:', details.dob),
          ],
          
          const Divider(height: 24),
          
          _buildLabel('දුරකථන අංකය'),
          TextFormField(
            controller: _phoneController,
            onChanged: (val) => vm.updateField(phone: val), 
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'දුරකථන අංකය ඇතුළත් කරන්න')
          ),
          const SizedBox(height: 16),
          
          _buildLabel('ඊමේල් ලිපිනය'),
          TextFormField(
            controller: _emailController,
            onChanged: (val) => vm.updateField(email: val), 
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'ඊමේල් ලිපිනයක් ඇත්නම් ඇතුළත් කරන්න')
          ),
          const SizedBox(height: 16),
          
          _buildLabel('ජාතිය'),
          DropdownButtonFormField<String>(
            value: details.nationality.isNotEmpty ? details.nationality : null,
            decoration: const InputDecoration(filled: true, fillColor: AppColors.fieldFill),
            items: ['සිංහල', 'දෙමළ', 'මුස්ලිම්'].map((String val) {
              return DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontFamily: 'UNGanganee')));
            }).toList(),
            onChanged: (val) {
              if (val != null) vm.updateField(nationality: val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'UNGanganee'))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'UNGanganee'))),
        ],
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