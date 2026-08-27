import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Ensure these paths match your actual project structure
import 'package:lankalink/data/auth_repository.dart';
import 'package:lankalink/screens/auth/login_screen.dart';
import 'package:lankalink/screens/auth/login_view_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingDropdownData = true;

  // Selected Values to be saved in the database (English)
  final String _selectedDistrictEn = 'Matara';
  String? _selectedLocalAuthorityEn;
  String? _selectedGNEn;

  // Selected Values for UI display (Sinhala)
  final String _selectedDistrictSi = 'මාතර';
  String? _selectedLocalAuthoritySi;
  String? _selectedGNSi;

  // Dynamically loaded from Cloud Firestore
  List<Map<String, String>> _localAuthorities = [];
  Map<String, List<Map<String, String>>> _gnDivisionsData = {};
  List<Map<String, String>> _currentGNDivisions = [];

  @override
  void initState() {
    super.initState();
    _fetchAdministrativeDataFromFirestore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Fetches Local Authorities and GN Divisions dynamically from Firestore
  Future<void> _fetchAdministrativeDataFromFirestore() async {
    setState(() => _isLoadingDropdownData = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('local_authorities')
          .where('district_en', isEqualTo: _selectedDistrictEn)
          .get();

      final List<Map<String, String>> laList = [];
      final Map<String, List<Map<String, String>>> gnMap = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String enName = (data['name_en'] ?? '').toString();
        final String siName = (data['name_si'] ?? '').toString();

        if (enName.isNotEmpty) {
          laList.add({
            'en': enName,
            'si': siName.isNotEmpty ? siName : enName,
          });

          final rawGNDivisions = data['gn_divisions'];
          if (rawGNDivisions is List) {
            final List<Map<String, String>> parsedGN = [];
            for (var item in rawGNDivisions) {
              if (item is Map) {
                parsedGN.add({
                  'en': (item['en'] ?? '').toString(),
                  'si': (item['si'] ?? item['en'] ?? '').toString(),
                });
              }
            }
            gnMap[enName] = parsedGN;
          } else {
            gnMap[enName] = [];
          }
        }
      }

      // Sort alphabetically
      laList.sort((a, b) => a['si']!.compareTo(b['si']!));

      if (mounted) {
        setState(() {
          _localAuthorities = laList;
          _gnDivisionsData = gnMap;
          _isLoadingDropdownData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDropdownData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'දත්ත පූරණය කිරීමේ දෝෂයක් මතු විය: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _signUpUser() async {
    String name = _nameController.text.trim();
    String nic = _nicController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        nic.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        _selectedLocalAuthorityEn == null ||
        _selectedGNEn == null ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර සියලුම ක්ෂේත්‍ර පුරවන්න.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ඔබ ඇතුළත් කළ මුරපදයන් නොගැලපේ.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': name,
        'nic': nic,
        'email': email,
        'phone': phone,
        'district': _selectedDistrictEn,
        'local_authority': _selectedLocalAuthorityEn,
        'gn_division': _selectedGNEn,
        'role': 'data collector',
        'createdAt': DateTime.now(),
        'isActive': false,
      });

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ලියාපදිංචිය සාර්ථකයි! ඔබගේ ගිණුම පරිපාලක විසින් අනුමත කළ පසු ඔබට ඇතුල් විය හැක.',
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (context) => LoginViewModel(
                AuthRepository(
                  FirebaseAuth.instance,
                  FirebaseFirestore.instance,
                ),
              ),
              child: const LoginScreen(),
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'දෝෂයක් මතු විය.';
      if (e.code == 'weak-password') {
        errorMessage = 'මුරපදය ඉතා දුර්වලයි (අවම අකුරු/ඉලක්කම් 6ක් අවශ්යයි).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'මෙම Email ලිපිනය දැනටමත් ලියාපදිංචි කර ඇත.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'ඔබ ඇතුළත් කළ Email ලිපිනය වැරදියි.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('අනපේක්ෂිත දෝෂයක් මතු විය.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'UNSamantha',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          obscureText: isPassword
              ? _obscurePassword
              : (isConfirmPassword ? _obscureConfirmPassword : false),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade100,
            suffixIcon: isPassword || isConfirmPassword
                ? IconButton(
                    icon: Icon(
                      (isPassword ? _obscurePassword : _obscureConfirmPassword)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.lightBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPassword) {
                          _obscurePassword = !_obscurePassword;
                        } else {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }
                      });
                    },
                  )
                : Icon(icon, color: Colors.lightBlue.shade200),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSearchableField({
    required String label,
    required String hint,
    required IconData icon,
    required List<Map<String, String>> options,
    required void Function(Map<String, String>) onSelected,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'UNSamantha',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<Map<String, String>>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return options;
            }
            return options.where((Map<String, String> option) {
              final siMatch = option['si']!
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
              final enMatch = option['en']!
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
              return siMatch || enMatch;
            });
          },
          displayStringForOption: (Map<String, String> option) =>
              option['si']!,
          onSelected: onSelected,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor:
                    enabled ? Colors.grey.shade100 : Colors.grey.shade200,
                suffixIcon: Icon(icon, color: Colors.lightBlue.shade200),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(15),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option['si']!,
                          style: const TextStyle(fontFamily: 'UNSamantha'),
                        ),
                        subtitle: Text(
                          option['en']!,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ලියාපදිංචි වන්න',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                  'නම', 'ඔබගේ නම', Icons.person_outline, _nameController),
              _buildTextField(
                  'ජා.හැ. අංකය', 'ජා.හැ. අංකය', Icons.badge_outlined, _nicController),
              _buildTextField(
                  'ඊමේල්', 'ඊමේල් ලිපිනය', Icons.email_outlined, _emailController),
              _buildTextField(
                  'දුරකථන', 'දුරකථන අංකය', Icons.phone_in_talk_outlined, _phoneController),

              // District Field
              _buildTextField(
                'දිස්ත්‍රික්කය',
                'මාතර',
                Icons.location_city_outlined,
                TextEditingController(text: 'මාතර ($_selectedDistrictEn)'),
                readOnly: true,
              ),

              // Searchable Local Authority (Loaded from DB)
              if (_isLoadingDropdownData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                _buildSearchableField(
                  label: 'පළාත් පාලන ආයතනය (සොයන්න)',
                  hint: _localAuthorities.isEmpty
                      ? 'පළාත් පාලන ආයතන දත්ත නොමැත (Admin විසින් ඇතුළත් කළ යුතුය)'
                      : 'ප්‍රාදේශීය/නගර සභාව ටයිප් කර තෝරන්න',
                  icon: Icons.account_balance_outlined,
                  options: _localAuthorities,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLocalAuthoritySi = selected['si'];
                      _selectedLocalAuthorityEn = selected['en'];
                      _selectedGNSi = null;
                      _selectedGNEn = null;
                      _currentGNDivisions =
                          _gnDivisionsData[_selectedLocalAuthorityEn!] ?? [];
                    });
                  },
                ),

              // Searchable GN Division (Filtered from DB)
              _buildSearchableField(
                label: 'ග්‍රාම නිලධාරී වසම (සොයන්න)',
                hint: _selectedLocalAuthoritySi == null
                    ? 'පළමුව පළාත් පාලන ආයතනය තෝරන්න'
                    : 'වසමේ නම හෝ අංකය ටයිප් කරන්න',
                icon: Icons.map_outlined,
                options: _currentGNDivisions,
                enabled: _selectedLocalAuthoritySi != null,
                onSelected: (selected) {
                  setState(() {
                    _selectedGNSi = selected['si'];
                    _selectedGNEn = selected['en'];
                  });
                },
              ),

              _buildTextField(
                'මුරපදය',
                'මුරපදය',
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),
              _buildTextField(
                'මුරපදය නැවත',
                'මුරපදය',
                Icons.lock_outline,
                _confirmPasswordController,
                isConfirmPassword: true,
              ),

              const SizedBox(height: 24),

              // Register Button
              Container(
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.blue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUpUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ලියාපදිංචි වන්න',
                          style: TextStyle(
                            fontFamily: 'UNSamantha',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ගිණුමක් සාදා තිබේද? ',
                      style: TextStyle(fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'ලොග් වන්න',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}