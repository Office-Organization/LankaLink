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

  // Values for UI display (Sinhala)
  String? _selectedDistrictSi;
  String? _selectedTownSi;

  // Values to be saved in the database (English)
  String? _selectedDistrictEn;
  String? _selectedTownEn;

  List<Map<String, String>> _towns = [];

  final List<Map<String, String>> _districts = [
    {'si': 'අම්පාර', 'en': 'Ampara'},
    {'si': 'අනුරාධපුර', 'en': 'Anuradhapura'},
    {'si': 'බදුල්ල', 'en': 'Badulla'},
    {'si': 'මඩකලපුව', 'en': 'Batticaloa'},
    {'si': 'කොළඹ', 'en': 'Colombo'},
    {'si': 'ගාල්ල', 'en': 'Galle'},
    {'si': 'ගම්පහ', 'en': 'Gampaha'},
    {'si': 'හම්බන්තොට', 'en': 'Hambantota'},
    {'si': 'යාපනය', 'en': 'Jaffna'},
    {'si': 'කළුතර', 'en': 'Kalutara'},
    {'si': 'මහනුවර', 'en': 'Kandy'},
    {'si': 'කෑගල්ල', 'en': 'Kegalle'},
    {'si': 'කිලිනොච්චි', 'en': 'Kilinochchi'},
    {'si': 'කුරුණෑගල', 'en': 'Kurunegala'},
    {'si': 'මන්නාරම', 'en': 'Mannar'},
    {'si': 'මාතලේ', 'en': 'Matale'},
    {'si': 'මාතර', 'en': 'Matara'},
    {'si': 'මොණරාගල', 'en': 'Monaragala'},
    {'si': 'මුලතිව්', 'en': 'Mullaitivu'},
    {'si': 'නුවර එළිය', 'en': 'Nuwara Eliya'},
    {'si': 'පොළොන්නරුව', 'en': 'Polonnaruwa'},
    {'si': 'පුත්තලම', 'en': 'Puttalam'},
    {'si': 'රත්නපුර', 'en': 'Ratnapura'},
    {'si': 'ත්‍රිකුණාමලය', 'en': 'Trincomalee'},
    {'si': 'වවුනියාව', 'en': 'Vavuniya'},
  ];

  final Map<String, List<Map<String, String>>> _townsData = {
    'Ampara': [
      {'si': 'අම්පාර', 'en': 'Ampara'},
      {'si': 'අක්කරපත්තුව', 'en': 'Akkaraipattu'},
      {'si': 'කල්මුනේ', 'en': 'Kalmunai'},
      {'si': 'සයින්දමරුදු', 'en': 'Sainthamaruthu'},
    ],
    'Anuradhapura': [
      {'si': 'අනුරාධපුර', 'en': 'Anuradhapura'},
      {'si': 'කැකිරාව', 'en': 'Kekirawa'},
      {'si': 'මැදවච්චිය', 'en': 'Medawachchiya'},
      {'si': 'තඹුත්තේගම', 'en': 'Thambuttegama'},
    ],
    'Badulla': [
      {'si': 'බදුල්ල', 'en': 'Badulla'},
      {'si': 'බණ්ඩාරවෙල', 'en': 'Bandarawela'},
      {'si': 'හපුතලේ', 'en': 'Haputale'},
      {'si': 'වැලිමඩ', 'en': 'Welimada'},
    ],
    'Batticaloa': [
      {'si': 'මඩකලපුව', 'en': 'Batticaloa'},
      {'si': 'කාත්තන්කුඩි', 'en': 'Kattankudy'},
      {'si': 'එරාවුර්', 'en': 'Eravur'},
    ],
    'Colombo': [
      {'si': 'කොළඹ', 'en': 'Colombo'},
      {'si': 'දෙහිවල-ගල්කිස්ස', 'en': 'Dehiwala-Mount Lavinia'},
      {'si': 'මොරටුව', 'en': 'Moratuwa'},
      {'si': 'ශ්‍රී ජයවර්ධනපුර කෝට්ටේ', 'en': 'Sri Jayawardenepura Kotte'},
      {'si': 'කඩුවෙල', 'en': 'Kaduwela'},
      {'si': 'මහරගම', 'en': 'Maharagama'},
      {'si': 'කැස්බෑව', 'en': 'Kesbewa'},
      {'si': 'කොලොන්නාව', 'en': 'Kolonnawa'},
      {'si': 'අවිස්සාවේල්ල', 'en': 'Avissawella'},
    ],
    'Galle': [
      {'si': 'ගාල්ල', 'en': 'Galle'},
      {'si': 'අම්බලන්ගොඩ', 'en': 'Ambalangoda'},
      {'si': 'හික්කඩුව', 'en': 'Hikkaduwa'},
      {'si': 'බෙන්තොට', 'en': 'Bentota'},
      {'si': 'ඇල්පිටිය', 'en': 'Elpitiya'},
      {'si': 'බද්දේගම', 'en': 'Baddegama'},
    ],
    'Gampaha': [
      {'si': 'ගම්පහ', 'en': 'Gampaha'},
      {'si': 'මීගමුව', 'en': 'Negombo'},
      {'si': 'ජා-ඇල', 'en': 'Ja-Ela'},
      {'si': 'කටුනායක', 'en': 'Katunayake'},
      {'si': 'කැලණිය', 'en': 'Kelaniya'},
      {'si': 'වත්තල', 'en': 'Wattala'},
    ],
    'Hambantota': [
      {'si': 'හම්බන්තොට', 'en': 'Hambantota'},
      {'si': 'තංගල්ල', 'en': 'Tangalle'},
      {'si': 'තිස්සමහාරාමය', 'en': 'Tissamaharama'},
      {'si': 'අම්බලන්තොට', 'en': 'Ambalantota'},
    ],
    'Jaffna': [
      {'si': 'යාපනය', 'en': 'Jaffna'},
      {'si': 'නල්ලූර්', 'en': 'Nallur'},
      {'si': 'චාවකච්චේරි', 'en': 'Chavakachcheri'},
      {'si': 'පේදුරුතුඩුව', 'en': 'Point Pedro'},
      {'si': 'කයිට්ස්', 'en': 'Karainagar'},
      {'si': 'චුන්නාකම්', 'en': 'Chunnakam'},
    ],
    'Kalutara': [
      {'si': 'කළුතර', 'en': 'Kalutara'},
      {'si': 'පානදුර', 'en': 'Panadura'},
      {'si': 'හොරණ', 'en': 'Horana'},
      {'si': 'බේරුවල', 'en': 'Beruwala'},
      {'si': 'මතුගම', 'en': 'Matugama'},
    ],
    'Kandy': [
      {'si': 'මහනුවර', 'en': 'Kandy'},
      {'si': 'ගම්පොල', 'en': 'Gampola'},
      {'si': 'නාවලපිටිය', 'en': 'Nawalapitiya'},
      {'si': 'පේරාදෙණිය', 'en': 'Peradeniya'},
      {'si': 'කටුගස්තොට', 'en': 'Katugastota'},
      {'si': 'අකුරණ', 'en': 'Akurana'},
    ],
    'Kegalle': [
      {'si': 'කෑගල්ල', 'en': 'Kegalle'},
      {'si': 'මාවනැල්ල', 'en': 'Mawanella'},
      {'si': 'රුවන්වැල්ල', 'en': 'Ruwanwella'},
      {'si': 'වරකාපොල', 'en': 'Warakapola'},
    ],
    'Kilinochchi': [
      {'si': 'කිලිනොච්චි', 'en': 'Kilinochchi'},
      {'si': 'පූනරීන්', 'en': 'Poonakary'},
      {'si': 'කණ්ඩාවලෙයි', 'en': 'Karachchi'},
    ],
    'Kurunegala': [
      {'si': 'කුරුණෑගල', 'en': 'Kurunegala'},
      {'si': 'කුලියාපිටිය', 'en': 'Kuliyapitiya'},
      {'si': 'පන්නල', 'en': 'Pannala'},
      {'si': 'නාරම්මල', 'en': 'Narammala'},
    ],
    'Mannar': [
      {'si': 'මන්නාරම', 'en': 'Mannar'},
      {'si': 'නානාට්ටාන්', 'en': 'Nanaddan'},
      {'si': 'මඩු', 'en': 'Madhu'},
    ],
    'Matale': [
      {'si': 'මාතලේ', 'en': 'Matale'},
      {'si': 'දඹුල්ල', 'en': 'Dambulla'},
      {'si': 'සීගිරිය', 'en': 'Sigiriya'},
      {'si': 'ගලේවෙල', 'en': 'Galewela'},
    ],
    'Matara': [
      {'si': 'මාතර', 'en': 'Matara'},
      {'si': 'වැලිගම', 'en': 'Weligama'},
      {'si': 'අකුරැස්ස', 'en': 'Akuressa'},
      {'si': 'දෙනියාය', 'en': 'Deniyaya'},
      {'si': 'දික්වැල්ල', 'en': 'Dickwella'},
      {'si': 'මිරිස්ස', 'en': 'Mirissa'},
    ],
    'Monaragala': [
      {'si': 'මොණරාගල', 'en': 'Monaragala'},
      {'si': 'වැල්ලවාය', 'en': 'Wellawaya'},
      {'si': 'බිබිල', 'en': 'Bibile'},
      {'si': 'කතරගම', 'en': 'Kataragama'},
    ],
    'Mullaitivu': [
      {'si': 'මුලතිව්', 'en': 'Mullaitivu'},
      {'si': 'පුදුකුඩිඉරිප්පු', 'en': 'Puthukudiyiruppu'},
      {'si': 'ඔඩ්ඩුසුඩාන්', 'en': 'Oddusuddan'},
    ],
    'Nuwara Eliya': [
      {'si': 'නුවර එළිය', 'en': 'Nuwara Eliya'},
      {'si': 'හැටන්', 'en': 'Hatton'},
      {'si': 'තලවකැලේ', 'en': 'Talawakele'},
      {'si': 'නානු ඔය', 'en': 'Nanu Oya'},
    ],
    'Polonnaruwa': [
      {'si': 'පොළොන්නරුව', 'en': 'Polonnaruwa'},
      {'si': 'කදුරුවෙල', 'en': 'Kaduruwela'},
      {'si': 'හිඟුරක්ගොඩ', 'en': 'Hingurakgoda'},
    ],
    'Puttalam': [
      {'si': 'පුත්තලම', 'en': 'Puttalam'},
      {'si': 'හලාවත', 'en': 'Chilaw'},
      {'si': 'වෙන්නප්පුව', 'en': 'Wennappuwa'},
      {'si': 'ආණමඩුව', 'en': 'Anamaduwa'},
    ],
    'Ratnapura': [
      {'si': 'රත්නපුර', 'en': 'Ratnapura'},
      {'si': 'ඇඹිලිපිටිය', 'en': 'Embilipitiya'},
      {'si': 'බලංගොඩ', 'en': 'Balangoda'},
      {'si': 'පැල්මඩුල්ල', 'en': 'Pelmadulla'},
    ],
    'Trincomalee': [
      {'si': 'ත්‍රිකුණාමලය', 'en': 'Trincomalee'},
      {'si': 'කින්නියා', 'en': 'Kinniya'},
      {'si': 'මුතූර්', 'en': 'Mutur'},
    ],
    'Vavuniya': [
      {'si': 'වවුනියාව', 'en': 'Vavuniya'},
      {'si': 'වවුනියාව උතුර', 'en': 'Vavuniya North'},
      {'si': 'වෙන්ගලචෙඩ්ඩිකුලම්', 'en': 'Vengalacheddikulam'},
    ],
  };

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
        _selectedDistrictEn == null ||
        _selectedTownEn == null ||
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
            'town': _selectedTownEn,
            'role': 'data collector',
            'createdAt': DateTime.now(),
            'isActive': false, // Account is inactive until approved by an admin
          });

      // Sign out the user immediately so they have to log in and be checked for approval
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ලියාපදිංචිය සාර්ථකයි! ඔබගේ ගිණුම පරිපාලක විසින් අනුමත කළ පසු ඔබට ඇතුල් විය හැක.',
            ),
          ),
        );

        // Fix: Wrapping LoginScreen with its Provider
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
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException during signup: ${e.code}\n$stackTrace');
      String errorMessage = 'දෝෂයක් මතු විය.';
      if (e.code == 'weak-password') {
        errorMessage = 'මුරපදය ඉතා දුර්වලයි (අවම අකුරු/ඉලක්කම් 6ක් අවශ්යයි).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'මෙම Email ලිපිනය දැනටමත් ලියාපදිංචි කර ඇත.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'ඔබ ඇතුළත් කළ Email ලිපිනය වැරදියි.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e, stackTrace) {
      debugPrint('Generic error during signup: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ලියාපදිංචි වීමේදී අනපේක්ෂිත දෝෂයක් මතු විය.'),
          ),
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
          obscureText: isPassword
              ? _obscurePassword
              : (isConfirmPassword ? _obscureConfirmPassword : false),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade100,
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

  InputDecoration _dropdownDecoration(IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      suffixIcon: Icon(icon, color: Colors.lightBlue.shade200),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                'නම',
                'ඔබගේ නම ඇතුළත් කරන්න',
                Icons.person_outline,
                _nameController,
              ),
              _buildTextField(
                'ජාතික හැඳුනුම්පත් අංකය',
                'ජා.හැ. අංකය ඇතුළත් කරන්න',
                Icons.badge_outlined,
                _nicController,
              ),
              _buildTextField(
                'ඊමේල් ලිපිනය',
                'ඔබගේ ඊමේල් ලිපිනය ඇතුළත් කරන්න',
                Icons.email_outlined,
                _emailController,
              ),
              _buildTextField(
                'දුරකථන අංකය',
                'ඔබගේ දුරකථන අංකය ඇතුළත් කරන්න',
                Icons.phone_in_talk_outlined,
                _phoneController,
              ),
              // District Dropdown
              const Text(
                'දිස්ත්‍රික්කය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedDistrictSi,
                hint: const Text('දිස්ත්‍රික්කය තෝරන්න'),
                decoration: _dropdownDecoration(Icons.location_city_outlined),
                items: _districts.map((Map<String, String> district) {
                  return DropdownMenuItem<String>(
                    value: district['si'],
                    child: Text(district['si']!),
                  );
                }).toList(),
                onChanged: (selectedSi) {
                  if (selectedSi == null) return;
                  final selectedDistrict = _districts.firstWhere(
                    (d) => d['si'] == selectedSi,
                  );

                  setState(() {
                    _selectedDistrictSi = selectedSi;
                    _selectedDistrictEn = selectedDistrict['en'];
                    _selectedTownSi = null; // Reset town when district changes
                    _selectedTownEn = null;
                    _towns = _townsData[_selectedDistrictEn!] ?? [];
                  });
                },
              ),
              const SizedBox(height: 16),

              // Town Dropdown
              const Text(
                'නගරය',
                style: TextStyle(
                  fontFamily: 'UNSamantha',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedTownSi,
                hint: const Text('නගරය තෝරන්න'),
                decoration: _dropdownDecoration(Icons.home_work_outlined),
                // Disable if no district is selected
                disabledHint: _selectedDistrictSi == null
                    ? const Text('පළමුව දිස්ත්‍රික්කය තෝරන්න')
                    : null,
                items: _towns.map((Map<String, String> town) {
                  return DropdownMenuItem<String>(
                    value: town['si'],
                    child: Text(town['si']!),
                  );
                }).toList(),
                onChanged: _selectedDistrictSi == null
                    ? null
                    : (selectedSi) {
                        if (selectedSi == null) return;
                        final selectedTown = _towns.firstWhere(
                          (t) => t['si'] == selectedSi,
                        );
                        setState(() {
                          _selectedTownSi = selectedSi;
                          _selectedTownEn = selectedTown['en'];
                        });
                      },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'මුරපදය',
                'මුරපදය',
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),
              _buildTextField(
                'මුරපදය නැවත ඇතුළත් කරන්න',
                'මුරපදය',
                Icons.lock_outline,
                _confirmPasswordController,
                isConfirmPassword: true,
              ),

              const SizedBox(height: 24),

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
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
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
                  const Text(
                    'ගිණුමක් සාදා තිබේද? ',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'ලොග් වන්න',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'UNSamantha',
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.w600,
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
