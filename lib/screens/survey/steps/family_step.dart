import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/app_theme.dart';
import '../survey_view_model.dart';
import '../../../models/survey.dart';

class FamilyStep extends StatefulWidget {
  const FamilyStep({super.key});

  @override
  State<FamilyStep> createState() => _FamilyStepState();
}

class _FamilyStepState extends State<FamilyStep> {
  static String _lastSearchedHouseNumber = '';

  final _houseNumberCtrl = TextEditingController();
  final _specialCountCtrl = TextEditingController();
  final _specialAmountCtrl = TextEditingController();
  final _specialDescCtrl = TextEditingController(); 
  
  final _aswasumaAmountCtrl = TextEditingController();
  String? _aswasumaCategory;
  
  bool _isEditingSpecialNeeds = false; 

  // Location Data Variables
  bool _isLoadingLocation = true;
  String? _selectedGnDivision;
  String? _localAuthority;
  
  List<Map<String, dynamic>> _authoritiesList = [];
  List<String> _gnDivisionsList = [];

  final List<String> _aswasumaCategories = [
    'දුප්පත්',
    'අන්ත දුප්පත්',
    'අවදානම් සහගත පවුල්',
    'සංක්‍රාන්තික පවුල්'
  ];

  @override
  void initState() {
    super.initState();
    _specialCountCtrl.addListener(_updateSpecialNeeds);
    _specialAmountCtrl.addListener(_updateSpecialNeeds);
    _specialDescCtrl.addListener(_updateSpecialNeeds);
    
    _aswasumaAmountCtrl.addListener(_updateAswasumaDetails);

    final currentHouseNumber = context.read<SurveyViewModel>().survey.houseNumber;
    if (_lastSearchedHouseNumber.isNotEmpty) {
      _houseNumberCtrl.text = _lastSearchedHouseNumber;
    } else if (currentHouseNumber.isNotEmpty) {
      _houseNumberCtrl.text = currentHouseNumber;
    }

    _houseNumberCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _houseNumberCtrl.text.length),
    );

    // Fetch user profile location data
    _loadUserLocationData();
  }

  Future<void> _loadUserLocationData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      final authSnapshot = await FirebaseFirestore.instance.collection('local_authorities').get();
      _authoritiesList = authSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name_en': data['name_en'] ?? doc.id,
          'name_si': data['name_si'] ?? '',
          'gn_divisions': data['gn_divisions'] ?? [],
        };
      }).toList();

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String? userAuth;
      String? userGn;

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        userAuth = data['local_authority']?.toString();
        userGn = data['gn_division']?.toString();
      }

      if (mounted) {
        if (userAuth != null && userAuth.isNotEmpty) {
          bool exists = _authoritiesList.any((a) => a['name_en'] == userAuth);
          if (exists) {
            _localAuthority = userAuth;
          } else if (_authoritiesList.isNotEmpty) {
            _localAuthority = _authoritiesList.first['name_en'];
          }
        } else if (_authoritiesList.isNotEmpty) {
          _localAuthority = _authoritiesList.first['name_en'];
        }

        _updateGnListForAuthority(_localAuthority);

        if (userGn != null && userGn.isNotEmpty) {
          if (!_gnDivisionsList.contains(userGn)) {
            _gnDivisionsList.add(userGn); 
          }
          _selectedGnDivision = userGn;
        } else if (_gnDivisionsList.isNotEmpty) {
          _selectedGnDivision = _gnDivisionsList.first;
        }

        _gnDivisionsList = _gnDivisionsList.toSet().toList();

        setState(() {
          _isLoadingLocation = false;
        });

        // Push initial load directly into ViewModel so it doesn't default to empty string
        Future.microtask(() {
          if (mounted) {
            context.read<SurveyViewModel>().updateLocation(_localAuthority, _selectedGnDivision);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user location: $e');
      if (mounted) setState(() => _isLoadingLocation = false);
    } 
  }

  void _updateGnListForAuthority(String? authName) {
    if (authName == null) {
      _gnDivisionsList = [];
      return;
    }
    
    final authMap = _authoritiesList.firstWhere(
      (element) => element['name_en'] == authName,
      orElse: () => <String, dynamic>{}, 
    );

    if (authMap.isNotEmpty) {
      final gnList = authMap['gn_divisions'] as List<dynamic>? ?? [];
      _gnDivisionsList = gnList.map((gn) => gn['en'].toString()).toList();
    } else {
      _gnDivisionsList = [];
    }
  }

  void _updateSpecialNeeds() {
    if (!mounted) return;
    final countText = _specialCountCtrl.text.trim();
    final amountText = _specialAmountCtrl.text.trim();
    final descText = _specialDescCtrl.text.trim();
    
    final count = countText.isEmpty ? 0 : (int.tryParse(countText) ?? 0);
    final amount = amountText.isEmpty ? 0.0 : (double.tryParse(amountText) ?? 0.0);
    
    context.read<SurveyViewModel>().updateSpecialNeeds(count, amount, descText);
  }

  void _updateAswasumaDetails() {
    if (!mounted) return;
  }

  // 🟢 THIS IS THE CRITICAL FIX: IT PREVENTS THE SEARCH FROM ERASING THE LOCATION
  Future<void> _handleSearch([String? query]) async {
    final text = (query ?? _houseNumberCtrl.text).trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();

    _lastSearchedHouseNumber = text;
    _houseNumberCtrl.text = text;
    _houseNumberCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _houseNumberCtrl.text.length),
    );

    final vm = context.read<SurveyViewModel>();
    await vm.searchHouse(text);
    
    if (mounted) {
      setState(() {
        _isEditingSpecialNeeds = false;
        
        // 1. If the database already had a saved location, update the Dropdowns to show it!
        if (vm.survey.family.localAuthority.isNotEmpty) {
          _localAuthority = vm.survey.family.localAuthority;
          _updateGnListForAuthority(_localAuthority);
          
          if (vm.survey.family.gnDivision.isNotEmpty && _gnDivisionsList.contains(vm.survey.family.gnDivision)) {
            _selectedGnDivision = vm.survey.family.gnDivision;
          } else if (_gnDivisionsList.isNotEmpty) {
             _selectedGnDivision = _gnDivisionsList.first;
             vm.updateLocation(_localAuthority, _selectedGnDivision);
          }
        } else {
          // 2. If the database was empty, push the UI dropdown values back into the ViewModel!
          vm.updateLocation(_localAuthority, _selectedGnDivision);
        }
      });
    }
  }

  @override
  void dispose() {
    _houseNumberCtrl.dispose();
    _specialCountCtrl.dispose();
    _specialAmountCtrl.dispose();
    _specialDescCtrl.dispose();
    _aswasumaAmountCtrl.dispose();
    super.dispose();
  }

  int _calculateAgeFromNIC(String nic, int defaultAge) {
    if (nic.trim().isEmpty) return defaultAge;

    final currentYear = DateTime.now().year;
    final cleanNic = nic.trim().toUpperCase();

    if (cleanNic.length == 10 && (cleanNic.endsWith('V') || cleanNic.endsWith('X'))) {
      final yearStr = cleanNic.substring(0, 2);
      final birthYear = int.tryParse(yearStr);
      if (birthYear != null) {
        return currentYear - (1900 + birthYear);
      }
    } 
    else if (cleanNic.length == 12) {
      final yearStr = cleanNic.substring(0, 4);
      final birthYear = int.tryParse(yearStr);
      if (birthYear != null) {
        return currentYear - birthYear;
      }
    }
    
    return defaultAge;
  }

  Widget _buildSpecialNeedsSection(FamilyInfo family) {
    final hasData = family.specialNeedsCount > 0 || 
                    family.specialNeedsAmount > 0 || 
                    family.specialNeedDescription.isNotEmpty;

    if (hasData && !_isEditingSpecialNeeds) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('විශේෂ අවශ්‍යතා සහිත සාමාජිකයන්', style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () {
                  _specialCountCtrl.text = family.specialNeedsCount > 0 ? family.specialNeedsCount.toString() : '';
                  _specialAmountCtrl.text = family.specialNeedsAmount > 0 ? family.specialNeedsAmount.toString() : '';
                  _specialDescCtrl.text = family.specialNeedDescription;
                  setState(() => _isEditingSpecialNeeds = true);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
               color: AppColors.fieldFill,
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                     Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                             const Text('ගණන', style: TextStyle(fontSize: 13, color: Colors.black54)),
                             const SizedBox(height: 4),
                             Text(family.specialNeedsCount.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                         ],
                     ),
                     Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                             const Text('මුදල (රුපියල්)', style: TextStyle(fontSize: 13, color: Colors.black54)),
                             const SizedBox(height: 4),
                             Text(family.specialNeedsAmount.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                         ],
                     )
                 ]
             )
          ),
          if (family.specialNeedDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'අවශ්‍යතාවය: ${family.specialNeedDescription}', 
              style: const TextStyle(fontSize: 14, color: Colors.black54)
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('විශේෂ අවශ්‍යතා සහිත සාමාජිකයන්', style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16)),
            if (hasData) 
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green, size: 20),
                onPressed: () => setState(() => _isEditingSpecialNeeds = false),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _specialCountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ගණන', hintText: '0'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _specialAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'මුදල (රුපියල්)', hintText: '0.00'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _specialDescCtrl,
          decoration: const InputDecoration(
            labelText: 'විශේෂ අවශ්‍යතාවය කුමක්ද? (විකල්ප)', 
            hintText: 'උදා: ආබාධිත / නිදන්ගත රෝග',
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateLog(String? updatedBy, DateTime? updatedAt) {
    if (updatedBy == null && updatedAt == null) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'මෙම ගෙදරට අදාළව මින් පෙර කිසිදු තොරතුරක් පද්ධතියට ඇතුළත් කර නොමැත. මෙය නව ඇතුළත් කිරීමකි.',
                style: TextStyle(fontFamily: 'UNGanganee', fontSize: 14, color: Colors.green.shade900),
              ),
            ),
          ],
        ),
      );
    }

    final dateStr = updatedAt != null 
        ? "${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}  |  ${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')}" 
        : "නොදන්නා දිනයකි";
        
    return Container(
      margin: const EdgeInsets.only(top: 24),
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
          Text('අවසන් වරට වෙනස් කළේ: $updatedBy', style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
          const SizedBox(height: 4),
          Text('දිනය සහ වේලාව: $dateStr', style: const TextStyle(fontFamily: 'UNGanganee', fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(SurveyViewModel vm) {
    if (_isLoadingLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'දත්ත රැස් කරන වසම (Location)',
                style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _localAuthority,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'පළාත් පාලන ආයතනය (Local Authority)',
              filled: true,
              fillColor: AppColors.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            hint: const Text('ආයතනය තෝරන්න', style: TextStyle(color: Colors.black54)),
            items: _authoritiesList.map((auth) {
              final nameEn = auth['name_en']?.toString() ?? '';
              final nameSi = auth['name_si']?.toString() ?? '';
              final displayName = nameSi.isNotEmpty ? '$nameSi ($nameEn)' : nameEn;
              return DropdownMenuItem<String>(
                value: nameEn,
                child: Text(displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'UNGanganee')),
              );
            }).toList(),
            onChanged: (String? val) {
              setState(() {
                _localAuthority = val;
                
                _updateGnListForAuthority(val);
                
                if (_gnDivisionsList.isNotEmpty) {
                  _selectedGnDivision = _gnDivisionsList.first;
                } else {
                  _selectedGnDivision = null;
                }
                
                _gnDivisionsList = _gnDivisionsList.toSet().toList();
              });
              
              context.read<SurveyViewModel>().updateLocation(_localAuthority, _selectedGnDivision);
            },
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedGnDivision,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'ග්‍රාම නිලධාරී වසම (GN Division)',
              filled: true,
              fillColor: AppColors.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            hint: const Text('වසම තෝරන්න', style: TextStyle(color: Colors.black54)),
            items: _gnDivisionsList.map((gn) {
              return DropdownMenuItem<String>(
                value: gn,
                child: Text(gn, style: const TextStyle(fontFamily: 'UNGanganee')),
              );
            }).toList(),
            onChanged: (String? val) {
              setState(() {
                _selectedGnDivision = val;
              });
              
              context.read<SurveyViewModel>().updateLocation(_localAuthority, val);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SurveyViewModel>();
    final survey = vm.survey;
    final family = survey.family;
    final members = family.members;
    
    final adults = members.where((m) => m.isAdult).toList();
    final children = members.where((m) => !m.isAdult).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ගෘහ මූලික අංකය',
              style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 45, 
                child: TextField(
                  controller: _houseNumberCtrl,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'අංකය',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding: const EdgeInsets.only(left: 10), 
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: AppColors.primary),
                      onPressed: () => _handleSearch(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black54, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (value) => _handleSearch(value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        if (vm.isBusy)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),

        if (!vm.isBusy && survey.houseNumber.isNotEmpty) ...[
          
          _buildUpdateLog(survey.updatedBy, survey.updatedAt),
          const SizedBox(height: 24),

          _buildLocationCard(vm),
          const SizedBox(height: 24),

          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'අස්වැසුම ප්‍රතිලාභ',
                      style: TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Text(
                          family.hasAswasuma ? 'ඇත' : 'නැත',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: family.hasAswasuma ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: family.hasAswasuma,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            context.read<SurveyViewModel>().toggleAswasuma(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (family.hasAswasuma) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _aswasumaCategory,
                    decoration: InputDecoration(
                      labelText: 'අස්වැසුම කාණ්ඩය (විකල්ප)',
                      filled: true,
                      fillColor: AppColors.fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    items: _aswasumaCategories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category, style: const TextStyle(fontFamily: 'UNGanganee')),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _aswasumaCategory = newValue;
                      });
                      _updateAswasumaDetails();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aswasumaAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ලබාදෙන මුදල (විකල්ප)',
                      hintText: 'රු: 0.00',
                      filled: true,
                      fillColor: AppColors.fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),
                _buildSpecialNeedsSection(family),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('වැඩිහිටි සාමාජිකයන් (අවු: 18 ට වැඩි)'),
          const SizedBox(height: 12),
          if (adults.isEmpty)
            const Text('දත්ත නොමැත', style: TextStyle(color: Colors.grey)),
          ...adults.map((m) => _buildMemberTile(context, m)),
          
          const SizedBox(height: 24),

          _buildSectionTitle('ළමා සාමාජිකයන් (අවු: 18 ට අඩු)'),
          const SizedBox(height: 12),
          if (children.isEmpty)
            const Text('දත්ත නොමැත', style: TextStyle(color: Colors.grey)),
          ...children.map((m) => _buildMemberTile(context, m)),

          const SizedBox(height: 32),

          _buildCard(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'පවුල පිළිබඳ තවත් තොරතුරු ඇතුලත් කිරීමට හෝ යාවත්කාලීන කිරීමට ඉදිරියට යන්න.',
                style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontFamily: 'UNSamantha', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildMemberTile(BuildContext context, FamilyMember member) {
    final displayAge = _calculateAgeFromNIC(member.nic, member.age);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            member.gender == 'ස්ත්‍රී' ? Icons.face_3 : Icons.face,
            color: AppColors.primary,
          ),
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('වයස: $displayAge | NIC: ${member.nic.isEmpty ? "-" : member.nic}', style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}