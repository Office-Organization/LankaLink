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

  // Values to be saved in the database (English)
  // Hardcoded to Matara as requested
  final String _selectedDistrictEn = 'Matara';
  String? _selectedLocalAuthorityEn;
  String? _selectedGNEn;

  // Values for UI display (Sinhala)
  final String _selectedDistrictSi = 'මාතර';
  String? _selectedLocalAuthoritySi;
  String? _selectedGNSi;

 // Hardcoded Local Authorities for Matara District
final List<Map<String, String>> _localAuthorities = [
  {'si': 'මාතර මහ නගර සභාව', 'en': 'Matara Municipal Council'},
  {'si': 'වැලිගම නගර සභාව', 'en': 'Weligama Urban Council'},
  {'si': 'මාතර ප්‍රාදේශීය සභාව', 'en': 'Matara Pradeshiya Sabha'},
  {'si': 'වැලිගම ප්‍රාදේශීය සභාව', 'en': 'Weligama Pradeshiya Sabha'},
  {'si': 'අකුරැස්ස ප්‍රාදේශීය සභාව', 'en': 'Akuressa Pradeshiya Sabha'},
  {'si': 'අතුරලිය ප්‍රාදේශීය සභාව', 'en': 'Athuraliya Pradeshiya Sabha'},
  {'si': 'දෙවිනුවර ප්‍රාදේශීය සභාව', 'en': 'Devinuwara Pradeshiya Sabha'},
  {'si': 'දික්වැල්ල ප්‍රාදේශීය සභාව', 'en': 'Dickwella Pradeshiya Sabha'},
  {'si': 'හක්මන ප්‍රාදේශීය සභාව', 'en': 'Hakmana Pradeshiya Sabha'},
  {'si': 'කඹුරුපිටිය ප්‍රාදේශීය සභාව', 'en': 'Kamburupitiya Pradeshiya Sabha'},
  {'si': 'කිරින්ද පුහුල්වැල්ල ප්‍රාදේශීය සභාව', 'en': 'Kirinda Puhulwella Pradeshiya Sabha'},
  {'si': 'කොටපොල ප්‍රාදේශීය සභාව', 'en': 'Kotapola Pradeshiya Sabha'},
  {'si': 'මාලිම්බඩ ප්‍රාදේශීය සභාව', 'en': 'Malimbada Pradeshiya Sabha'},
  {'si': 'පස්ගොඩ ප්‍රාදේශීය සභාව', 'en': 'Pasgoda Pradeshiya Sabha'},
  {'si': 'පිටබැද්දර ප්‍රාදේශීය සභාව', 'en': 'Pitabeddara Pradeshiya Sabha'},
  {'si': 'තිහගොඩ ප්‍රාදේශීය සභාව', 'en': 'Thihagoda Pradeshiya Sabha'},
];

