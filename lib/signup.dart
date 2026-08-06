import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gnDivisionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedDistrict;

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;
  
  bool _isNicTaken = false;
  bool _isCheckingNic = false;
  bool _nicCheckError = false; 
  String _nicErrorText = '';
  Timer? _debounce;

  bool? _doPasswordsMatch;
  String _passwordMatchError = '';

  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo',
    'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara',
    'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar',
    'Matale', 'Matara', 'Monaragala', 'Mullaitivu', 'Nuwara Eliya',
    'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya'
  ];

  @override
  void initState() {
    super.initState();
    _nicController.addListener(_onNicChanged);
    _passwordController.addListener(_checkPasswordMatch);
    _confirmPasswordController.addListener(_checkPasswordMatch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fullNameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _gnDivisionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordMatch() {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (confirm.isEmpty) {
      setState(() {
        _doPasswordsMatch = null;
        _passwordMatchError = '';
      });
    } else if (pass == confirm) {
      setState(() {
        _doPasswordsMatch = true;
        _passwordMatchError = '';
      });
    } else {
      setState(() {
        _doPasswordsMatch = false;
        _passwordMatchError = 'Passwords do not match';
      });
    }
  }

  void _onNicChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final nic = _nicController.text.trim();
      if (nic.length < 6) {
        setState(() {
          _isCheckingNic = false;
          _isNicTaken = false;
          _nicCheckError = false;
          _nicErrorText = '';
        });
        return;
      }

      setState(() {
        _isCheckingNic = true;
        _nicErrorText = '';
        _nicCheckError = false;
      });

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('nic', isEqualTo: nic)
            .get();

        setState(() {
          _isCheckingNic = false;
          _isNicTaken = snapshot.docs.isNotEmpty;
          _nicErrorText = _isNicTaken ? 'NIC number is already registered.' : '';
        });
      } catch (e) {
        setState(() {
          _isCheckingNic = false;
          _isNicTaken = false;
          _nicCheckError = true; 
        });
      }
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isNicTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This NIC is already registered.')),
      );
      return;
    }
    if (_doPasswordsMatch == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nic = _nicController.text.trim();
      final finalCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: nic)
          .get();

      if (finalCheck.docs.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate NIC detected. Registration blocked.')),
        );
        return;
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;
        
        // Removed province from Firestore payload
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': _fullNameController.text.trim(),
          'nic': nic,
          'email': _emailController.text.trim(),
          'mobilePhone': _mobileController.text.trim(),
          'district': _selectedDistrict,
          'gnDivision': _gnDivisionController.text.trim(),
          'status': 'inactive',
          'createdAt': Timestamp.now(),
        });

        await userCredential.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful! Please wait for admin approval.')),
        );

        _fullNameController.clear();
        _nicController.clear();
        _emailController.clear();
        _mobileController.clear();
        _gnDivisionController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _selectedDistrict = null;
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      String errorText = 'Failed to register: ${e.toString()}';
      if (e.toString().contains('index')) {
        errorText = 'Database query failed. Please create the required Firestore index for "nic".';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData? icon,
      {TextInputType? keyboardType, String? errorText, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorText: errorText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (label == 'Email' && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      bool isObscured, VoidCallback toggleVisibility,
      {String? errorText, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        suffixIcon: suffixIcon ??
            IconButton(
              icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: toggleVisibility,
              color: const Color(0xFFC2185B),
            ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorText: errorText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      value: selectedValue,
      hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
      isExpanded: true,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a $hint' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Create an Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                _buildTextField(_fullNameController, "Your Full Name", Icons.person_outline),
                const SizedBox(height: 16),

                _buildTextField(
                  _nicController, 
                  "NIC Number", 
                  null,
                  errorText: _nicErrorText.isNotEmpty ? _nicErrorText : null,
                  suffixIcon: _isCheckingNic
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC2185B)),
                          ),
                        )
                      : (_nicCheckError
                          ? const Icon(Icons.error_outline, color: Colors.orange) 
                          : (_isNicTaken
                              ? const Icon(Icons.close, color: Colors.red) 
                              : (_nicController.text.trim().length >= 6
                                  ? const Icon(Icons.check, color: Colors.green) 
                                  : null))),
                ),
                const SizedBox(height: 16),

                _buildDropdown('Select District', _districts, _selectedDistrict, (value) {
                  setState(() => _selectedDistrict = value);
                }),
                const SizedBox(height: 16),

                _buildTextField(_gnDivisionController, "GN Division", null),
                const SizedBox(height: 16),

                _buildTextField(_emailController, "Email", Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),

                _buildTextField(_mobileController, "Mobile Number", Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),

                _buildPasswordField(_passwordController, "Enter Your Password",
                    _isPasswordObscured, () {
                  setState(() => _isPasswordObscured = !_isPasswordObscured);
                }),
                const SizedBox(height: 16),

                _buildPasswordField(
                  _confirmPasswordController,
                  "Enter Password Again",
                  _isConfirmPasswordObscured,
                  () {
                    setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured);
                  },
                  errorText: _doPasswordsMatch == false ? _passwordMatchError : null,
                  suffixIcon: _doPasswordsMatch == null
                      ? null
                      : (_doPasswordsMatch == true
                          ? const Icon(Icons.check, color: Colors.green)
                          : const Icon(Icons.close, color: Colors.red)),
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                      ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already Registered?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}