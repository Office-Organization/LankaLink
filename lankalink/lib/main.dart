import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Email Verification Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

// ------------------- AUTH GATE -------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // User is signed in – show Dashboard
          return const DashboardScreen();
        } else {
          // Not signed in – show Login
          return const LoginScreen();
        }
      },
    );
  }
}

// ------------------- LOGIN SCREEN -------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      // Check if email is verified
      if (user != null && !user.emailVerified) {
        // Sign out immediately
        await FirebaseAuth.instance.signOut();
        setState(() {
          _message = '⚠️ Your email is not verified. '
              'Please check your inbox and click the verification link.\n'
              'You can request a new link below.';
          _isLoading = false;
        });
        return;
      }

      // If verified, AuthGate will redirect to Dashboard automatically
      // so we don't need to do anything here.
      setState(() {
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = _getErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Something went wrong. Try again.';
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '❌ No account found for this email.';
      case 'wrong-password':
        return '❌ Incorrect password.';
      case 'invalid-email':
        return '❌ Invalid email format.';
      case 'too-many-requests':
        return '⏳ Too many attempts. Please wait.';
      default:
        return '⚠️ ${e.message}';
    }
  }

  // Resend verification email (works if the user exists but is not verified)
  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your email first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // We need to sign in with the password to get a user object, but
      // we don't want to keep them signed in. We'll try to sign in and
      // then sign out if not verified, or just use sendEmailVerification
      // on the user object.
      // Simpler: we can try to sign in, but that might lock account if wrong password.
      // Better: we can use FirebaseAuth.instance.currentUser? but that is null if not signed in.
      // Workaround: we can attempt to sign in and if success but not verified, resend.
      // Or we can use the Firebase Admin SDK (not from client).
      // However, the easiest way to resend verification is to require the user
      // to be signed in (but we don't want that). 
      // Instead, we can ask the user to sign up again? That's not ideal.
      // A common approach: send a password reset email that also includes a link to verify.
      // But for simplicity, we can just tell the user to check their spam folder.
      // Actually, Firebase does not allow resending verification without the user being signed in.
      // So we need to sign in first, then call sendEmailVerification, then sign out.
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        setState(() {
          _message = '📧 New verification email sent to $email. Please check your inbox.';
        });
      } else {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _message = 'This email is already verified. You can log in now.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Could not resend. Make sure your password is correct.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_message, textAlign: TextAlign.center),
            ],
            // Resend button (only show if there's a verification-related message)
            if (_message.contains('verification') || _message.contains('verify'))
              TextButton(
                onPressed: _resendVerification,
                child: const Text('Resend verification email'),
              ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                );
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- SIGN UP SCREEN -------------------
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Please fill all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setState(() => _message = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      // Sign out so the user cannot use the app until verified
      await FirebaseAuth.instance.signOut();

      setState(() {
        _message = '✅ Account created! A verification link has been sent to $email.\n'
            'Please click the link to verify your email, then log in.';
        _isLoading = false;
      });

      // Clear fields
      _emailController.clear();
      _passwordController.clear();
      _confirmController.clear();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = _getSignUpErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Something went wrong. Try again.';
        _isLoading = false;
      });
    }
  }

  String _getSignUpErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '❌ This email is already registered.';
      case 'invalid-email':
        return '❌ Please enter a valid email address.';
      case 'weak-password':
        return '❌ Password is too weak. Use at least 6 characters.';
      default:
        return '⚠️ ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('Create Account'),
                  ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_message, textAlign: TextAlign.center),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- DASHBOARD SCREEN -------------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // AuthGate will automatically show LoginScreen
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Welcome to the Dashboard!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Verified user: ${user?.email ?? "Unknown"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}