// Hardcoded GN Divisions based on Local Authority
final Map<String, List<Map<String, String>>> _gnDivisionsData = {
  'Weligama Urban Council': [
    {'si': 'මහ වීදිය (382)', 'en': 'Maha Weediya (382)'},
    {'si': 'පරණකඩේ (382A)', 'en': 'Paranakade (382A)'},
    {'si': 'හෙට්ටිවීදිය (382B)', 'en': 'Hettiweediya (382B)'},
    {'si': 'ගල්බොක්ක නැගෙනහිර (385)', 'en': 'Galbokka East (385)'},
    {'si': 'අලුත් වීදිය (385A)', 'en': 'Aluthweediya (385A)'},
    {'si': 'ගල්බොක්ක බටහිර (385B)', 'en': 'Galbokka West (385B)'},
    {'si': 'වල්ලිවල බටහිර (386A)', 'en': 'Walliwala West (386A)'},
    {'si': 'වල්ලිවල නැගෙනහිර (386B)', 'en': 'Walliwala East (386B)'},
    {'si': 'කප්පරතොට දකුණ (386C)', 'en': 'Kapparathota South (386C)'},
    {'si': 'කප්පරතොට උතුර (386D)', 'en': 'Kapparathota North (386D)'},
    {'si': 'පැලෑන නැගෙනහිර (387)', 'en': 'Pelena East (387)'},
    {'si': 'පැලෑන බටහිර (387A)', 'en': 'Pelena West (387A)'},
    {'si': 'කොහුණුගමුව (389)', 'en': 'Kohunugamuwa (389)'},
  ],
  'Matara Municipal Council': [
    {'si': 'කොටුවේගොඩ (416)', 'en': 'Kotewegoda (416)'},
    {'si': 'නූපේ (416A)', 'en': 'Nupe (416A)'},
    {'si': 'ඉසදීන් නගරය (416B)', 'en': 'Isadeen Town (416B)'},
    {'si': 'උයන්වත්ත (415)', 'en': 'Uyanwatta (415)'},
    {'si': 'උයන්වත්ත උතුර (415A)', 'en': 'Uyanwatta North (415A)'},
    {'si': 'උයන්වත්ත දකුණ (415B)', 'en': 'Uyanwatta South (415B)'},
    {'si': 'පොල්හේන (417)', 'en': 'Polhena (417)'},
    {'si': 'වල්ගම (418)', 'en': 'Walgama (418)'},
    {'si': 'වල්ගම උතුර (418A)', 'en': 'Walgama North (418A)'},
    {'si': 'වල්ගම මැද (418B)', 'en': 'Walgama Meda (418B)'},
    {'si': 'වල්ගම දකුණ (418C)', 'en': 'Walgama South (418C)'},
    {'si': 'වෙලේගොඩ නැගෙනහිර (419A)', 'en': 'Welegoda East (419A)'},
    {'si': 'වෙලේගොඩ බටහිර (419B)', 'en': 'Welegoda West (419B)'},
    {'si': 'හිත්බැටිය නැගෙනහිර (420A)', 'en': 'Hiththetiya East (420A)'},
    {'si': 'හිත්බැටිය මධ්‍යම (420B)', 'en': 'Hiththetiya Central (420B)'},
    {'si': 'හිත්බැටිය බටහිර (420C)', 'en': 'Hiththetiya West (420C)'},
    {'si': 'සුදර්ශී පෙදෙස (420D)', 'en': 'Sudarshi Place (420D)'},
    {'si': 'වල්පල නැගෙනහිර (414A)', 'en': 'Walpala East (414A)'},
    {'si': 'වල්පල බටහිර (414B)', 'en': 'Walpala West (414B)'},
    {'si': 'වැලිවේරිය නැගෙනහිර (413A)', 'en': 'Weliweriya East (413A)'},
    {'si': 'වැලිවේරිය බටහිර (413B)', 'en': 'Weliweriya West (413B)'},
    {'si': 'තුඩාව (412)', 'en': 'Tudawa (412)'},
    {'si': 'මැද්දවත්ත (423)', 'en': 'Meddawatta (423)'},
  ],
  'Matara Pradeshiya Sabha': [
    {'si': 'කැකණදුර (420)', 'en': 'Kekanadura (420)'},
    {'si': 'තලල්ල උතුර (421A)', 'en': 'Talalla North (421A)'},
    {'si': 'තලල්ල දකුණ (421B)', 'en': 'Talalla South (421B)'},
    {'si': 'නාඩියගහවත්ත (422)', 'en': 'Nadiyagahawatta (422)'},
    {'si': 'දියගහ (424)', 'en': 'Diyagaha (424)'},
    {'si': 'මකවිට (425)', 'en': 'Makavita (425)'},
    {'si': 'කොකාවල (426)', 'en': 'Kokawala (426)'},
    {'si': 'කුඹල්ගම (427)', 'en': 'Kubalgama (427)'},
    {'si': 'වෙහෙරහේන (428)', 'en': 'Weherahena (428)'},
    {'si': 'ගන්දර (429)', 'en': 'Gandara (429)'},
  ],
  'Weligama Pradeshiya Sabha': [
    {'si': 'මිරිස්ස දකුණ (391)', 'en': 'Mirissa South (391)'},
    {'si': 'මිරිස්ස උතුර (392)', 'en': 'Mirissa North (392)'},
    {'si': 'කඹුරුගමුව උතුර (408)', 'en': 'Kamburugamuwa North (408)'},
    {'si': 'කඹුරුගමුව දකුණ (409)', 'en': 'Kamburugamuwa South (409)'},
    {'si': 'දෙණිපිටිය උතුර (395)', 'en': 'Denipitiya North (395)'},
    {'si': 'දෙණිපිටිය දකුණ (396)', 'en': 'Denipitiya South (396)'},
    {'si': 'වැලිපිටිය (398)', 'en': 'Welipitiya (398)'},
    {'si': 'පැලෑන උතුර (388)', 'en': 'Pelena North (388)'},
    {'si': 'මිද්දෙණිය (399)', 'en': 'Middeniya (399)'},
  ],
  'Akuressa Pradeshiya Sabha': [
    {'si': 'අකුරැස්ස (430)', 'en': 'Akuressa (430)'},
    {'si': 'මලිදූව (431)', 'en': 'Maliduwa (431)'},
    {'si': 'ඉඹුල්ගොඩ (432)', 'en': 'Imbulgoda (432)'},
    {'si': 'පොරඹ (433)', 'en': 'Poramba (433)'},
    {'si': 'හේනේගම බටහිර (434)', 'en': 'Henegama West (434)'},
    {'si': 'මිනීපෙගොඩ (435)', 'en': 'Minipegoda (435)'},
    {'si': 'මාරඹ (436)', 'en': 'Maramba (436)'},
    {'si': 'තලාගහගම (437)', 'en': 'Thalahagama (437)'},
    {'si': 'උරුමුත්ත (438)', 'en': 'Urumutta (438)'},
    {'si': 'හුලන්දාව (439)', 'en': 'Hulandawa (439)'},
    {'si': 'ලේනම (440)', 'en': 'Lenama (440)'},
    {'si': 'බෝපගොඩ (441)', 'en': 'Bopagoda (441)'},
  ],
  'Athuraliya Pradeshiya Sabha': [
    {'si': 'අතුරලිය (520)', 'en': 'Athuraliya (520)'},
    {'si': 'විල්පිට (521)', 'en': 'Wilpita (521)'},
    {'si': 'බාලකාවල (522)', 'en': 'Balakawala (522)'},
    {'si': 'පරදූව (523)', 'en': 'Paraduwa (523)'},
    {'si': 'ඇල්ගිරිය (524)', 'en': 'Elgiriya (524)'},
    {'si': 'මාරගොඩ (525)', 'en': 'Maragoda (525)'},
  ],
  'Devinuwara Pradeshiya Sabha': [
    {'si': 'දෙවිනුවර උතුර (480)', 'en': 'Devinuwara North (480)'},
    {'si': 'දෙවිනුවර දකුණ (481)', 'en': 'Devinuwara South (481)'},
    {'si': 'දෙවිනුවර නුගේගොඩ (482)', 'en': 'Devinuwara Nugegoda (482)'},
    {'si': 'සිංහාසන (483)', 'en': 'Sinhasana (483)'},
    {'si': 'කපුගම මධ්‍යම (484)', 'en': 'Kapugama Central (484)'},
    {'si': 'කපුගම උතුර (485)', 'en': 'Kapugama North (485)'},
    {'si': 'කොට්ටගොඩ (486)', 'en': 'Kottagoda (486)'},
    {'si': 'තල්පාවිල (487)', 'en': 'Thalpawila (487)'},
  ],
  'Dickwella Pradeshiya Sabha': [
    {'si': 'දික්වැල්ල උතුර (450)', 'en': 'Dickwella North (450)'},
    {'si': 'දික්වැල්ල දකුණ (451)', 'en': 'Dickwella South (451)'},
    {'si': 'පෙහෙබිය (452)', 'en': 'Pehebiya (452)'},
    {'si': 'බතිගම උතුර (453)', 'en': 'Batigama North (453)'},
    {'si': 'බතිගම දකුණ (454)', 'en': 'Batigama South (454)'},
    {'si': 'වලස්ගල බටහිර (455)', 'en': 'Walasgala West (455)'},
    {'si': 'වලස්ගල නැගෙනහිර (456)', 'en': 'Walasgala East (456)'},
    {'si': 'බෙලිහින්න (457)', 'en': 'Belihinna (457)'},
    {'si': 'රාදම්පොල (458)', 'en': 'Radampola (458)'},
    {'si': 'වෙහෙල්ල (459)', 'en': 'Wehella (459)'},
    {'si': 'උරුගමුව (460)', 'en': 'Urugamuwa (460)'},
  ],
  'Hakmana Pradeshiya Sabha': [
    {'si': 'හක්මන (470)', 'en': 'Hakmana (470)'},
    {'si': 'දෙනගම (471)', 'en': 'Denagama (471)'},
    {'si': 'ලැල්පේ (472)', 'en': 'Lalpe (472)'},
    {'si': 'හෙට්ටියාවල (473)', 'en': 'Hettiyawala (473)'},
    {'si': 'යටියන (474)', 'en': 'Yatiyana (474)'},
    {'si': 'මීඇල්ල (475)', 'en': 'Miella (475)'},
    {'si': 'කොළඹගේආර (476)', 'en': 'Kolambageara (476)'},
  ],
  'Kamburupitiya Pradeshiya Sabha': [
    {'si': 'කඹුරුපිටිය (490)', 'en': 'Kamburupitiya (490)'},
    {'si': 'අකුරුගොඩ (491)', 'en': 'Akurugoda (491)'},
    {'si': 'හොරගොඩ (492)', 'en': 'Horagoda (492)'},
    {'si': 'කිරිමැටිමුල්ල (493)', 'en': 'Kirimetimulla (493)'},
    {'si': 'මාපලාන (494)', 'en': 'Mapalana (494)'},
    {'si': 'තඹලගම (495)', 'en': 'Thambalagama (495)'},
  ],
  'Kirinda Puhulwella Pradeshiya Sabha': [
    {'si': 'කිරින්ද (530)', 'en': 'Kirinda (530)'},
    {'si': 'පුහුල්වැල්ල (531)', 'en': 'Puhulwella (531)'},
    {'si': 'බටුවිට (532)', 'en': 'Batuvita (532)'},
    {'si': 'විද්‍යානිකේත (533)', 'en': 'Vidyaniketha (533)'},
  ],
  'Kotapola Pradeshiya Sabha': [
    {'si': 'කොටපොල (540)', 'en': 'Kotapola (540)'},
    {'si': 'දෙනියාය (541)', 'en': 'Deniyaya (541)'},
    {'si': 'මොරවක (542)', 'en': 'Morawaka (542)'},
    {'si': 'කොළවෙනිගම (543)', 'en': 'Kolawenigama (543)'},
  ],
  'Malimbada Pradeshiya Sabha': [
    {'si': 'මාලිම්බඩ උතුර (510)', 'en': 'Malimbada North (510)'},
    {'si': 'මාලිම්බඩ දකුණ (511)', 'en': 'Malimbada South (511)'},
    {'si': 'තෙලිජ්ජවිල (512)', 'en': 'Thelijjawila (512)'},
    {'si': 'සුල්තානාගොඩ (513)', 'en': 'Sulthanagoda (513)'},
    {'si': 'කෙටන්විල (514)', 'en': 'Ketanwila (514)'},
  ],
  'Pasgoda Pradeshiya Sabha': [
    {'si': 'පස්ගොඩ (550)', 'en': 'Pasgoda (550)'},
    {'si': 'රොටුඹ (552)', 'en': 'Rotumba (552)'},
    {'si': 'බෙංගමුව (553)', 'en': 'Bengamuwa (553)'},
  ],
  'Pitabeddara Pradeshiya Sabha': [
    {'si': 'පිටබැද්දර (560)', 'en': 'Pitabeddara (560)'},
    {'si': 'කලුවල (561)', 'en': 'Kaluwala (561)'},
    {'si': 'සියඹලාගොඩ (562)', 'en': 'Siyambalagoda (562)'},
    {'si': 'ඇලකන්ද (563)', 'en': 'Elakanda (563)'},
  ],
  'Thihagoda Pradeshiya Sabha': [
    {'si': 'තිහගොඩ (500)', 'en': 'Thihagoda (500)'},
    {'si': 'කපුවත්ත (501)', 'en': 'Kapuwatta (501)'},
    {'si': 'නායිම්බල (502)', 'en': 'Naimbala (502)'},
    {'si': 'පාලටුව (503)', 'en': 'Palatuwa (503)'},
    {'si': 'යටියන නැගෙනහිර (504)', 'en': 'Yatiyana East (504)'},
  ],
};
  List<Map<String, String>> _currentGNDivisions = [];

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
            'local_authority': _selectedLocalAuthorityEn, // Added level
            'gn_division': _selectedGNEn, // Added bottom level
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

  // Basic Text Field Builder
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

  // NEW: Searchable Dropdown Field Builder using Autocomplete
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
            // Enable search by filtering options
            return options.where((Map<String, String> option) {
              return option['si']!
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          displayStringForOption: (Map<String, String> option) => option['si']!,
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
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
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

              _buildTextField('නම', 'ඔබගේ නම', Icons.person_outline, _nameController),
              _buildTextField('ජා.හැ. අංකය', 'ජා.හැ. අංකය', Icons.badge_outlined, _nicController),
              _buildTextField('ඊමේල්', 'ඊමේල් ලිපිනය', Icons.email_outlined, _emailController),
              _buildTextField('දුරකථන', 'දුරකථන අංකය', Icons.phone_in_talk_outlined, _phoneController),

              // Hardcoded District Field (Read-only)
              _buildTextField(
                'දිස්ත්‍රික්කය',
                'මාතර',
                Icons.location_city_outlined,
                TextEditingController(text: 'මාතර (Matara)'),
                readOnly: true,
              ),

              // Searchable Local Authority (Pradeshiya Sabha/Municipal)
              _buildSearchableField(
                label: 'පළාත් පාලන ආයතනය (සොයන්න)',
                hint: 'ප්‍රාදේශීය/නගර සභාව ටයිප් කර තෝරන්න',
                icon: Icons.account_balance_outlined,
                options: _localAuthorities,
                onSelected: (selected) {
                  setState(() {
                    _selectedLocalAuthoritySi = selected['si'];
                    _selectedLocalAuthorityEn = selected['en'];
                    // Reset GN Division when Local Authority changes
                    _selectedGNSi = null;
                    _selectedGNEn = null;
                    _currentGNDivisions = _gnDivisionsData[_selectedLocalAuthorityEn!] ?? [];
                  });
                },
              ),

              // Searchable GN Division
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

              _buildTextField('මුරපදය', 'මුරපදය', Icons.lock_outline, _passwordController, isPassword: true),
              _buildTextField('මුරපදය නැවත', 'මුරපදය', Icons.lock_outline, _confirmPasswordController, isConfirmPassword: true),

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
                  const Text('ගිණුමක් සාදා තිබේද? ', style: TextStyle(fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'ලොග් වන්න',
                      style: TextStyle(fontSize: 12, color: Colors.lightBlue, fontWeight: FontWeight.bold),
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